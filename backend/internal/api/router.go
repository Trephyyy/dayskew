package api

import (
	"net/http"
)

// Router wires up HTTP handlers. It returns a single handler mounted at the
// root, dispatching on request path.
func Router() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("/health", handleHealth)
	return mux
}

func handleHealth(w http.ResponseWriter, r *http.Request) {
	w.Write([]byte("ok"))
}