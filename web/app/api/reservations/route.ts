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

    // Insert new reservation with 'pending' status
    const { data, error } = await supabase
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
        special_requests: body.special_requests || null,
        status: 'pending'
      })
      .select()
      .single()

    if (error) {
      console.error('Database error:', error)
      return NextResponse.json(
        { error: 'Failed to create reservation' },
        { status: 500 }
      )
    }

    const apiKey = process.env.ELEVENLABS_API_KEY
    if (!apiKey) {
      console.error('ELEVENLABS_API_KEY is not set')
      return NextResponse.json(
        { error: 'Server misconfiguration: ELEVENLABS_API_KEY missing' },
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
      agent_id: 'agent_1901kfebxqqmf3t8199cjbg2h9dt',
      agent_phone_number_id: 'phnum_7201kjre5njbethvynsv2e39tcjj',
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
          .eq('id', data.id)
        return NextResponse.json(
          {
            success: false,
            error: 'Failed to initiate outbound call',
            message: errMessage,
            reservation: { ...data, status: 'failed', failure_reason: errMessage },
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
          .eq('id', data.id)
        return NextResponse.json({
          success: false,
          message: failureReason,
          reservation: {
            ...data,
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
        .eq('id', data.id)
      return NextResponse.json(
        {
          success: false,
          error: 'Failed to reach ElevenLabs outbound call API',
          message: errMessage,
          reservation: { ...data, status: 'failed', failure_reason: errMessage },
        },
        { status: 502 }
      )
    }

    if (conversationId || callSid) {
      const { error: updateError } = await supabase
        .from('reservations')
        .update({
          status: callStatus,
          ...(conversationId && { conversation_id: conversationId }),
          ...(callSid && { call_id: callSid }),
        })
        .eq('id', data.id)

      if (updateError) {
        console.error('Failed to update reservation with conversation_id/call_id:', updateError)
      }
    }

    return NextResponse.json({
      success: true,
      reservation: {
        ...data,
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
