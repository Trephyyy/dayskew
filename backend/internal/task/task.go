package task

import (
	"errors"
	"time"

	"github.com/google/uuid"
)

// MaxMinutes is the number of minutes in a day (exclusive upper bound).
const MaxMinutes = 1440

// Task is a single schedulable unit. All times are "minutes since midnight"
// (0-1439). A task with both sensitivity flags set is a "Locked" event that
// anchors the day's skeleton.
//
// ScheduledDate is the calendar day the task runs on ("YYYY-MM-DD" in JSON).
// A nil ScheduledDate is a recurring daily task that applies to every day.
// Timezone (IANA name) interprets the minute-of-day values when syncing to
// external calendars such as Google Calendar.
type Task struct {
	ID               uuid.UUID `db:"id"              json:"id"`
	Name             string    `db:"name"            json:"name"`
	Duration         int       `db:"duration"        json:"duration"`
	PreferredStart   int       `db:"preferred_start" json:"preferredStart"`
	IsStartSensitive bool      `db:"is_start_sensitive" json:"isStartSensitive"`
	IsEndSensitive   bool      `db:"is_end_sensitive" json:"isEndSensitive"`
	Priority         int       `db:"priority"        json:"priority"`
	ScheduledDate    *time.Time `db:"scheduled_date" json:"scheduledDate"`
	Timezone         string    `db:"timezone"        json:"timezone"`
	GoogleEventID    *string   `db:"google_event_id" json:"googleEventId"`
	CreatedAt        time.Time `db:"created_at"      json:"createdAt"`
	UpdatedAt        time.Time `db:"updated_at"      json:"updatedAt"`
}

// dateLayout is the canonical calendar-date representation used by the API
// and Google Calendar's date fields.
const dateLayout = "2006-01-02"

// ParseDate parses a "YYYY-MM-DD" string into a time at midnight UTC.
func ParseDate(s string) (*time.Time, error) {
	t, err := time.Parse(dateLayout, s)
	if err != nil {
		return nil, err
	}
	return &t, nil
}

// ParseDateLike parses a scheduledDate payload, accepting either the calendar
// "YYYY-MM-DD" form or a full RFC3339 timestamp.
func ParseDateLike(s string) (*time.Time, error) {
	if t, err := time.Parse(dateLayout, s); err == nil {
		return &t, nil
	}
	t, err := time.Parse(time.RFC3339, s)
	if err != nil {
		return nil, errors.New("scheduledDate must be YYYY-MM-DD or an RFC3339 timestamp")
	}
	return &t, nil
}

// Valid checks a task's constraints and returns a descriptive error if invalid.
func (t Task) Valid() error {
	if t.Name == "" {
		return errors.New("task name is required")
	}
	if t.Duration <= 0 {
		return errors.New("duration must be a positive integer")
	}
	if t.PreferredStart < 0 || t.PreferredStart >= MaxMinutes {
		return errors.New("preferredStart must be between 0 and 1439")
	}
	if t.PreferredStart+t.Duration > MaxMinutes {
		return errors.New("task ends after 23:59 (end of day)")
	}
	if t.Priority < 1 || t.Priority > 3 {
		return errors.New("priority must be 1 (high), 2 (medium), or 3 (low)")
	}
	if t.Timezone != "" {
		if _, err := time.LoadLocation(t.Timezone); err != nil {
			return errors.New("timezone must be a valid IANA name (e.g. UTC, Europe/Sofia)")
		}
	}
	return nil
}

// RigidEnd is the latest minute at which an end-sensitive task may finish.
func (t Task) RigidEnd() int {
	return t.PreferredStart + t.Duration
}
