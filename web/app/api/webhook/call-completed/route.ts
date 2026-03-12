import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    console.log('[Webhook] Received payload at:', new Date().toISOString());
    console.log('[Webhook] Webhook type:', body.type);

    // 1. Filter out unsupported webhook types
    if (body.type !== 'post_call_transcription' && body.type !== 'post_call_audio') {
      console.log('[Webhook] Skipping unsupported webhook type:', body.type);
      return NextResponse.json({ success: true, message: 'Webhook ignored' });
    }

    const rawData = body.data || {};
    const metadata = rawData.metadata || {};
    
    // Extract ElevenLabs conversation_id
    const convId = body.conversation_id || rawData.conversation_id || metadata.conversation_id;
    if (!convId) {
      console.error('[Webhook] Missing conversation_id in webhook payload');
      return NextResponse.json({ success: false, message: 'Missing conversation_id' }, { status: 400 });
    }

    const supabase = await createClient();

    // 2. Find the corresponding reservation in the database (match by conversation_id)
    const { data: targetConversation, error: fetchError } = await supabase
      .from('conversations')
      .select('id, reservation_id')
      .eq('conversation_id', convId)
      .single();

    if (fetchError || !targetConversation) {
      console.error('[Webhook] Did not find conversation with conversation_id:', convId);
      return NextResponse.json({ success: false, message: 'No matching conversation found' }, { status: 200 });
    }

    const conversationId = targetConversation.id;
    const reservationId = targetConversation.reservation_id;

    // ==========================================
    // 🌟 SCENARIO A: Process Audio Payload 
    // ==========================================
    if (body.type === 'post_call_audio') {
      console.log(`[Webhook] 🎧 Processing AUDIO payload for ${convId}`);
      
      const base64Audio = rawData.full_audio;
      if (!base64Audio) {
        return NextResponse.json({ success: false, message: 'No audio data found' }, { status: 400 });
      }

      // Convert Base64 string to MP3 Buffer
      const audioBuffer = Buffer.from(base64Audio, 'base64');
      const fileName = `${convId}.mp3`;

      // Upload to Supabase 'call_audios' storage bucket
      const { error: uploadError } = await supabase.storage
        .from('call_audios')
        .upload(fileName, audioBuffer, {
          contentType: 'audio/mpeg',
          upsert: true
        });

      if (uploadError) {
        console.error('[Webhook] ❌ Supabase storage upload failed:', uploadError);
        return NextResponse.json({ error: 'Audio upload failed' }, { status: 500 });
      }

      // Get public audio URL
      const { data: publicUrlData } = supabase.storage
        .from('call_audios')
        .getPublicUrl(fileName);
        
      const finalAudioUrl = publicUrlData.publicUrl;
      console.log(`[Webhook] ✅ Successfully saved audio URL: ${finalAudioUrl}`);

      // Only update the audio_url field to prevent overwriting transcription data
      await supabase.from('conversations').update({ audio_url: finalAudioUrl }).eq('id', conversationId);
      await supabase.from('reservations').update({ audio_url: finalAudioUrl }).eq('id', reservationId);

      return NextResponse.json({ success: true, audio_saved: true });
    }


    // ==========================================
    // 🌟 SCENARIO B: Process Transcription & Status
    // ==========================================
    if (body.type === 'post_call_transcription') {
      console.log(`[Webhook] 📝 Processing TRANSCRIPTION payload for ${convId}`);
      
      const analysis = rawData.analysis || {};
      const dataResults = analysis.data_collection_results || {};
      
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

      // Anti-phantom data mechanism: Ignore empty payloads to protect existing DB records
      if (cleanTranscript.length === 0 && cleanedDetails.call_stats.duration === 0) {
        console.log(`[Webhook] Intercepted phantom empty data. Canceling DB updates.`);
        return NextResponse.json({ success: true, message: 'Ignored empty phantom payload' });
      }

      const rawStatus = String(dataResults.reservation_status?.value || dataResults.reservation_status || "incomplete").toLowerCase();
      const requiredAction = dataResults.required_action?.value || null;
      const rejectionReason = dataResults.rejection_reason?.value || null;

      let dbStatus = 'completed';
      let isConfirmed = false;
      let finalFailureReason = null;

      // Priority 1: Check if there's a required_action (e.g., alternative time offered)
      if (requiredAction) {
        dbStatus = 'action_required';
        finalFailureReason = requiredAction;
        isConfirmed = false;
      } 
      // Priority 2: Check reservation_status
      else if (rawStatus === 'confirmed') {
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

      console.log(`[Webhook] Status updated -> DB: ${dbStatus}`);

      // Update conversations table (Note: audio_url is not overwritten here to preserve the audio webhook's update)
      await supabase
        .from('conversations')
        .update({
          status: dbStatus,
          booking_confirmed: isConfirmed,
          failure_reason: finalFailureReason,
          confirmation_details: cleanedDetails,
          call_ended_at: new Date().toISOString()
        })
        .eq('id', conversationId);

      // Update reservations table
      const currentSummary = dbStatus === 'action_required'
        ? `Action required: ${finalFailureReason}`
        : cleanedDetails.summary;

      await supabase
        .from('reservations')
        .update({
          status: dbStatus,
          current_summary: currentSummary,
          updated_at: new Date().toISOString(),
          booking_confirmed: isConfirmed,
          confirmation_details: cleanedDetails,
          failure_reason: finalFailureReason,
        })
        .eq('id', reservationId);

      return NextResponse.json({ success: true, conversation_id: conversationId });
    }

  } catch (error) {
    console.error('[Webhook] Fatal error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}