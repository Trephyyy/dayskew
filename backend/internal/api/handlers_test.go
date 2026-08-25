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
