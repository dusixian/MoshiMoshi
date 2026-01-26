import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'
import type { CallCompletedWebhook, ReservationStatus } from '@/lib/types/reservation'

// POST /api/webhook/call-completed
// This endpoint receives the post-call webhook from ElevenLabs
// when the call ends and analysis is complete
export async function POST(request: NextRequest) {
  try {
    const body: CallCompletedWebhook = await request.json()

    console.log('[Webhook] Received call completion:', JSON.stringify(body, null, 2))

    // Validate required fields
    if (!body.reservation_id) {
      return NextResponse.json(
        { error: 'Missing reservation_id' },
        { status: 400 }
      )
    }

    const supabase = await createClient()

    // Determine the new status based on call result
    // Valid statuses: 'pending', 'calling', 'completed', 'failed'
    let newStatus: ReservationStatus = 'completed'
    
    if (body.status === 'failed' || body.status === 'no_answer') {
      newStatus = 'failed'
    }
    // Use 'completed' for both confirmed and rejected reservations
    // The actual confirmation status is stored in booking_confirmed field

    // Update the reservation with call results
    const { data, error } = await supabase
      .from('reservations')
      .update({
        status: newStatus,
        call_id: body.call_sid,
        booking_confirmed: body.analysis?.reservation_confirmed ?? false,
        confirmation_details: body.analysis ? {
          restaurant_response: body.analysis.restaurant_response,
          confirmed_date: body.analysis.confirmed_date,
          confirmed_time: body.analysis.confirmed_time,
          notes: body.analysis.notes,
          duration: body.duration,
          recording_url: body.recording_url
        } : null,
        failure_reason: newStatus === 'failed' ? (body.status || 'Call failed') : null,
        call_ended_at: new Date().toISOString()
      })
      .eq('id', body.reservation_id)
      .select()
      .single()

    if (error) {
      console.error('[Webhook] Database error:', error)
      return NextResponse.json(
        { error: 'Failed to update reservation' },
        { status: 500 }
      )
    }

    console.log(`[Webhook] Reservation ${body.reservation_id} updated to status: ${newStatus}`)

    return NextResponse.json({
      success: true,
      reservation: data
    })

  } catch (error) {
    console.error('[Webhook] Error processing webhook:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
