package scheduler

import (
	"testing"

	"github.com/google/uuid"

	"dayskew-backend/internal/task"
)

func mkTask(name string, dur, start int, startS, endS bool, priority int) task.Task {
	return task.Task{
		ID:               uuid.New(),
		Name:             name,
		Duration:         dur,
		PreferredStart:   start,
		IsStartSensitive: startS,
		IsEndSensitive:   endS,
		Priority:         priority,
	}
}

func took(r Result) map[string]int {
	m := map[string]int{}
	for _, p := range r.Timeline {
		m[p.Task.Name] = p.ComputedStart
	}
	return m
}

func conflicts(r Result) map[string]bool {
	m := map[string]bool{}
	for _, t := range r.Conflicts {
		m[t.Name] = true
	}
	return m
}

func TestHighPriorityClaimsEarliestSlot(t *testing.T) {
	tasks := []task.Task{
		mkTask("low", 60, 480, false, false, 3),
		mkTask("high", 60, 480, false, false, 1),
	}
	r := Schedule(tasks, 0)
	st := took(r)
	if st["high"] != 0 {
		t.Fatalf("high should take earliest slot 0, got %d", st["high"])
	}
	if st["low"] != 60 {
		t.Fatalf("low should shift after high to 60, got %d", st["low"])
	}
}

func TestSkeletonIsLocked(t *testing.T) {
	skeleton := mkTask("skeleton", 120, 600, true, true, 3)
	other := mkTask("other", 60, 600, false, false, 1)
	r := Schedule([]task.Task{skeleton, other}, 480)
	st := took(r)
	if st["skeleton"] != 600 {
		t.Fatalf("skeleton not locked at 600: %v", st)
	}
	if st["other"] != 480 {
		t.Fatalf("other should pack into free gap before skeleton at 480: %v", st)
	}
}

func TestEndSensitiveRespectsRigidEnd(t *testing.T) {
	blocker := mkTask("blocker", 300, 1, false, false, 1)
	endTask := mkTask("endtask", 60, 600, false, true, 2)
	r := Schedule([]task.Task{blocker, endTask}, 0)
	for _, p := range r.Timeline {
		if p.Task.Name == "endtask" {
			if p.ComputedEnd > 660 {
				t.Fatalf("endtask exceeded rigid end: %d", p.ComputedEnd)
			}
			return
		}
	}
	t.Fatalf("endtask not placed: %+v", r)
}

func TestEndSensitiveUnplaceable(t *testing.T) {
	blocker := mkTask("blocker", 300, 50, false, false, 1)
	endTask := mkTask("endtask", 60, 200, false, true, 3) // rigidEnd = 260
	r := Schedule([]task.Task{blocker, endTask}, 0)
	if !conflicts(r)["endtask"] {
		t.Fatalf("endtask should be a conflict: %+v", r)
	}
}

func TestStartSensitiveClampsToPreferred(t *testing.T) {
	tCase := []struct {
		current int
		want    int
	}{
		{current: 480, want: 500}, // within day, pref wins
		{current: 600, want: 600}, // current time wins
	}
	for _, c := range tCase {
		r := Schedule([]task.Task{mkTask("t", 60, 500, true, false, 1)}, c.current)
		if st := took(r)["t"]; st != c.want {
			t.Fatalf("current=%d: start-sensitive want %d got %d", c.current, c.want, st)
		}
	}
}

func TestUnplaceableBeyondEndOfDay(t *testing.T) {
	r := Schedule([]task.Task{mkTask("late", 60, 480, false, false, 1)}, 1390)
	if len(r.Timeline) != 0 {
		t.Fatalf("expected no placement, got %+v", r.Timeline)
	}
	if !conflicts(r)["late"] {
		t.Fatalf("late should be a conflict: %+v", r)
	}
}

func TestTimelineChronological(t *testing.T) {
	r := Schedule([]task.Task{
		mkTask("high", 60, 300, false, false, 1),
		mkTask("med", 60, 200, false, false, 2),
	}, 0)
	for i := 1; i < len(r.Timeline); i++ {
		if r.Timeline[i].ComputedStart < r.Timeline[i-1].ComputedStart {
			t.Fatalf("timeline not chronological: %+v", r.Timeline)
		}
	}
}
