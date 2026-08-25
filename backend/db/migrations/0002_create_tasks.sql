-- 0002_create_tasks.sql
-- Tasks scheduled by the dayskew engine.
-- Times are integers representing "minutes since midnight" (0-1439).

CREATE TABLE IF NOT EXISTS tasks (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name               TEXT        NOT NULL DEFAULT '',
    duration           INTEGER     NOT NULL CHECK (duration > 0),
    preferred_start    INTEGER     NOT NULL CHECK (preferred_start >= 0 AND preferred_start <= 1439),
    is_start_sensitive BOOLEAN     NOT NULL DEFAULT FALSE,
    is_end_sensitive   BOOLEAN     NOT NULL DEFAULT FALSE,
    priority           INTEGER     NOT NULL CHECK (priority BETWEEN 1 AND 3),
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_tasks_preferred_start ON tasks (preferred_start);