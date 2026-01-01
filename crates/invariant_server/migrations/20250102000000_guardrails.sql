-- crates/invariant_server/migrations/20250102000000_guardrails.sql

-- Add columns for Operational Control
ALTER TABLE identities 
ADD COLUMN IF NOT EXISTS genesis_version SMALLINT NOT NULL DEFAULT 1,
ADD COLUMN IF NOT EXISTS network TEXT NOT NULL DEFAULT 'testnet';

-- Add a constraint to ensure valid network values
ALTER TABLE identities 
ADD CONSTRAINT check_network_enum 
CHECK (network IN ('testnet', 'mainnet', 'dev'));

-- Index for rapid filtering of testnet vs mainnet data
CREATE INDEX IF NOT EXISTS idx_identities_network ON identities(network);