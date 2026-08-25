-- 0003_add_task_dates.sql
-- Date-scoped tasks + calendar-sync groundwork.
--
-- scheduled_date   DATE     NULL = recurring/daily task; otherwise the
--                           specific day (YYYY-MM-DD) the task runs.
-- timezone         TEXT     IANA name used when exporting to Google Calendar
--                           (interprets "minutes since midnight").
-- google_event_id  TEXT     Back-reference to the synced Google Calendar
--                           event once calendar sync is wired up.

ALTER TABLE tasks ADD COLUMN IF NOT EXISTS scheduled_date DATE;
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS timezone TEXT NOT NULL DEFAULT 'UTC';
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS google_event_id TEXT;

CREATE INDEX IF NOT EXISTS idx_tasks_scheduled_date ON tasks (scheduled_date);
