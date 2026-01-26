-- Create reservations table for storing restaurant booking requests
CREATE TABLE IF NOT EXISTS public.reservations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Restaurant info
  restaurant_phone TEXT NOT NULL,
  restaurant_name TEXT,
  
  -- Reservation details
  reservation_date DATE NOT NULL,
  reservation_time TIME NOT NULL,
  party_size INTEGER NOT NULL CHECK (party_size > 0),
  
  -- Customer info
  customer_name TEXT NOT NULL,
  customer_phone TEXT NOT NULL,
  customer_email TEXT,
  special_requests TEXT,
  
  -- Call/Agent status
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'calling', 'completed', 'failed')),
  call_id TEXT,  -- ElevenLabs/Twilio call ID
  
  -- Result from agent
  booking_confirmed BOOLEAN,
  confirmation_details JSONB,  -- Store any extra info from the call
  failure_reason TEXT,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  call_started_at TIMESTAMPTZ,
  call_ended_at TIMESTAMPTZ
);

-- Create index for common queries
CREATE INDEX IF NOT EXISTS idx_reservations_status ON public.reservations(status);
CREATE INDEX IF NOT EXISTS idx_reservations_call_id ON public.reservations(call_id);

-- Enable RLS (for now, allow all operations - you can tighten this later with user auth)
ALTER TABLE public.reservations ENABLE ROW LEVEL SECURITY;

-- Temporary permissive policy for development (tighten for production)
CREATE POLICY "Allow all operations for now" ON public.reservations
  FOR ALL USING (true) WITH CHECK (true);

-- Function to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update updated_at
DROP TRIGGER IF EXISTS update_reservations_updated_at ON public.reservations;
CREATE TRIGGER update_reservations_updated_at
  BEFORE UPDATE ON public.reservations
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
