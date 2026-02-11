import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    console.log('[Webhook] Received payload:', JSON.stringify(body, null, 2));

    const BACKUP_ID = "0a43df25-e617-4ff8-9c16-2243337df28b";
    
    const dynamicVars = body.data?.conversation_initiation_client_data?.dynamic_variables;
    let reservationId = dynamicVars?.reservation_id || BACKUP_ID;

    const supabase = await createClient();

    const results = body.data?.analysis?.data_collection_results || {};

    const rawStatus = results.reservation_status?.value || results.reservation_status;
    const isConfirmed = rawStatus === 'confirmed';
    
    const notes = results.restaurant_notes?.value || results.restaurant_notes || "";
    const altTimes = results.alternative_times?.value || results.alternative_times || "";
    const rejectReason = results.rejection_reason?.value || results.rejection_reason || null;

    const { data, error } = await supabase
      .from('reservations')
      .update({
        status: 'completed',
        call_id: body.conversation_id || body.data?.conversation_id,
        booking_confirmed: isConfirmed,
        failure_reason: rejectReason,
        confirmation_details: {
          status: rawStatus,
          alternative_times: altTimes,
          notes: notes,
          raw_analysis: results
        },
        updated_at: new Date().toISOString()
      })
      .eq('id', reservationId)
      .select()
      .single();

    if (error) {
      console.error('[Webhook] Database error:', error);
      return NextResponse.json({ error: 'Failed to update' }, { status: 500 });
    }

    // 此时日志应该会显示 Confirmed: true 了
    console.log(`[Webhook] Reservation ${reservationId} updated. Confirmed: ${isConfirmed}`);

    return NextResponse.json({ success: true, data });

  } catch (error) {
    console.error('[Webhook] Error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}