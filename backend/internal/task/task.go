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
type Task struct {
	ID               uuid.UUID `db:"id"              json:"id"`
	Name             string    `db:"name"            json:"name"`
	Duration         int       `db:"duration"        json:"duration"`
	PreferredStart   int       `db:"preferred_start" json:"preferredStart"`
	IsStartSensitive bool      `db:"is_start_sensitive" json:"isStartSensitive"`
	IsEndSensitive   bool      `db:"is_end_sensitive" json:"isEndSensitive"`
	Priority         int       `db:"priority"        json:"priority"`
	CreatedAt        time.Time `db:"created_at"      json:"createdAt"`
	UpdatedAt        time.Time `db:"updated_at"      json:"updatedAt"`
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
	return nil
}

// RigidEnd is the latest minute at which an end-sensitive task may finish.
func (t Task) RigidEnd() int {
	return t.PreferredStart + t.Duration
}
