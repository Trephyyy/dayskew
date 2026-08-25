# dayskew monorepo build/test runner
# One-command entrypoint: `make all`

BACKEND := backend
GO     := go

.PHONY: all build test run migrate db-up db-down compose clean

all: build test

build:
	@$(GO) build -o backend/out/server backend/cmd/server
	@$(GO) build -o backend/out/migrate backend/cmd/migrate

test:
	@$(GO) test ./backend

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