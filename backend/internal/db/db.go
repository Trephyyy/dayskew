package db

import (
	"github.com/jmoiron/sqlx"
	"dayskew-backend/internal/config"
)

// Open creates a Postgres connection (via the lib/pq driver) from config.
func Open(cfg config.Config) (*sqlx.DB, error) {
	return sqlx.Connect("postgres", cfg.DbUrl)
}