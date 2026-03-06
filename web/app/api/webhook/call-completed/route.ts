import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    console.log('[Webhook] Received payload at:', new Date().toISOString());
    console.log('[Webhook] Webhook type:', body.type);
    console.log('[Webhook] Full payload:', JSON.stringify(body, null, 2));

    // Only process post_call_transcription webhooks
    // post_call_audio webhooks don't have transcript/analysis data
    if (body.type !== 'post_call_transcription') {
      console.log('[Webhook] Skipping non-transcription webhook:', body.type);
      return NextResponse.json({ success: true, message: 'Non-transcription webhook ignored' });
    }

    const rawData = body.data || {};
    const analysis = rawData.analysis || {};
    const dataResults = analysis.data_collection_results || {};
    const metadata = rawData.metadata || {};

    const convId = body.conversation_id || rawData.conversation_id || metadata.conversation_id;
    console.log(`[Webhook] Extracted conversation_id: ${convId}`);

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

    // Find conversation by conversation_id
    if (!convId) {
      console.error('[Webhook] Missing conversation_id in webhook payload');
      return NextResponse.json({ success: false, message: 'Missing conversation_id' }, { status: 400 });
    }

    const { data: targetConversation, error: fetchError } = await supabase
      .from('conversations')
      .select('id, reservation_id')
      .eq('conversation_id', convId)
      .single();

    if (fetchError || !targetConversation) {
      console.error('[Webhook] Did not find conversation with conversation_id:', convId, fetchError);
      return NextResponse.json({ success: false, message: 'No matching conversation found' }, { status: 200 });
    }

    const conversationId = targetConversation.id;
    const reservationId = targetConversation.reservation_id;
    console.log(`[Webhook] Found conversation ID: ${conversationId}, reservation ID: ${reservationId}`);

    // Audio
    let finalAudioUrl = null;
    if (convId && process.env.ELEVENLABS_API_KEY) {
      try {
        console.log(`[Webhook] Fetching audio for ${convId}...`);
        const audioRes = await fetch(`https://api.elevenlabs.io/v1/convai/conversations/${convId}/audio`, {
          method: 'GET',
          headers: { 'xi-api-key': process.env.ELEVENLABS_API_KEY }
        });

        if (audioRes.ok) {
          const audioBlob = await audioRes.blob();
          const audioBuffer = await audioBlob.arrayBuffer();
          const fileName = `${convId}.mp3`;

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
      console.warn('[Webhook] Missing convId or ELEVENLABS_API_KEY. Skipping audio fetch.');
    }


    // Update conversations table with call details
    const { error: updateConversationError } = await supabase
      .from('conversations')
      .update({
        status: dbStatus,
        booking_confirmed: isConfirmed,
        failure_reason: finalFailureReason,
        confirmation_details: cleanedDetails,
        audio_url: finalAudioUrl,
        call_ended_at: new Date().toISOString()
      })
      .eq('id', conversationId);

    if (updateConversationError) {
      console.error('[Webhook] Conversation update error:', updateConversationError);
      return NextResponse.json({ error: 'Database update failed' }, { status: 500 });
    }

    // Update reservations table with overall status
    const currentSummary = dbStatus === 'action_required'
      ? `Action required: ${finalFailureReason}`
      : cleanedDetails.summary;

    const { error: updateReservationError } = await supabase
      .from('reservations')
      .update({
        status: dbStatus,
        current_summary: currentSummary,
        updated_at: new Date().toISOString(),
        // Update old fields for backward compatibility with iOS
        booking_confirmed: isConfirmed,
        confirmation_details: cleanedDetails,
        failure_reason: finalFailureReason,
        audio_url: finalAudioUrl,
      })
      .eq('id', reservationId);

    if (updateReservationError) {
      console.error('[Webhook] Reservation update error:', updateReservationError);
      return NextResponse.json({ error: 'Database update failed' }, { status: 500 });
    }

    return NextResponse.json({
      success: true,
      conversation_id: conversationId,
      reservation_id: reservationId,
      audio_saved: !!finalAudioUrl
    });

  } catch (error) {
    console.error('[Webhook] Fatal error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}