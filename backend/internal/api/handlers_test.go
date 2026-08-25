package api

import (
	"bytes"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/google/uuid"
)

func TestHealth(t *testing.T) {
	h := Router(nil)
	req := httptest.NewRequest(http.MethodGet, "/health", nil)
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	if rec.Code != http.StatusOK || rec.Body.String() != "ok" {
		t.Fatalf("health: got %d %q", rec.Code, rec.Body.String())
	}
}

func TestScheduleMethodNotAllowed(t *testing.T) {
	h := Router(nil)
	req := httptest.NewRequest(http.MethodGet, "/schedule", nil)
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	if rec.Code != http.StatusMethodNotAllowed {
		t.Fatalf("expected 405, got %d", rec.Code)
	}
}

func TestScheduleRejectsBadCurrentTime(t *testing.T) {
	// Nil store is fine here: validation happens before storage access.
	h := Router(nil)
	body := `{"currentTime":9999}`
	req := httptest.NewRequest(http.MethodPost, "/schedule", bytes.NewBufferString(body))
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected 400, got %d %s", rec.Code, rec.Body.String())
	}
}

func TestTasksBadJSON(t *testing.T) {
	h := Router(nil)
	req := httptest.NewRequest(http.MethodPost, "/tasks", bytes.NewBufferString(`{bad`))
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected 400, got %d", rec.Code)
	}
}

func TestPathID(t *testing.T) {
	id := uuid.New()
	req := httptest.NewRequest(http.MethodGet, "/tasks/"+id.String(), nil)
	if got, ok := pathID(req); !ok || got != id {
		t.Fatalf("pathID: got %v ok=%v want %v", got, ok, id)
	}
	bad := httptest.NewRequest(http.MethodGet, "/tasks/not-a-uuid", nil)
	if _, ok := pathID(bad); ok {
		t.Fatal("pathID should reject bad uuid")
	}
}

func TestListTasksRejectsBadDate(t *testing.T) {
	h := Router(nil)
	req := httptest.NewRequest(http.MethodGet, "/tasks?date=not-a-date", nil)
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected 400 for bad date, got %d %s", rec.Code, rec.Body.String())
	}
}

func TestScheduleRejectsBadDate(t *testing.T) {
	h := Router(nil)
	body := `{"currentTime":480,"date":"nope"}`
	req := httptest.NewRequest(http.MethodPost, "/schedule", bytes.NewBufferString(body))
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected 400 for bad schedule date, got %d %s", rec.Code, rec.Body.String())
	}
}

func TestTaskInputToTask(t *testing.T) {
	in := taskInput{
		Name:           "Launch",
		Duration:       30,
		PreferredStart: 600,
		Priority:       1,
		ScheduledDate:  strPtr("2026-08-26"),
		Timezone:       "Europe/Sofia",
	}
	tk, err := in.toTask()
	if err != nil {
		t.Fatalf("toTask: %v", err)
	}
	if tk.ScheduledDate == nil || tk.ScheduledDate.UTC().Format("2006-01-02") != "2026-08-26" {
		t.Fatalf("toTask scheduledDate: %v", tk.ScheduledDate)
	}
	if tk.Timezone != "Europe/Sofia" {
		t.Fatalf("toTask timezone: %q", tk.Timezone)
	}
}

func TestTaskInputDefaultsTimezone(t *testing.T) {
	in := taskInput{Name: "x", Duration: 30, PreferredStart: 600, Priority: 2}
	tk, err := in.toTask()
	if err != nil {
		t.Fatalf("toTask: %v", err)
	}
	if tk.Timezone != "UTC" {
		t.Fatalf("expected default UTC timezone, got %q", tk.Timezone)
	}
	if tk.ScheduledDate != nil {
		t.Fatal("expected nil scheduledDate for recurring task")
	}
}

func TestTaskInputRejectsBadScheduledDate(t *testing.T) {
	in := taskInput{Name: "x", Duration: 30, PreferredStart: 600, Priority: 2, ScheduledDate: strPtr("01-02-2026")}
	if _, err := in.toTask(); err == nil {
		t.Fatal("expected error for bad scheduledDate format")
	}
}

func strPtr(s string) *string { return &s }
