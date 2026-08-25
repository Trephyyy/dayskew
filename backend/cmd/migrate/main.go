package main

import (
	"log"
	"os"
	"path"
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

	dir := path.Join("..", "..", "db", "migrations")
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