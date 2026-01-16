-- crates/invariant_server/migrations/20260116000000_add_last_attestation.sql
-- Add last_attestation column to track Trust Decay
ALTER TABLE identities 
ADD COLUMN IF NOT EXISTS last_attestation TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- Add an index for the reaper/audit performance
CREATE INDEX IF NOT EXISTS idx_identities_attestation ON identities(last_attestation);

-- Backfill existing records to prevent immediate decay on deploy
UPDATE identities SET last_attestation = created_at WHERE last_attestation IS NULL;