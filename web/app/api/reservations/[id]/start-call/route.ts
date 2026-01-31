import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

interface StartCallRequest {
  conversation_id: string
  call_sid?: string
}

// POST /api/reservations/[id]/start-call
// Called after ElevenLabs outbound call API returns conversation_id
export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params
    const body: StartCallRequest = await request.json()

    if (!body.conversation_id) {
      return NextResponse.json(
        { error: 'conversation_id is required' },
        { status: 400 }
      )
    }

    const supabase = await createClient()

    // Check if reservation exists and is in pending status
    const { data: existing, error: fetchError } = await supabase
      .from('reservation_dev')
      .select('*')
      .eq('id', id)
      .single()

    if (fetchError || !existing) {
      return NextResponse.json(
        { error: 'Reservation not found' },
        { status: 404 }
      )
    }

    if (existing.status !== 'pending') {
      return NextResponse.json(
        { error: `Cannot start call for reservation with status: ${existing.status}` },
        { status: 400 }
      )
    }

    // Update reservation with conversation_id and change status to 'calling'
    const { data, error } = await supabase
      .from('reservation_dev')
      .update({
        status: 'calling',
        conversation_id: body.conversation_id,
        call_started_at: new Date().toISOString()
      })
      .eq('id', id)
      .select()
      .single()

    if (error) {
      console.error('Database error:', error)
      return NextResponse.json(
        { error: 'Failed to update reservation' },
        { status: 500 }
      )
    }

    return NextResponse.json({
      success: true,
      reservation: data,
      message: 'Call initiated. Waiting for call completion webhook.'
    })

  } catch (error) {
    console.error('Error starting call:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
