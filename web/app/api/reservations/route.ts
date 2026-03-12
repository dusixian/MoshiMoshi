import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'
import type { CreateReservationRequest } from '@/lib/types/reservation'

// POST /api/reservations - Create a new reservation request
export async function POST(request: NextRequest) {
  try {
    const body: CreateReservationRequest = await request.json()

    // Validate required fields
    const requiredFields = [
      'user_id',
      'restaurant_name',
      'restaurant_phone', 
      'reservation_date',
      'reservation_time',
      'party_size',
      'customer_name',
      'customer_phone'
    ] as const

    for (const field of requiredFields) {
      if (!body[field]) {
        return NextResponse.json(
          { error: `Missing required field: ${field}` },
          { status: 400 }
        )
      }
    }

    const supabase = await createClient()

    // Step 1: Insert new reservation with 'pending' status
    const { data: reservation, error: reservationError } = await supabase
      .from('reservations')
      .insert({
        user_id: body.user_id,
        restaurant_name: body.restaurant_name,
        restaurant_phone: body.restaurant_phone,
        reservation_date: body.reservation_date,
        reservation_time: body.reservation_time,
        party_size: body.party_size,
        customer_name: body.customer_name,
        customer_phone: body.customer_phone,
        customer_email: body.customer_email || null,
        special_requests: body.special_requests || null,
        status: 'pending'
      })
      .select()
      .single()

    if (reservationError || !reservation) {
      console.error('Database error:', reservationError)
      return NextResponse.json(
        { error: 'Failed to create reservation' },
        { status: 500 }
      )
    }

    // Step 2: Create conversation record (attempt_number = 1)
    const { data: conversation, error: conversationError } = await supabase
      .from('conversations')
      .insert({
        reservation_id: reservation.id,
        attempt_number: 1,
        status: 'pending',
        booking_confirmed: false,
      })
      .select()
      .single()

    if (conversationError || !conversation) {
      console.error('Failed to create conversation:', conversationError)
      // Rollback: delete the reservation we just created
      await supabase.from('reservations').delete().eq('id', reservation.id)
      return NextResponse.json(
        { error: 'Failed to create conversation record' },
        { status: 500 }
      )
    }

    const apiKey = process.env.ELEVENLABS_API_KEY
    const agentId = process.env.ELEVENLABS_AGENT_ID
    const agentPhoneNumberId = process.env.ELEVENLABS_AGENT_PHONE_NUMBER_ID
    if (!apiKey || !agentId || !agentPhoneNumberId) {
      console.error('ElevenLabs config missing:', { apiKey: !!apiKey, agentId: !!agentId, agentPhoneNumberId: !!agentPhoneNumberId })
      return NextResponse.json(
        { error: 'Server misconfiguration: ELEVENLABS_API_KEY, ELEVENLABS_AGENT_ID, and ELEVENLABS_AGENT_PHONE_NUMBER_ID must be set in .env.local' },
        { status: 500 }
      )
    }

    // Dynamic variables for the agent (match ElevenLabs convai dashboard)
    const dateFormatted = body.reservation_date.replace(/-/g, '/') // YYYY-MM-DD -> YYYY/MM/DD
    const dynamicVariables: Record<string, string | number> = {
      restaurant_name: body.restaurant_name,
      date: dateFormatted,
      time: body.reservation_time,
      party_size: body.party_size,
      name: body.customer_name,
      customer_phone: body.customer_phone,
      special_requests: body.special_requests?.trim() || 'None',
    }

    const outboundPayload = {
      agent_id: agentId,
      agent_phone_number_id: agentPhoneNumberId,
      to_number: body.restaurant_phone,
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
        console.error('[ElevenLabs outbound] Error:', elRes.status, elData)
        const errMessage = elData?.message || elRes.statusText || 'Outbound call failed'
        await supabase
          .from('reservations')
          .update({ status: 'failed', failure_reason: errMessage })
          .eq('id', reservation.id)
        return NextResponse.json(
          {
            success: false,
            error: 'Failed to initiate outbound call',
            message: errMessage,
            reservation: { ...reservation, status: 'failed', failure_reason: errMessage },
          },
          { status: 502 }
        )
      }

      conversationId = elData.conversation_id ?? null
      callSid = elData.callSid ?? null

      if (elData?.success && (conversationId || callSid)) {
        callStatus = 'calling'
      } else {
        // success is not true: mark reservation as failed and store reason
        const failureReason = elData?.message || 'Outbound call failed'
        await supabase
          .from('reservations')
          .update({
            status: 'failed',
            failure_reason: failureReason,
            ...(conversationId && { conversation_id: conversationId }),
            ...(callSid && { call_id: callSid }),
          })
          .eq('id', reservation.id)
        return NextResponse.json({
          success: false,
          message: failureReason,
          reservation: {
            ...reservation,
            status: 'failed',
            failure_reason: failureReason,
            conversation_id: conversationId,
            call_id: callSid,
          },
        }, { status: 200 })
      }
    } catch (err) {
      console.error('[ElevenLabs outbound] Request failed:', err)
      const errMessage = err instanceof Error ? err.message : 'Network error'
      await supabase
        .from('reservations')
        .update({ status: 'failed', failure_reason: errMessage })
        .eq('id', reservation.id)
      await supabase
        .from('conversations')
        .update({ status: 'failed', failure_reason: errMessage })
        .eq('id', conversation.id)
      return NextResponse.json(
        {
          success: false,
          error: 'Failed to reach ElevenLabs outbound call API',
          message: errMessage,
          reservation: { ...reservation, status: 'failed', failure_reason: errMessage },
        },
        { status: 502 }
      )
    }

    if (conversationId || callSid) {
      // Update both reservation and conversation records

      // Update reservation (status + latest_conversation_id)
      const { error: updateReservationError } = await supabase
        .from('reservations')
        .update({
          status: callStatus,
          latest_conversation_id: conversationId,
          // Keep old fields for backward compatibility (to be removed later)
          ...(conversationId && { conversation_id: conversationId }),
          ...(callSid && { call_id: callSid }),
        })
        .eq('id', reservation.id)

      if (updateReservationError) {
        console.error('Failed to update reservation:', updateReservationError)
      }

      // Update conversation record (conversation_id, call_id, status)
      const { error: updateConversationError } = await supabase
        .from('conversations')
        .update({
          conversation_id: conversationId,
          call_id: callSid,
          status: callStatus,
        })
        .eq('id', conversation.id)

      if (updateConversationError) {
        console.error('Failed to update conversation:', updateConversationError)
      }
    }

    return NextResponse.json({
      success: true,
      reservation: {
        ...reservation,
        status: callStatus,
        conversation_id: conversationId,
        call_id: callSid,
      },
      message: callStatus === 'calling' ? 'Reservation created, call initiated' : 'Reservation created',
    }, { status: 201 })

  } catch (error) {
    console.error('Error creating reservation:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}

// GET /api/reservations - List all reservations (for testing)
export async function GET() {
  try {
    const supabase = await createClient()

    const { data, error } = await supabase
      .from('reservations')
      .select('*')
      .order('created_at', { ascending: false })

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json({ reservations: data })
  } catch (error) {
    console.error('Error fetching reservations:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
