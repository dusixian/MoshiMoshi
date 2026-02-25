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

    const realConvId = body.conversation_id || rawData.conversation_id || metadata.conversation_id;
    console.log(`[Webhook] Extracted conversation_id: ${realConvId}`);

    const cleanTranscript = (rawData.transcript || []).map((msg: any) => ({
      role: msg.role || "unknown",
      message: msg.message || ""
    }));

    const cleanedDetails = {
      summary: analysis.transcript_summary || "",
      results: dataResults,
      transcript: cleanTranscript,
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
    } else if (rawStatus === 'action_required') {
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

    // Audio
    let finalAudioUrl = null;
    if (realConvId && process.env.ELEVENLABS_API_KEY) {
      try {
        console.log(`[Webhook] Fetching audio for ${realConvId}...`);
        const audioRes = await fetch(`https://api.elevenlabs.io/v1/convai/conversations/${realConvId}/audio`, {
          method: 'GET',
          headers: { 'xi-api-key': process.env.ELEVENLABS_API_KEY }
        });

        if (audioRes.ok) {
          const audioBlob = await audioRes.blob();
          const audioBuffer = await audioBlob.arrayBuffer();
          const fileName = `${realConvId}.mp3`;

          // to call_audios bucket
          const { error: uploadError } = await supabase.storage
            .from('call_audios')
            .upload(fileName, audioBuffer, {
              contentType: 'audio/mpeg',
              upsert: true
            });

          if (uploadError) {
            console.error('[Webhook] Supabase storage upload failed:', uploadError);
          } else {
            const { data: publicUrlData } = supabase.storage
              .from('call_audios')
              .getPublicUrl(fileName);
            
            finalAudioUrl = publicUrlData.publicUrl;
            console.log(`[Webhook] Successfully saved audio URL: ${finalAudioUrl}`);
          }
        } else {
          console.error('[Webhook] Failed to fetch audio from ElevenLabs. Status:', audioRes.status);
        }
      } catch (audioError) {
        console.error('[Webhook] Error during audio processing:', audioError);
      }
    } else {
      console.warn('[Webhook] Missing realConvId or ELEVENLABS_API_KEY. Skipping audio fetch.');
    }


    // update database
    const { error: updateError } = await supabase
      .from('reservations')
      .update({
        status: dbStatus,
        booking_confirmed: isConfirmed,
        failure_reason: finalFailureReason,
        confirmation_details: cleanedDetails, 
        audio_url: finalAudioUrl,
        updated_at: new Date().toISOString()
      })
      .eq('id', targetId);

    if (updateError) {
      console.error('[Webhook] Supabase update error:', updateError);
      return NextResponse.json({ error: 'Database update failed' }, { status: 500 });
    }

    return NextResponse.json({ success: true, updated_id: targetId, audio_saved: !!finalAudioUrl });

  } catch (error) {
    console.error('[Webhook] Fatal error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}