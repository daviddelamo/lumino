ALTER TABLE users ADD COLUMN IF NOT EXISTS facebook_id TEXT UNIQUE;
CREATE INDEX IF NOT EXISTS idx_users_facebook_id ON users(facebook_id) WHERE facebook_id IS NOT NULL;
