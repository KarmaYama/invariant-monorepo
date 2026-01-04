-- crates/invariant_server/migrations/20250104000001_production_hardening.sql

-- 1. Add Username for Social Leaderboard
ALTER TABLE identities ADD COLUMN IF NOT EXISTS username TEXT UNIQUE;

-- 2. Add Hashed Hardware Column (Privacy)
ALTER TABLE identities ADD COLUMN IF NOT EXISTS hardware_device_hash TEXT;

-- 3. Add Genesis Eligibility Flag (Gamification)
ALTER TABLE identities ADD COLUMN IF NOT EXISTS is_genesis_eligible BOOLEAN DEFAULT TRUE;

-- 4. Idempotency Index (Safe Retries)
-- 🔒 SECURITY: This prevents "double-mining" if a bot sends 2 requests in the same millisecond.
-- We force UTC timezone to make the index IMMUTABLE and reliable.
CREATE UNIQUE INDEX IF NOT EXISTS ux_heartbeats_window 
ON heartbeats (identity_id, date_trunc('hour', timestamp AT TIME ZONE 'UTC'));

-- 5. Privacy: We can optionally drop the raw column later, but we keep it for now for debugging.
-- ALTER TABLE identities DROP COLUMN hardware_device;