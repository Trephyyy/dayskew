# dayskew monorepo build/test runner
# One-command entrypoint: `make all`

BACKEND := backend
GO     := go

.PHONY: all build test run migrate db-up db-down compose clean

all: build test

build:
	@cd backend && $(GO) build -o out/server ./cmd/server
	@cd backend && $(GO) build -o out/migrate ./cmd/migrate

test:
	@cd backend && $(GO) test ./...

run: build
	@backend/out/server

migrate: build
	@backend/out/migrate

db-up:
	@docker compose up -d postgres

db-down:
	@docker compose down

compose:
	@docker compose up

clean:
	rm -rf backend/out
	@docker compose down