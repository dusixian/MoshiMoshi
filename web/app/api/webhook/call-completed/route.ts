import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    console.log('[Webhook] Received payload at:', new Date().toISOString());


    const rawData = body.data || {};
    const analysis = rawData.analysis || {};
    const dataResults = analysis.data_collection_results || {};
    const metadata = rawData.metadata || {};

    const cleanedDetails = {
      summary: analysis.transcript_summary || "",
      results: dataResults,
      transcript: rawData.transcript || [],
      call_stats: {
        duration: metadata.call_duration_secs || 0,
        cost: metadata.cost || 0
      }
    };

    // "Confirmed", "Action Required", "Failed", "Incomplete"
    const rawStatus = String(dataResults.reservation_status?.value || dataResults.reservation_status || "incomplete").toLowerCase();
    
    // database - failure_reason
    const requiredAction = dataResults.required_action?.value || null;
    const rejectionReason = dataResults.rejection_reason?.value || null;

    // database - status
    let dbStatus = 'completed'; 
    let isConfirmed = false;
    let finalFailureReason = null;

    if (rawStatus === 'confirmed') {
      dbStatus = 'completed';
      isConfirmed = true;
    } else if (rawStatus === 'action required') {
      dbStatus = 'action_required'; 
      finalFailureReason = requiredAction; 
    } else if (rawStatus === 'failed') {
      dbStatus = 'failed';
      finalFailureReason = rejectionReason;
    } else {
      dbStatus = 'incomplete'; 
    }

    console.log(`[Webhook] status - ElevenLabs: ${rawStatus} -> DB: ${dbStatus}, Confirmed: ${isConfirmed}`);

    const supabase = await createClient();

    // get the latest pending data
    const { data: latestPending, error: fetchError } = await supabase
      .from('reservations')
      .select('id')
      .eq('status', 'calling')
      .order('created_at', { ascending: false })
      .limit(1)
      .single();

    if (fetchError || !latestPending) {
      console.error('[Webhook] Did not find pending status reservation:', fetchError);
      return NextResponse.json({ success: false, message: 'No pending reservation found' }, { status: 200 });
    }

    const targetId = latestPending.id;
    console.log(`[Webhook] target reservation ID: ${targetId}`);

    // TODO: [Next Stage - This part needs to be refactored after integrating Twilio]
    // need conversation_id
    // const realConvId = body.conversation_id || body.data?.conversation_id;
    // .eq('conversation_id', realConvId) replace .eq('id', targetId)。

    // update database
    const { error: updateError } = await supabase
      .from('reservations')
      .update({
        status: dbStatus,
        booking_confirmed: isConfirmed,
        failure_reason: finalFailureReason,
        confirmation_details: cleanedDetails, 
        
        updated_at: new Date().toISOString()
      })
      .eq('id', targetId);

    if (updateError) {
      console.error('[Webhook] Supabase update error:', updateError);
      return NextResponse.json({ error: 'Database update failed' }, { status: 500 });
    }

    return NextResponse.json({ success: true, updated_id: targetId });

  } catch (error) {
    console.error('[Webhook] Fatal error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}