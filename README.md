# dayskew

A dynamic, relative-time daily scheduler. Instead of locking your day to a
fixed wake-up time, DaySkew treats every task as a constraint and recomputes
your whole day from the moment you actually get up — no conflicted or silently
dropped tasks.

## What it does

- **Plan once, reflow every day.** Give each task a duration, a preferred time,
  a priority (High / Medium / Low) and sensitivity bounds (start/end locked).
  Recurring tasks apply to every day; you can also plan a specific future day.
- **Just Woke Up.** Tap the button when you actually wake up (or set the time
  manually) and DaySkew lays out the day forward from that moment, packing
  high-priority tasks into the best slots first.
- **No silent drops.** Anything that can't fit is listed in the **Bump Zone**
  for you to reschedule, move, or drop by hand.
- **Save to Google Calendar.** Push the computed day into a dedicated
  "DaySkew" calendar in your Google account.

**App:** Android (iOS / desktop / web build), neo-brutal + retro-arcade UI.

## Repo layout

- `mobile/` — Flutter app
- `backend/` — Go REST API (`cmd/`, `internal/`, sqlx migrations in `db/`)
- `webapp/` — web frontend (empty)
- `shared/` — OpenAPI / JSON shared types and contracts

## Quick start

```sh
make db-up   # start Postgres locally (docker compose up -d postgres)
make build   # compile backend binaries
make test    # run Go tests
make migrate # apply db/migrations/*.sql
make run     # start the API on :8080
```

`make compose` boots the full stack (Postgres + API) in Docker. Android APKs
are published to [Releases](https://github.com/Trephyyy/dayskew/releases).

## Environment

Backend config is read from env vars (see `internal/config`), with local
defaults matching `docker-compose.yml`:

- `DATABASE_URL`
- `PORT` (default 8080)
- `APP_ENV`