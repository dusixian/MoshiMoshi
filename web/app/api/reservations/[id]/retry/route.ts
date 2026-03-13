import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

// POST /api/reservations/[id]/retry - Retry a failed reservation with user's response
export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const body = await request.json()
    const { user_response } = body

    if (!user_response || typeof user_response !== 'string') {
      return NextResponse.json(
        { error: 'Missing or invalid user_response' },
        { status: 400 }
      )
    }

    const { id: reservationId } = await params
    const supabase = await createClient()

    // Step 1: Fetch reservation details
    const { data: reservation, error: reservationError } = await supabase
      .from('reservations')
      .select('*')
      .eq('id', reservationId)
      .single()

    if (reservationError || !reservation) {
      console.error('[Retry] Reservation not found:', reservationError)
      return NextResponse.json(
        { error: 'Reservation not found' },
        { status: 404 }
      )
    }

    // Step 2: Get the latest conversation to find previous issue
    const { data: conversations, error: conversationsError } = await supabase
      .from('conversations')
      .select('*')
      .eq('reservation_id', reservationId)
      .order('attempt_number', { ascending: false })
      .limit(1)

    if (conversationsError || !conversations || conversations.length === 0) {
      console.error('[Retry] No previous conversation found:', conversationsError)
      return NextResponse.json(
        { error: 'No previous conversation found' },
        { status: 404 }
      )
    }

    const previousConversation = conversations[0]
    const nextAttemptNumber = previousConversation.attempt_number + 1
    const previousIssue = previousConversation.failure_reason || 'Previous attempt was unsuccessful'
    const lastConversationSummary = previousConversation.confirmation_details?.summary || 'No summary available.'

    console.log(`[Retry] Starting attempt ${nextAttemptNumber} for reservation ${reservationId}`)
    console.log(`[Retry] Previous issue: ${previousIssue}`)
    console.log(`[Retry] User response: ${user_response}`)

    // Step 3: Create new conversation record
    const { data: newConversation, error: newConversationError } = await supabase
      .from('conversations')
      .insert({
        reservation_id: reservationId,
        attempt_number: nextAttemptNumber,
        status: 'pending',
        booking_confirmed: false,
        user_response: user_response,
        restaurant_name: reservation.restaurant_name,
        restaurant_phone: reservation.restaurant_phone,
        reservation_date: reservation.reservation_date,
        reservation_time: reservation.reservation_time,
        party_size: reservation.party_size,
        customer_name: reservation.customer_name,
        customer_phone: reservation.customer_phone,
        customer_email: reservation.customer_email || null,
        special_requests: reservation.special_requests || null,
      })
      .select()
      .single()

    if (newConversationError || !newConversation) {
      console.error('[Retry] Failed to create conversation:', newConversationError)
      return NextResponse.json(
        { error: 'Failed to create conversation record' },
        { status: 500 }
      )
    }

    // Step 4: Prepare ElevenLabs outbound call
    const apiKey = process.env.ELEVENLABS_API_KEY
    const agentId = process.env.ELEVENLABS_RECALL_AGENT_ID
    const agentPhoneNumberId = process.env.ELEVENLABS_AGENT_PHONE_NUMBER_ID
    if (!apiKey || !agentId || !agentPhoneNumberId) {
      console.error('[Retry] ElevenLabs config missing:', { apiKey: !!apiKey, agentId: !!agentId, agentPhoneNumberId: !!agentPhoneNumberId })
      return NextResponse.json(
        { error: 'Server misconfiguration: ELEVENLABS_API_KEY, ELEVENLABS_RECALL_AGENT_ID, and ELEVENLABS_AGENT_PHONE_NUMBER_ID must be set' },
        { status: 500 }
      )
    }

    // Build dynamic variables with all context
    const dateFormatted = reservation.reservation_date.replace(/-/g, '/')
    const isModification = !!previousConversation.modify_tag
    const conversationRecord = isModification
      ? JSON.stringify({
          restaurant_name: previousConversation.restaurant_name,
          restaurant_phone: previousConversation.restaurant_phone,
          reservation_date: previousConversation.reservation_date,
          reservation_time: previousConversation.reservation_time,
          party_size: previousConversation.party_size,
          customer_name: previousConversation.customer_name,
          customer_phone: previousConversation.customer_phone,
          special_requests: previousConversation.special_requests,
        })
      : ''
    const dynamicVariables: Record<string, string | number> = {
      restaurant_name: reservation.restaurant_name,
      date: dateFormatted,
      time: reservation.reservation_time,
      party_size: reservation.party_size,
      name: reservation.customer_name,
      customer_phone: reservation.customer_phone,
      special_requests: reservation.special_requests?.trim() || 'None',
      previous_issue: previousIssue,
      user_response: user_response,
      last_conversation_summary: lastConversationSummary,
      modify_tag: previousConversation.modify_tag || '',
      conversation_record: conversationRecord,
    }

    const outboundPayload = {
      agent_id: agentId,
      agent_phone_number_id: agentPhoneNumberId,
      to_number: reservation.restaurant_phone,
      conversation_initiation_client_data: {
        dynamic_variables: dynamicVariables,
      },
    }

    let callStatus: 'calling' | 'pending' = 'pending'
    let conversationId: string | null = null
    let callSid: string | null = null

    try {
      const elRes = await fetch('https://api.elevenlabs.io/v1/convai/twilio/outbound-call', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'xi-api-key': apiKey,
        },
        body: JSON.stringify(outboundPayload),
      })

      const elData = await elRes.json().catch(() => ({})) as {
        success?: boolean
        message?: string
        conversation_id?: string
        callSid?: string
      }

      if (!elRes.ok) {
        console.error('[Retry ElevenLabs outbound] Error:', elRes.status, elData)
        const errMessage = elData?.message || elRes.statusText || 'Outbound call failed'
        await supabase
          .from('reservations')
          .update({ status: 'failed', failure_reason: errMessage })
          .eq('id', reservationId)
        return NextResponse.json(
          {
            success: false,
            error: 'Failed to initiate retry call',
            message: errMessage,
          },
          { status: 502 }
        )
      }

      conversationId = elData.conversation_id ?? null
      callSid = elData.callSid ?? null

      if (elData?.success && (conversationId || callSid)) {
        callStatus = 'calling'
      } else {
        const failureReason = elData?.message || 'Retry call failed'
        await supabase
          .from('reservations')
          .update({
            status: 'failed',
            failure_reason: failureReason,
          })
          .eq('id', reservationId)
        return NextResponse.json({
          success: false,
          message: failureReason,
        }, { status: 200 })
      }
    } catch (err) {
      console.error('[Retry ElevenLabs outbound] Request failed:', err)
      const errMessage = err instanceof Error ? err.message : 'Network error'
      await supabase
        .from('reservations')
        .update({ status: 'failed', failure_reason: errMessage })
        .eq('id', reservationId)
      return NextResponse.json(
        {
          success: false,
          error: 'Failed to reach ElevenLabs outbound call API',
          message: errMessage,
        },
        { status: 502 }
      )
    }

    if (conversationId || callSid) {
      // Update reservation (status + latest_conversation_id)
      const { error: updateReservationError } = await supabase
        .from('reservations')
        .update({
          status: callStatus,
          latest_conversation_id: conversationId,
        })
        .eq('id', reservationId)

      if (updateReservationError) {
        console.error('[Retry] Failed to update reservation:', updateReservationError)
      }

      // Update conversation record (conversation_id, call_id, status)
      const { error: updateConversationError } = await supabase
        .from('conversations')
        .update({
          conversation_id: conversationId,
          call_id: callSid,
          status: callStatus,
        })
        .eq('id', newConversation.id)

      if (updateConversationError) {
        console.error('[Retry] Failed to update conversation:', updateConversationError)
      }
    }

    return NextResponse.json({
      success: true,
      message: 'Retry call initiated',
      attempt_number: nextAttemptNumber,
      conversation_id: conversationId,
      call_sid: callSid,
    }, { status: 200 })

  } catch (error) {
    console.error('[Retry] Error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
