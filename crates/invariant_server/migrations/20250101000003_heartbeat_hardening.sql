-- crates/invariant_server/migrations/20250101000003_heartbeat_hardening.sql

-- Prevent duplicate heartbeat records for the same identity and timestamp.
CREATE UNIQUE INDEX IF NOT EXISTS ux_heartbeats_identity_timestamp
ON heartbeats (identity_id, timestamp);

-- Optional: Add optimistic concurrency control column
-- ALTER TABLE identities ADD COLUMN IF NOT EXISTS version BIGINT DEFAULT 0;
-- Note: If you use version, you'd increment it in UPDATE ... RETURNING version too.
