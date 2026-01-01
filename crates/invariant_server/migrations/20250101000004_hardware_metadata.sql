-- crates/invariant_server/migrations/20250101000004_hardware_metadata.sql
-- Adds hardware metadata columns to the identities table
ALTER TABLE identities
ADD COLUMN IF NOT EXISTS hardware_brand TEXT,
ADD COLUMN IF NOT EXISTS hardware_device TEXT,
ADD COLUMN IF NOT EXISTS hardware_product TEXT;

-- Create an index on 'hardware_device' to allow rapid lookup of compromised fleets
-- (e.g., "Select all from device 'Pixel 3'").
CREATE INDEX IF NOT EXISTS idx_identities_hardware_device 
ON identities(hardware_device);