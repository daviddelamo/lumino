CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE,
    password_hash TEXT,
    display_name TEXT,
    auth_provider TEXT NOT NULL DEFAULT 'email',
    locale TEXT NOT NULL DEFAULT 'en',
    timezone TEXT NOT NULL DEFAULT 'UTC',
    onboarding_profile JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    icon_id TEXT NOT NULL DEFAULT 'circle',
    color TEXT NOT NULL DEFAULT '#E8823A',
    start_at TIMESTAMPTZ NOT NULL,
    end_at TIMESTAMPTZ,
    repeat_rule JSONB,
    reminder_offset_min INT,
    notes TEXT,
    completed_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE habits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    icon_id TEXT NOT NULL DEFAULT 'circle',
    color TEXT NOT NULL DEFAULT '#E8823A',
    type TEXT NOT NULL CHECK (type IN ('bool', 'count', 'duration')),
    target_value NUMERIC NOT NULL DEFAULT 1,
    unit TEXT,
    frequency_rule JSONB NOT NULL,
    reminder_time TIME,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    archived_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE habit_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    habit_id UUID NOT NULL REFERENCES habits(id) ON DELETE CASCADE,
    entry_date DATE NOT NULL,
    value NUMERIC NOT NULL DEFAULT 1,
    note TEXT,
    logged_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (habit_id, entry_date)
);

CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash TEXT NOT NULL,
    device_id TEXT,
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_tasks_user_date ON tasks(user_id, start_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_habits_user ON habits(user_id) WHERE archived_at IS NULL;
CREATE INDEX idx_habit_entries_habit_date ON habit_entries(habit_id, entry_date);
CREATE INDEX idx_refresh_tokens_hash ON refresh_tokens(token_hash) WHERE revoked_at IS NULL;
