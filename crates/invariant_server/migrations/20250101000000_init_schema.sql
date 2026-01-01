-- Identity Table
CREATE TABLE IF NOT EXISTS identities (
    id UUID PRIMARY KEY,
    public_key BYTEA NOT NULL,
    continuity_score BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_heartbeat TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status TEXT NOT NULL CHECK (status IN ('active', 'dormant', 'revoked'))
);

-- Heartbeat Log
CREATE TABLE IF NOT EXISTS heartbeats (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    identity_id UUID NOT NULL REFERENCES identities(id),
    device_signature BYTEA NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_heartbeats_identity ON heartbeats(identity_id);