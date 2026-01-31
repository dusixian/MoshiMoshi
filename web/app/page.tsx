'use client'

import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'

interface Reservation {
  id: string
  status: string
  restaurant_name: string
  restaurant_phone: string
  reservation_date: string
  reservation_time: string
  party_size: number
  customer_name: string
  conversation_id?: string
  booking_confirmed?: boolean
  data_collection_results?: Record<string, unknown>
  confirmation_details?: {
    transcript?: Array<{ role: string; message: string; time_in_call_secs: number }>
    call_duration_secs?: number
    analysis?: Record<string, unknown>
  }
}

interface ConversationData {
  status: string
  transcript: Array<{ role: string; message: string; time_in_call_secs: number }>
  metadata: { call_duration_secs: number; start_time_unix_secs: number }
  data_collection_results?: Record<string, unknown>
}

export default function TestPage() {
  const [loading, setLoading] = useState(false)
  const [result, setResult] = useState<string>('')
  const [currentReservation, setCurrentReservation] = useState<Reservation | null>(null)
  const [conversationId, setConversationId] = useState('')
  const [conversationData, setConversationData] = useState<ConversationData | null>(null)

  const [form, setForm] = useState({
    restaurant_name: 'すし匠',
    restaurant_phone: '+81-3-1234-5678',
    reservation_date: '2026-01-25',
    reservation_time: '19:00',
    party_size: 2,
    customer_name: 'John Doe',
    customer_phone: '+1-555-123-4567',
    special_requests: 'Window seat if possible'
  })

  // Step 1: Create reservation
  const createReservation = async () => {
    setLoading(true)
    setResult('')
    try {
      const res = await fetch('/api/reservations', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(form)
      })
      const data = await res.json()
      setResult(JSON.stringify(data, null, 2))
      if (data.reservation) {
        setCurrentReservation(data.reservation)
      }
    } catch (error) {
      setResult(`Error: ${error}`)
    }
    setLoading(false)
  }

  // Step 2: Start call with conversation_id (simulating ElevenLabs API response)
  const startCall = async () => {
    if (!currentReservation) {
      setResult('No reservation created yet')
      return
    }
    if (!conversationId.trim()) {
      setResult('Please enter a conversation_id')
      return
    }
    setLoading(true)
    try {
      const res = await fetch(`/api/reservations/${currentReservation.id}/start-call`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ conversation_id: conversationId.trim() })
      })
      const data = await res.json()
      setResult(JSON.stringify(data, null, 2))
      if (data.reservation) {
        setCurrentReservation(data.reservation)
      }
    } catch (error) {
      setResult(`Error: ${error}`)
    }
    setLoading(false)
  }

  // Step 3: Get conversation details from ElevenLabs
  const getConversation = async () => {
    if (!currentReservation) {
      setResult('No reservation created yet')
      return
    }
    setLoading(true)
    try {
      const res = await fetch(`/api/reservations/${currentReservation.id}/get-conversation`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' }
      })
      const data = await res.json()
      setResult(JSON.stringify(data, null, 2))
      if (data.reservation) {
        setCurrentReservation(data.reservation)
      }
      if (data.conversation) {
        setConversationData(data.conversation)
      }
    } catch (error) {
      setResult(`Error: ${error}`)
    }
    setLoading(false)
  }

  // Step 4 (Alt): Mock call completion (success) - simulates ElevenLabs webhook
  const mockCallSuccess = async () => {
    if (!currentReservation) {
      setResult('No reservation created yet')
      return
    }
    setLoading(true)
    try {
      const res = await fetch('/api/test/mock-call-complete', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ 
          reservation_id: currentReservation.id, 
          success: true 
        })
      })
      const data = await res.json()
      setResult(JSON.stringify(data, null, 2))
      if (data.webhook_response?.reservation) {
        setCurrentReservation(data.webhook_response.reservation)
      }
    } catch (error) {
      setResult(`Error: ${error}`)
    }
    setLoading(false)
  }

  // Step 4 alt: Mock call completion (failure) - simulates ElevenLabs webhook
  const mockCallFailed = async () => {
    if (!currentReservation) {
      setResult('No reservation created yet')
      return
    }
    setLoading(true)
    try {
      const res = await fetch('/api/test/mock-call-complete', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ 
          reservation_id: currentReservation.id, 
          success: false 
        })
      })
      const data = await res.json()
      setResult(JSON.stringify(data, null, 2))
      if (data.webhook_response?.reservation) {
        setCurrentReservation(data.webhook_response.reservation)
      }
    } catch (error) {
      setResult(`Error: ${error}`)
    }
    setLoading(false)
  }

  // Check current reservation status
  const checkStatus = async () => {
    if (!currentReservation) {
      setResult('No reservation created yet')
      return
    }
    setLoading(true)
    try {
      const res = await fetch(`/api/reservations/${currentReservation.id}`)
      const data = await res.json()
      setResult(JSON.stringify(data, null, 2))
      if (data.reservation) {
        setCurrentReservation(data.reservation)
      }
    } catch (error) {
      setResult(`Error: ${error}`)
    }
    setLoading(false)
  }

  // List all reservations
  const listAll = async () => {
    setLoading(true)
    try {
      const res = await fetch('/api/reservations')
      const data = await res.json()
      setResult(JSON.stringify(data, null, 2))
    } catch (error) {
      setResult(`Error: ${error}`)
    }
    setLoading(false)
  }

  return (
    <main className="min-h-screen bg-background p-8">
      <div className="mx-auto max-w-4xl space-y-6">
        <h1 className="text-3xl font-bold text-foreground">
          Reservation Backend Test
        </h1>
        <p className="text-muted-foreground">
          Test the reservation API flow: Create reservation, mock call completion, check status
        </p>

        <div className="grid gap-6 md:grid-cols-2">
          {/* Form */}
          <Card>
            <CardHeader>
              <CardTitle>Create Reservation</CardTitle>
              <CardDescription>Fill in reservation details</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>Restaurant Name</Label>
                  <Input 
                    value={form.restaurant_name}
                    onChange={(e) => setForm({...form, restaurant_name: e.target.value})}
                  />
                </div>
                <div className="space-y-2">
                  <Label>Restaurant Phone</Label>
                  <Input 
                    value={form.restaurant_phone}
                    onChange={(e) => setForm({...form, restaurant_phone: e.target.value})}
                  />
                </div>
              </div>
              <div className="grid grid-cols-3 gap-4">
                <div className="space-y-2">
                  <Label>Date</Label>
                  <Input 
                    type="date"
                    value={form.reservation_date}
                    onChange={(e) => setForm({...form, reservation_date: e.target.value})}
                  />
                </div>
                <div className="space-y-2">
                  <Label>Time</Label>
                  <Input 
                    type="time"
                    value={form.reservation_time}
                    onChange={(e) => setForm({...form, reservation_time: e.target.value})}
                  />
                </div>
                <div className="space-y-2">
                  <Label>Party Size</Label>
                  <Input 
                    type="number"
                    value={form.party_size}
                    onChange={(e) => setForm({...form, party_size: parseInt(e.target.value)})}
                  />
                </div>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>Customer Name</Label>
                  <Input 
                    value={form.customer_name}
                    onChange={(e) => setForm({...form, customer_name: e.target.value})}
                  />
                </div>
                <div className="space-y-2">
                  <Label>Customer Phone</Label>
                  <Input 
                    value={form.customer_phone}
                    onChange={(e) => setForm({...form, customer_phone: e.target.value})}
                  />
                </div>
              </div>
              <div className="space-y-2">
                <Label>Special Requests</Label>
                <Textarea 
                  value={form.special_requests}
                  onChange={(e) => setForm({...form, special_requests: e.target.value})}
                />
              </div>
              <Button onClick={createReservation} disabled={loading} className="w-full">
                1. Create Reservation
              </Button>
            </CardContent>
          </Card>

          {/* Actions & Status */}
          <div className="space-y-6">
            <Card>
              <CardHeader>
                <CardTitle>Current Reservation</CardTitle>
                <CardDescription>
                  {currentReservation 
                    ? `ID: ${currentReservation.id.slice(0, 8)}... | Status: ${currentReservation.status}${currentReservation.conversation_id ? ` | Conv: ${currentReservation.conversation_id.slice(0, 12)}...` : ''}`
                    : 'No reservation yet'}
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                {/* Step 2: Start Call with conversation_id */}
                <div className="space-y-2">
                  <Label>Step 2: Enter Conversation ID (from ElevenLabs)</Label>
                  <div className="flex gap-2">
                    <Input 
                      placeholder="conversation_id from ElevenLabs"
                      value={conversationId}
                      onChange={(e) => setConversationId(e.target.value)}
                      disabled={!currentReservation || currentReservation.status !== 'pending'}
                    />
                    <Button 
                      onClick={startCall} 
                      disabled={loading || !currentReservation || currentReservation.status !== 'pending'}
                    >
                      Start Call
                    </Button>
                  </div>
                  <p className="text-xs text-muted-foreground">
                    Go to ElevenLabs, make the call, then paste the conversation_id here
                  </p>
                </div>

                {/* Step 3: Get Conversation Details from ElevenLabs */}
                <div className="space-y-2">
                  <Label>Step 3: Get Conversation Details</Label>
                  <Button 
                    onClick={getConversation} 
                    disabled={loading || !currentReservation || !currentReservation.conversation_id}
                    className="w-full"
                  >
                    Fetch from ElevenLabs
                  </Button>
                  <p className="text-xs text-muted-foreground">
                    Calls ElevenLabs API to get conversation transcript and data_collection_results
                  </p>
                </div>

                {/* Step 4 (Alt): Mock webhook completion */}
                <div className="space-y-2">
                  <Label>Alt: Simulate Call Completion (Mock)</Label>
                  <div className="grid grid-cols-2 gap-3">
                    <Button 
                      onClick={mockCallSuccess} 
                      disabled={loading || !currentReservation || currentReservation.status !== 'calling'} 
                      variant="outline"
                      className="bg-transparent"
                    >
                      Mock Success
                    </Button>
                    <Button 
                      onClick={mockCallFailed} 
                      disabled={loading || !currentReservation || currentReservation.status !== 'calling'} 
                      variant="outline"
                      className="bg-transparent"
                    >
                      Mock Failure
                    </Button>
                  </div>
                </div>

                {/* Utility buttons */}
                <div className="space-y-2 border-t pt-4">
                  <Button onClick={checkStatus} disabled={loading || !currentReservation} variant="outline" className="w-full bg-transparent">
                    Check Status
                  </Button>
                  <Button onClick={listAll} disabled={loading} variant="secondary" className="w-full">
                    List All Reservations
                  </Button>
                </div>
              </CardContent>
            </Card>

            {/* Success Card */}
            {currentReservation && currentReservation.status === 'completed' && currentReservation.booking_confirmed && (
              <Card className="border-green-500 bg-green-50 dark:bg-green-950">
                <CardHeader>
                  <CardTitle className="text-green-700 dark:text-green-300">Reservation Confirmed!</CardTitle>
                </CardHeader>
                <CardContent className="text-sm text-green-800 dark:text-green-200">
                  <p><strong>Restaurant:</strong> {currentReservation.restaurant_name}</p>
                  <p><strong>Date:</strong> {currentReservation.confirmation_details?.confirmed_date || currentReservation.reservation_date}</p>
                  <p><strong>Time:</strong> {currentReservation.confirmation_details?.confirmed_time || currentReservation.reservation_time}</p>
                  {currentReservation.confirmation_details?.restaurant_response && (
                    <p><strong>Response:</strong> {currentReservation.confirmation_details.restaurant_response}</p>
                  )}
                </CardContent>
              </Card>
            )}

            {/* Failure Card */}
            {currentReservation && currentReservation.status === 'failed' && (
              <Card className="border-red-500 bg-red-50 dark:bg-red-950">
                <CardHeader>
                  <CardTitle className="text-red-700 dark:text-red-300">Call Failed</CardTitle>
                </CardHeader>
                <CardContent className="text-sm text-red-800 dark:text-red-200">
                  <p>The reservation call could not be completed.</p>
                </CardContent>
              </Card>
            )}

            {/* Data Collection Results */}
            {conversationData?.data_collection_results && (
              <Card className="border-blue-500 bg-blue-50 dark:bg-blue-950">
                <CardHeader>
                  <CardTitle className="text-blue-700 dark:text-blue-300">Data Collection Results</CardTitle>
                </CardHeader>
                <CardContent>
                  <pre className="overflow-auto rounded bg-blue-100 p-3 text-xs text-blue-900 dark:bg-blue-900 dark:text-blue-100">
                    {JSON.stringify(conversationData.data_collection_results, null, 2)}
                  </pre>
                </CardContent>
              </Card>
            )}

            {/* Conversation Transcript */}
            {conversationData?.transcript && conversationData.transcript.length > 0 && (
              <Card>
                <CardHeader>
                  <CardTitle>Conversation Transcript</CardTitle>
                  <CardDescription>
                    Duration: {conversationData.metadata?.call_duration_secs || 0}s
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-2 max-h-64 overflow-auto">
                  {conversationData.transcript.map((turn, i) => (
                    <div 
                      key={i} 
                      className={`rounded p-2 text-sm ${
                        turn.role === 'user' 
                          ? 'bg-muted text-foreground' 
                          : 'bg-primary/10 text-primary'
                      }`}
                    >
                      <span className="font-semibold capitalize">{turn.role}</span>
                      <span className="text-muted-foreground text-xs ml-2">({turn.time_in_call_secs}s)</span>
                      <p className="mt-1">{turn.message}</p>
                    </div>
                  ))}
                </CardContent>
              </Card>
            )}
          </div>
        </div>

        {/* API Response */}
        <Card>
          <CardHeader>
            <CardTitle>API Response</CardTitle>
          </CardHeader>
          <CardContent>
            <pre className="max-h-96 overflow-auto rounded-lg bg-muted p-4 text-sm">
              {result || 'Response will appear here...'}
            </pre>
          </CardContent>
        </Card>
      </div>
    </main>
  )
}
