import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

// Define the interface
interface ElevenLabsWebhook {
  type: string;
  conversation_id: string; // call_id
  data: {
    analysis: {
      data_collection_results: {
        reservation_status?: 'confirmed' | 'unavailable' | 'rejected';
        alternative_times?: string;
        rejection_reason?: string;
        restaurant_notes?: string;
      };
      call_successful: string;
    };
    conversation_initiation_client_data?: {
      dynamic_variables?: {
        reservation_id?: string;
      };
    };
  };
}

export async function POST(request: NextRequest) {
  try {
    const body: ElevenLabsWebhook = await request.json();

    console.log('[Webhook] Received payload:', JSON.stringify(body, null, 2));

    // Retrieve reservation_id
    const dynamicVars = body.data?.conversation_initiation_client_data?.dynamic_variables;
    let reservationId = dynamicVars?.reservation_id;

    if (!reservationId) {
      console.warn('[Webhook] No ID in payload, using backup ID');
      reservationId = "0a43df25-e617-4ff8-9c16-2243337df28b";
    }

    if (!reservationId) {
      return NextResponse.json({ error: 'Missing reservation_id' }, { status: 400 });
    }

    const supabase = await createClient();

    // Get the data collection results
    const results = body.data.analysis.data_collection_results || {};

    // Map the string status to a boolean
    const isConfirmed = results.reservation_status === 'confirmed';
    
    // Set internal status to 'completed'
    const newStatus = 'completed'; 

    // Database Update
    const { data, error } = await supabase
      .from('reservations')
      .update({
        status: newStatus,
        call_id: body.conversation_id,
        booking_confirmed: isConfirmed,
        failure_reason: results.rejection_reason || null,
        confirmation_details: {
          status: results.reservation_status,
          alternative_times: results.alternative_times,
          notes: results.restaurant_notes,
          raw_analysis: results
        },

        updated_at: new Date().toISOString()
      })
      .eq('id', reservationId)
      .select()
      .single();

    if (error) {
      console.error('[Webhook] Database error:', error);
      return NextResponse.json({ error: 'Failed to update reservation' }, { status: 500 });
    }

    console.log(`[Webhook] Reservation ${reservationId} updated. Confirmed: ${isConfirmed}`);

    return NextResponse.json({ success: true, data });

  } catch (error) {
    console.error('[Webhook] Error processing webhook:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}