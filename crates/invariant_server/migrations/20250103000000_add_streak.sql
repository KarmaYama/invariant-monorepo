-- Add streak tracking column
ALTER TABLE identities 
ADD COLUMN IF NOT EXISTS streak BIGINT NOT NULL DEFAULT 0;