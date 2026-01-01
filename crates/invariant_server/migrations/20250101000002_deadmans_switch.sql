-- crates/invariant_server/migrations/20250101000002_deadmans_switch.sql

-- Adds Switch configuration to the Identity
ALTER TABLE identities 
ADD COLUMN IF NOT EXISTS switch_threshold_days INTEGER DEFAULT 365,
ADD COLUMN IF NOT EXISTS switch_beneficiary_id UUID REFERENCES identities(id),
ADD COLUMN IF NOT EXISTS switch_status TEXT NOT NULL DEFAULT 'inactive' 
    CHECK (switch_status IN ('inactive', 'armed', 'triggered'));

-- Index for the background worker to find dormant accounts
CREATE INDEX IF NOT EXISTS idx_identities_liveness 
ON identities(last_heartbeat) 
WHERE switch_status = 'armed';