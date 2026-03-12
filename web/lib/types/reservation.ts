export type ReservationStatus =
  | 'pending'           // Just created, waiting to start call
  | 'calling'           // Call in progress
  | 'confirmed'         // Reservation confirmed
  | 'action_required'   // Needs user response
  | 'incomplete'        // Call incomplete
  | 'failed'            // Call failed or couldn't connect

// Conversation table - stores individual call attempts
export interface Conversation {
  id: string
  reservation_id: string
  attempt_number: number
  conversation_id: string | null
  call_id: string | null
  call_started_at: string | null
  call_ended_at: string | null
  created_at: string
  status: ReservationStatus
  booking_confirmed: boolean
  confirmation_details: any
  failure_reason: string | null
  audio_url: string | null
  user_response: string | null
}

// Reservation table - stores reservation info (订单本身)
export interface Reservation {
  id: string
  user_id: string
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
  created_at: string
  updated_at: string

  // New fields
  current_summary: string | null
  latest_conversation_id: string | null

  // Old fields (to be deprecated after migration)
  conversation_id: string | null
  call_id: string | null
  booking_confirmed: boolean | null
  confirmation_details: any
  failure_reason: string | null
  call_started_at: string | null
  call_ended_at: string | null
  audio_url: string | null
}

// Request to create a new reservation
export interface CreateReservationRequest {
  user_id: string
  restaurant_name: string
  restaurant_phone: string
  reservation_date: string  // YYYY-MM-DD
  reservation_time: string  // HH:MM
  party_size: number
  customer_name: string
  customer_phone: string
  customer_email?: string
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
