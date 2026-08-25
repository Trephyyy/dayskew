package api

import (
	"encoding/json"
	"errors"
	"net/http"
	"strings"

	"github.com/google/uuid"

	"dayskew-backend/internal/db"
	"dayskew-backend/internal/scheduler"
	"dayskew-backend/internal/task"
)

// handlers holds HTTP dependencies (the task store).
type handlers struct {
	store *db.Store
}

// scheduleRequest is the payload for POST /schedule. date is optional: when
// present it schedules only that calendar day's tasks (YYYY-MM-DD); when
// absent it schedules every task as a recurring day.
type scheduleRequest struct {
	CurrentTime int     `json:"currentTime"`
	Date        *string `json:"date"`
}

// taskInput is the create/update payload. scheduledDate is a calendar day
// ("YYYY-MM-DD") or RFC3339 timestamp; null/empty means a recurring daily task.
type taskInput struct {
	Name             string  `json:"name"`
	Duration         int     `json:"duration"`
	PreferredStart   int     `json:"preferredStart"`
	IsStartSensitive bool    `json:"isStartSensitive"`
	IsEndSensitive   bool    `json:"isEndSensitive"`
	Priority         int     `json:"priority"`
	ScheduledDate    *string `json:"scheduledDate"`
	Timezone         string  `json:"timezone"`
	GoogleEventID    *string `json:"googleEventId"`
}

// toTask converts a create/update payload into a persistable Task, normalizing
// the timezone (defaults to UTC) and parsing the optional date.
func (in taskInput) toTask() (task.Task, error) {
	t := task.Task{
		Name:             in.Name,
		Duration:         in.Duration,
		PreferredStart:   in.PreferredStart,
		IsStartSensitive: in.IsStartSensitive,
		IsEndSensitive:   in.IsEndSensitive,
		Priority:         in.Priority,
		Timezone:         "UTC",
	}
	if in.Timezone != "" {
		t.Timezone = in.Timezone
	}
	if in.ScheduledDate != nil && *in.ScheduledDate != "" {
		d, err := task.ParseDateLike(*in.ScheduledDate)
		if err != nil {
			return task.Task{}, err
		}
		t.ScheduledDate = d
	}
	if in.GoogleEventID != nil && *in.GoogleEventID != "" {
		v := *in.GoogleEventID
		t.GoogleEventID = &v
	}
	return t, nil
}

func (h *handlers) handleListTasks(w http.ResponseWriter, r *http.Request) {
	date := r.URL.Query().Get("date")
	var (
		tt  []task.Task
		err error
	)
	if date != "" {
		if _, perr := task.ParseDate(date); perr != nil {
			writeError(w, http.StatusBadRequest, "date must be a YYYY-MM-DD calendar day")
			return
		}
		tt, err = h.store.ListTasksForDate(date)
	} else {
		tt, err = h.store.ListTasks()
	}
	if err != nil {
		writeError(w, http.StatusInternalServerError, err.Error())
		return
	}
	if tt == nil {
		tt = []task.Task{}
	}
	writeJSON(w, http.StatusOK, tt)
}

func (h *handlers) handleGetTask(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(r)
	if !ok {
		writeError(w, http.StatusBadRequest, "invalid task id")
		return
	}
	t, err := h.store.GetTask(id)
	if err != nil {
		writeDBError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, t)
}

func (h *handlers) handleCreateTask(w http.ResponseWriter, r *http.Request) {
	var in taskInput
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
		writeError(w, http.StatusBadRequest, "invalid JSON body")
		return
	}
	t, err := in.toTask()
	if err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	if err := t.Valid(); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	stored, err := h.store.CreateTask(t)
	if err != nil {
		writeError(w, http.StatusInternalServerError, err.Error())
		return
	}
	writeJSON(w, http.StatusCreated, stored)
}

func (h *handlers) handleUpdateTask(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(r)
	if !ok {
		writeError(w, http.StatusBadRequest, "invalid task id")
		return
	}
	var in taskInput
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
		writeError(w, http.StatusBadRequest, "invalid JSON body")
		return
	}
	t, err := in.toTask()
	if err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	t.ID = id
	if err := t.Valid(); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	stored, err := h.store.UpdateTask(t)
	if err != nil {
		writeDBError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, stored)
}

func (h *handlers) handleDeleteTask(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(r)
	if !ok {
		writeError(w, http.StatusBadRequest, "invalid task id")
		return
	}
	if err := h.store.DeleteTask(id); err != nil {
		writeDBError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *handlers) handleSchedule(w http.ResponseWriter, r *http.Request) {
	var req scheduleRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid JSON body")
		return
	}
	if req.CurrentTime < 0 || req.CurrentTime >= task.MaxMinutes {
		writeError(w, http.StatusBadRequest, "currentTime must be between 0 and 1439")
		return
	}
	var (
		tt  []task.Task
		err error
	)
	if req.Date != nil && *req.Date != "" {
		if _, perr := task.ParseDate(*req.Date); perr != nil {
			writeError(w, http.StatusBadRequest, "date must be a YYYY-MM-DD calendar day")
			return
		}
		tt, err = h.store.ListTasksForDate(*req.Date)
	} else {
		tt, err = h.store.ListTasks()
	}
	if err != nil {
		writeError(w, http.StatusInternalServerError, err.Error())
		return
	}
	res := scheduler.Schedule(tt, req.CurrentTime)
	writeJSON(w, http.StatusOK, res)
}

// pathID extracts the :id segment from paths like /tasks/{id}.
func pathID(r *http.Request) (uuid.UUID, bool) {
	parts := strings.Split(strings.Trim(r.URL.Path, "/"), "/")
	if len(parts) != 2 {
		return uuid.Nil, false
	}
	id, err := uuid.Parse(parts[1])
	if err != nil {
		return uuid.Nil, false
	}
	return id, true
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}

func writeError(w http.ResponseWriter, status int, msg string) {
	writeJSON(w, status, map[string]string{"error": msg})
}

func writeDBError(w http.ResponseWriter, err error) {
	if errors.Is(err, db.ErrNotFound) {
		writeError(w, http.StatusNotFound, "task not found")
		return
	}
	writeError(w, http.StatusInternalServerError, err.Error())
}
