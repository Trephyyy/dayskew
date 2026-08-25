package main

import (
	"log"
	"os"
	"path"
	"path/filepath"
	"strings"

	"dayskew-backend/internal/config"
	"dayskew-backend/internal/db"
)

func main() {
	cfg := config.Load()
	conn, err := db.Open(cfg)
	if err != nil {
		log.Fatalln("migrate: connection failed:", err)
	}

	// Resolve the migrations dir relative to the executable so it works
	// regardless of the current working directory.
	exe, err := os.Executable()
	if err != nil {
		log.Fatalln("migrate: cannot resolve executable path:", err)
	}
	dir := path.Join(filepath.Dir(exe), "..", "db", "migrations")
	entries, err := os.ReadDir(dir)
	if err != nil {
		log.Fatalln("migrate: cannot read migrations dir:", err)
	}

	applied := 0
	for _, entry := range entries {
		name := entry.Name()
		if !strings.HasSuffix(name, ".sql") {
			continue
		}
		file, err := os.ReadFile(path.Join(dir, name))
		if err != nil {
			log.Fatalln("migrate: cannot read", name, ":", err)
		}
		body := string(file)
		log.Println("applying", name)
		_, err = conn.Exec(body)
		if err != nil {
			log.Fatalln("migrate: failed on", name, ":", err)
		}
		applied += 1
	}

	log.Println("migrate: applied", applied, "migration(s)")
}
