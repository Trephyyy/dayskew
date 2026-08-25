# dayskew

Monorepo for the dayskew platform.

## Layout

- `backend/` — Go REST API (`cmd/`, `internal/`, sqlx migrations in `db/`)
- `webapp/` — web frontend (empty)
- `mobile/` — mobile app (empty)
- `shared/` — OpenAPI / JSON shared types and contracts

## Quick start

```sh
make db-up   # start Postgres locally (docker compose up -d postgres)
make build   # compile backend binaries
make test    # run Go tests
make migrate # apply db/migrations/*.sql
make run     # start the API on :8080
```

`make compose` boots the full stack (Postgres + API) in Docker.

## Environment

Backend config is read from env vars (see `internal/config`), with local
defaults matching `docker-compose.yml`:

- `DATABASE_URL`
- `PORT` (default 8080)
- `APP_ENV`