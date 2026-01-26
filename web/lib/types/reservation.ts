export type ReservationStatus = 
  | 'pending'      // Just created, waiting to start call
  | 'calling'      // Call in progress
  | 'completed'    // Call finished (check booking_confirmed for result)
  | 'failed'       // Call failed or couldn't connect

// Database row type (matches actual database schema)
export interface Reservation {
  id: string
  restaurant_name: string | null
  restaurant_phone: string
  reservation_date: string
  reservation_time: string
  party_size: number
  customer_name: string
  customer_phone: string
  customer_email: string | null
  special_requests: string | null
  status: ReservationStatus
  call_id: string | null
  booking_confirmed: boolean | null
  confirmation_details: {
    restaurant_response?: string
    confirmed_date?: string
    confirmed_time?: string
    notes?: string
    duration?: number
    recording_url?: string
  } | null
  failure_reason: string | null
  created_at: string
  updated_at: string
  call_started_at: string | null
  call_ended_at: string | null
}

// Request to create a new reservation
export interface CreateReservationRequest {
  restaurant_name: string
  restaurant_phone: string
  reservation_date: string  // YYYY-MM-DD
  reservation_time: string  // HH:MM
  party_size: number
  customer_name: string
  customer_phone: string
  special_requests?: string
}

// Webhook payload from ElevenLabs (simplified/mock version)
export interface CallCompletedWebhook {
  call_sid: string
  reservation_id: string
  status: 'completed' | 'failed' | 'no_answer'
  duration: number
  recording_url?: string
  analysis: {
    reservation_confirmed: boolean
    confirmed_date?: string
    confirmed_time?: string
    restaurant_response: string
    notes?: string
  }
}
