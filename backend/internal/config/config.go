package config

import "os"

// Config holds runtime settings loaded from the environment.
type Config struct {
	DbUrl string
	Port  string
	Env   string
}

func envOr(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

// Load reads configuration from environment variables, falling back to
// sensible local defaults that match docker-compose.yml.
func Load() Config {
	return Config{
		DbUrl: envOr("DATABASE_URL", "postgres://dayskew:dayskew@localhost:5432/dayskew"),
		Port:  envOr("PORT", "8080"),
		Env:   envOr("APP_ENV", "development"),
	}
}