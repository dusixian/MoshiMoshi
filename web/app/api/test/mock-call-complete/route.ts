import { NextRequest, NextResponse } from 'next/server'

// POST /api/test/mock-call-complete
// Test endpoint to simulate ElevenLabs webhook
// Usage: POST with { reservation_id: "xxx", success: true/false }
export async function POST(request: NextRequest) {
  try {
    const { reservation_id, success = true } = await request.json()

    if (!reservation_id) {
      return NextResponse.json(
        { error: 'Missing reservation_id' },
        { status: 400 }
      )
    }

    // Construct mock webhook payload
    const mockWebhook = {
      call_sid: `twilio_call_${Date.now()}`,
      reservation_id,
      status: success ? 'completed' : 'failed',
      duration: success ? Math.floor(Math.random() * 120) + 30 : 0,
      recording_url: success ? `https://example.com/recordings/${reservation_id}.mp3` : undefined,
      analysis: success ? {
        reservation_confirmed: true,
        confirmed_date: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
        confirmed_time: '19:00',
        restaurant_response: 'はい、ご予約承りました。12月25日19時、2名様でお待ちしております。',
        notes: 'Window seat requested and confirmed'
      } : {
        reservation_confirmed: false,
        restaurant_response: '申し訳ございません。その日時は満席となっております。',
        notes: 'Restaurant fully booked'
      }
    }

    // Call the actual webhook endpoint
    const baseUrl = request.nextUrl.origin
    const webhookResponse = await fetch(`${baseUrl}/api/webhook/call-completed`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(mockWebhook)
    })

    const result = await webhookResponse.json()

    return NextResponse.json({
      message: 'Mock webhook sent',
      webhook_payload: mockWebhook,
      webhook_response: result
    })

  } catch (error) {
    console.error('Error in mock endpoint:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
