-- crates/invariant_server/migrations/20250101000001_sybil_harden.sql
-- Force the DB to be the final arbiter of Sybil Resistance[cite: 365, 368].
ALTER TABLE identities ADD CONSTRAINT unique_public_key UNIQUE (public_key);

-- Add Heartbeat support for Dead Man's Switch[cite: 116, 273].
ALTER TABLE identities ADD COLUMN IF NOT EXISTS switch_active BOOLEAN DEFAULT FALSE;