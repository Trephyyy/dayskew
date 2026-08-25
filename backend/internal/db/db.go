package db

import (
	"dayskew-backend/internal/config"
	"github.com/jmoiron/sqlx"
	_ "github.com/lib/pq"
)

// Open creates a Postgres connection (via the lib/pq driver) from config.
func Open(cfg config.Config) (*sqlx.DB, error) {
	return sqlx.Connect("postgres", cfg.DbUrl)
}
