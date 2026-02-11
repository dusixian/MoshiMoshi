import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    console.log('[Webhook] Received payload at:', new Date().toISOString());

    const BACKUP_ID = "0a43df25-e617-4ff8-9c16-2243337df28b";
    let reservationId = body.data?.conversation_initiation_client_data?.dynamic_variables?.reservation_id || BACKUP_ID;

    const results = body.data?.analysis?.data_collection_results || {};

    const extracted = {
      status: results.reservation_status?.value || results.reservation_status || "",
      notes: results.restaurant_notes?.value || "",
      alternative_times: results.alternative_times?.value || "",
      rejection_reason: results.rejection_reason?.value || null
    };

    const isConfirmed = extracted.status === 'confirmed';

    console.log(`[Webhook] Target ID: ${reservationId}, Confirmed: ${isConfirmed}`);

    const supabase = await createClient();

    const { data, error } = await supabase
      .from('reservations')
      .update({
        status: 'completed',
        booking_confirmed: isConfirmed,
        failure_reason: extracted.rejection_reason,
        confirmation_details: {
          status: extracted.status,
          notes: extracted.notes,
          alternative_times: extracted.alternative_times
        },
        updated_at: new Date().toISOString()
      })
      .eq('id', reservationId)
      .select()
      .single();

    if (error) {
      console.error('[Webhook] Supabase error:', error);
      return NextResponse.json({ error: 'Database update failed' }, { status: 500 });
    }

    return NextResponse.json({ success: true, updated_id: reservationId });

  } catch (error) {
    console.error('[Webhook] Fatal error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}