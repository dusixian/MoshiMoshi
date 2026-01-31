import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

// ElevenLabs conversation response type
interface ElevenLabsConversation {
  agent_id: string
  conversation_id: string
  status: string
  transcript: Array<{
    role: string
    time_in_call_secs: number
    message: string
  }>
  metadata: {
    start_time_unix_secs: number
    call_duration_secs: number
  }
  analysis?: {
    data_collection_results?: Record<string, unknown>
    [key: string]: unknown
  }
  has_audio: boolean
  has_user_audio: boolean
  has_response_audio: boolean
}

// POST /api/reservations/[id]/get-conversation
// Fetches conversation details from ElevenLabs and updates the reservation
export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params
    const supabase = await createClient()

    // Get the reservation to find conversation_id
    const { data: reservation, error: fetchError } = await supabase
      .from('reservation_dev')
      .select('*')
      .eq('id', id)
      .single()

    if (fetchError || !reservation) {
      return NextResponse.json(
        { error: 'Reservation not found' },
        { status: 404 }
      )
    }

    if (!reservation.conversation_id) {
      return NextResponse.json(
        { error: 'No conversation_id found for this reservation' },
        { status: 400 }
      )
    }

    // Fetch conversation details from ElevenLabs
    const elevenLabsApiKey = process.env.ELEVENLABS_API_KEY
    
    if (!elevenLabsApiKey) {
      return NextResponse.json(
        { error: 'ELEVENLABS_API_KEY not configured' },
        { status: 500 }
      )
    }

    const elevenLabsResponse = await fetch(
      `https://api.elevenlabs.io/v1/convai/conversations/${reservation.conversation_id}`,
      {
        headers: {
          'xi-api-key': elevenLabsApiKey
        }
      }
    )

    if (!elevenLabsResponse.ok) {
      const errorText = await elevenLabsResponse.text()
      console.error('ElevenLabs API error:', errorText)
      return NextResponse.json(
        { error: `ElevenLabs API error: ${elevenLabsResponse.status}` },
        { status: elevenLabsResponse.status }
      )
    }

    const conversation: ElevenLabsConversation = await elevenLabsResponse.json()

    // Determine if booking was confirmed based on conversation status
    const isCompleted = conversation.status === 'done' || conversation.status === 'completed'
    const dataCollectionResults = conversation.analysis?.data_collection_results || null

    // Update reservation with conversation details
    const { data: updatedReservation, error: updateError } = await supabase
      .from('reservation_dev')
      .update({
        status: isCompleted ? 'completed' : (conversation.status === 'failed' ? 'failed' : 'calling'),
        data_collection_results: dataCollectionResults,
        confirmation_details: {
          transcript: conversation.transcript,
          call_duration_secs: conversation.metadata?.call_duration_secs,
          start_time_unix_secs: conversation.metadata?.start_time_unix_secs,
          analysis: conversation.analysis
        },
        call_ended_at: isCompleted ? new Date().toISOString() : null
      })
      .eq('id', id)
      .select()
      .single()

    if (updateError) {
      console.error('Database update error:', updateError)
      return NextResponse.json(
        { error: 'Failed to update reservation' },
        { status: 500 }
      )
    }

    return NextResponse.json({
      success: true,
      reservation: updatedReservation,
      conversation: {
        status: conversation.status,
        transcript: conversation.transcript,
        metadata: conversation.metadata,
        data_collection_results: dataCollectionResults
      }
    })

  } catch (error) {
    console.error('Error fetching conversation:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
