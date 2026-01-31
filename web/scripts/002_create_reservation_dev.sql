-- Create reservation_dev table for development/testing
-- Uses conversation_id (ElevenLabs) instead of call_id

CREATE TABLE IF NOT EXISTS reservation_dev (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Restaurant info
  restaurant_name TEXT,
  restaurant_phone TEXT NOT NULL,
  
  -- Reservation details
  reservation_date DATE NOT NULL,
  reservation_time TIME NOT NULL,
  party_size INTEGER NOT NULL CHECK (party_size > 0),
  
  -- Customer info
  customer_name TEXT NOT NULL,
  customer_phone TEXT NOT NULL,
  customer_email TEXT,
  special_requests TEXT,
  
  -- Call/Conversation status
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'calling', 'completed', 'failed')),
  conversation_id TEXT,  -- ElevenLabs conversation ID
  
  -- Results from ElevenLabs
  booking_confirmed BOOLEAN,
  data_collection_results JSONB,  -- Stores analysis.data_collection_results from ElevenLabs
  confirmation_details JSONB,      -- Other call details (transcript, duration, etc.)
  failure_reason TEXT,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  call_started_at TIMESTAMPTZ,
  call_ended_at TIMESTAMPTZ
);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_reservation_dev_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS reservation_dev_updated_at ON reservation_dev;
CREATE TRIGGER reservation_dev_updated_at
  BEFORE UPDATE ON reservation_dev
  FOR EACH ROW
  EXECUTE FUNCTION update_reservation_dev_updated_at();

-- Disable RLS for development (enable in production)
ALTER TABLE reservation_dev DISABLE ROW LEVEL SECURITY;

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_reservation_dev_conversation_id ON reservation_dev(conversation_id);
CREATE INDEX IF NOT EXISTS idx_reservation_dev_status ON reservation_dev(status);
