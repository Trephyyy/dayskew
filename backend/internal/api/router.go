package api

import (
	"net/http"

	"dayskew-backend/internal/db"
)

// Router wires up HTTP handlers against a task store. It returns a single
// handler mounted at the root, dispatching on request method and path.
func Router(store *db.Store) http.Handler {
	h := &handlers{store: store}
	mux := http.NewServeMux()

	mux.HandleFunc("/health", handleHealth)

	mux.HandleFunc("/tasks", func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			h.handleListTasks(w, r)
		case http.MethodPost:
			h.handleCreateTask(w, r)
		default:
			writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		}
	})
	mux.HandleFunc("/tasks/", func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			h.handleGetTask(w, r)
		case http.MethodPut:
			h.handleUpdateTask(w, r)
		case http.MethodDelete:
			h.handleDeleteTask(w, r)
		default:
			writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		}
	})

	mux.HandleFunc("/schedule", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			writeError(w, http.StatusMethodNotAllowed, "method not allowed")
			return
		}
		h.handleSchedule(w, r)
	})

	return mux
}

func handleHealth(w http.ResponseWriter, r *http.Request) {
	w.Write([]byte("ok"))
}
