package db

import (
	"database/sql"
	"errors"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"dayskew-backend/internal/task"
)

// ErrNotFound is returned when a requested row does not exist.
var ErrNotFound = errors.New("not found")

// Store is a sqlx-backed repository for tasks.
type Store struct {
	db *sqlx.DB
}

// NewStore returns a Store bound to the given connection.
func NewStore(conn *sqlx.DB) *Store {
	if conn == nil {
		return nil
	}
	return &Store{db: conn}
}

// CreateTask inserts a new task and returns the stored record.
func (s *Store) CreateTask(t task.Task) (task.Task, error) {
	const q = `
INSERT INTO tasks (name, duration, preferred_start, is_start_sensitive, is_end_sensitive, priority)
VALUES (:name, :duration, :preferred_start, :is_start_sensitive, :is_end_sensitive, :priority)
RETURNING id, name, duration, preferred_start, is_start_sensitive, is_end_sensitive, priority, created_at, updated_at`

	rows, err := s.db.NamedQuery(q, t)
	if err != nil {
		return task.Task{}, err
	}
	defer rows.Close()

	var out task.Task
	if !rows.Next() {
		return task.Task{}, errors.New("create task returned no row")
	}
	if err := rows.StructScan(&out); err != nil {
		return task.Task{}, err
	}
	return out, nil
}

// GetTask fetches a single task by id.
func (s *Store) GetTask(id uuid.UUID) (task.Task, error) {
	const q = `
SELECT id, name, duration, preferred_start, is_start_sensitive, is_end_sensitive,
       priority, created_at, updated_at
FROM tasks WHERE id = $1`

	var t task.Task
	if err := s.db.Get(&t, q, id); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return task.Task{}, ErrNotFound
		}
		return task.Task{}, err
	}
	return t, nil
}

// ListTasks returns all tasks ordered by preferred start then priority.
func (s *Store) ListTasks() ([]task.Task, error) {
	const q = `
SELECT id, name, duration, preferred_start, is_start_sensitive, is_end_sensitive,
       priority, created_at, updated_at
FROM tasks ORDER BY preferred_start ASC, priority ASC, name ASC`

	tt := []task.Task{}
	if err := s.db.Select(&tt, q); err != nil {
		return nil, err
	}
	return tt, nil
}

// UpdateTask overwrites the mutable fields of an existing task.
func (s *Store) UpdateTask(t task.Task) (task.Task, error) {
	const q = `
UPDATE tasks SET
    name = :name,
    duration = :duration,
    preferred_start = :preferred_start,
    is_start_sensitive = :is_start_sensitive,
    is_end_sensitive = :is_end_sensitive,
    priority = :priority,
    updated_at = now()
WHERE id = :id
RETURNING id, name, duration, preferred_start, is_start_sensitive, is_end_sensitive,
          priority, created_at, updated_at`

	rows, err := s.db.NamedQuery(q, t)
	if err != nil {
		return task.Task{}, err
	}
	defer rows.Close()

	var out task.Task
	if !rows.Next() {
		return task.Task{}, ErrNotFound
	}
	if err := rows.StructScan(&out); err != nil {
		return task.Task{}, err
	}
	return out, nil
}

// DeleteTask removes a task by id.
func (s *Store) DeleteTask(id uuid.UUID) error {
	const q = `DELETE FROM tasks WHERE id = $1`
	res, err := s.db.Exec(q, id)
	if err != nil {
		return err
	}
	n, err := res.RowsAffected()
	if err != nil {
		return err
	}
	if n == 0 {
		return ErrNotFound
	}
	return nil
}
