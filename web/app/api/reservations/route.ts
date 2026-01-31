import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'
import type { CreateReservationRequest } from '@/lib/types/reservation'

// POST /api/reservations - Create a new reservation request
export async function POST(request: NextRequest) {
  try {
    const body: CreateReservationRequest = await request.json()

    // Validate required fields
    const requiredFields = [
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
      .from('reservation_dev')
      .insert({
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

    // Reservation created with 'pending' status
    // Next step: Call ElevenLabs API to initiate outbound call
    // The API will return conversation_id which should be used to update the reservation
    
    return NextResponse.json({
      success: true,
      reservation: data,
      message: 'Reservation created. Ready to initiate call.',
      next_step: 'Call POST /api/reservations/{id}/start-call with conversation_id to begin the call'
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
      .from('reservation_dev')
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
