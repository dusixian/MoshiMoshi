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
  restaurant_response?: string
  confirmed_date?: string
  confirmed_time?: string
}

export default function TestPage() {
  const [loading, setLoading] = useState(false)
  const [result, setResult] = useState<string>('')
  const [currentReservation, setCurrentReservation] = useState<Reservation | null>(null)

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

  // Step 2: Mock call completion (success)
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

  // Step 2 alt: Mock call completion (failure)
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
                    ? `ID: ${currentReservation.id.slice(0, 8)}... | Status: ${currentReservation.status}`
                    : 'No reservation yet'}
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="grid grid-cols-2 gap-3">
                  <Button onClick={mockCallSuccess} disabled={loading || !currentReservation} variant="default">
                    2a. Mock Success
                  </Button>
                  <Button onClick={mockCallFailed} disabled={loading || !currentReservation} variant="destructive">
                    2b. Mock Failure
                  </Button>
                </div>
                <Button onClick={checkStatus} disabled={loading || !currentReservation} variant="outline" className="w-full bg-transparent">
                  Check Status
                </Button>
                <Button onClick={listAll} disabled={loading} variant="secondary" className="w-full">
                  List All Reservations
                </Button>
              </CardContent>
            </Card>

            {currentReservation && currentReservation.status === 'confirmed' && (
              <Card className="border-green-500 bg-green-50 dark:bg-green-950">
                <CardHeader>
                  <CardTitle className="text-green-700 dark:text-green-300">Reservation Confirmed!</CardTitle>
                </CardHeader>
                <CardContent className="text-sm text-green-800 dark:text-green-200">
                  <p><strong>Restaurant:</strong> {currentReservation.restaurant_name}</p>
                  <p><strong>Date:</strong> {currentReservation.confirmed_date || currentReservation.reservation_date}</p>
                  <p><strong>Time:</strong> {currentReservation.confirmed_time || currentReservation.reservation_time}</p>
                  <p><strong>Response:</strong> {currentReservation.restaurant_response}</p>
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
