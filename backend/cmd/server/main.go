package main

import (
	"log"
	"net/http"

	"dayskew-backend/internal/api"
	"dayskew-backend/internal/config"
	"dayskew-backend/internal/db"
)

func main() {
	cfg := config.Load()

	conn, err := db.Open(cfg)
	if err != nil {
		log.Println("warning: could not connect to postgres:", err)
	}

	store := db.NewStore(conn)

	handler := api.Router(store)
	log.Println("dayskew backend listening on 0.0.0.0:" + cfg.Port)
	http.ListenAndServe("0.0.0.0:"+cfg.Port, handler)
}
