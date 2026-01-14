-- Add FCM Token for Server-Driven Wake Up
ALTER TABLE identities ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- Create index to quickly find nodes that need waking up
-- This is used by the Reaper to find "late" nodes efficiently
CREATE INDEX IF NOT EXISTS idx_identities_fcm_token ON identities(fcm_token) 
WHERE status = 'active';