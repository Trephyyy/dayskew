package scheduler

import (
	"sort"

	"dayskew-backend/internal/task"
)

// PlacedTask is a successfully scheduled task with its computed start/end.
type Placed struct {
	Task          task.Task `json:"task"`
	ComputedStart int       `json:"computedStart"`
	ComputedEnd   int       `json:"computedEnd"`
}

// Result is the output of a scheduling run.
type Result struct {
	Timeline  []Placed    `json:"timeline"`
	Conflicts []task.Task `json:"conflicts"`
}

// input is an internal task alongside its sensitivity bounds.
type input struct {
	Task task.Task
	// rigidStart is the earliest admissible start when start-sensitive.
	rigidStart int
	// rigidEnd is the latest admissible end when end-sensitive.
	rigidEnd int
}

// Schedule performs two-pass priority placement and returns a chronologically
// ordered timeline plus any unplaceable tasks.
func Schedule(tasks []task.Task, currentTime int) Result {
	ins := make(map[string]*input, len(tasks))
	for _, t := range tasks {
		in := &input{Task: t, rigidStart: t.PreferredStart}
		in.rigidEnd = t.RigidEnd()
		ins[t.ID.String()] = in
	}

	var skeleton []*input
	var high, medium, low []*input
	for _, in := range ins {
		switch {
		case in.Task.IsStartSensitive && in.Task.IsEndSensitive:
			skeleton = append(skeleton, in)
		case in.Task.Priority == 1:
			high = append(high, in)
		case in.Task.Priority == 2:
			medium = append(medium, in)
		default:
			low = append(low, in)
		}
	}

	byStart := func(a, b *input) bool {
		return a.Task.PreferredStart < b.Task.PreferredStart
	}
	sort.SliceStable(skeleton, func(i, j int) bool { return byStart(skeleton[i], skeleton[j]) })
	sort.SliceStable(high, func(i, j int) bool { return byStart(high[i], high[j]) })
	sort.SliceStable(medium, func(i, j int) bool { return byStart(medium[i], medium[j]) })
	sort.SliceStable(low, func(i, j int) bool { return byStart(low[i], low[j]) })

	var tl []Placed
	var conflicts []task.Task
	occupiedTimeline := make([]Placed, 0, len(tasks))

	place := func(in *input) bool {
		start := currentTime
		if in.Task.IsStartSensitive && start < in.rigidStart {
			start = in.rigidStart
		}

		gapStart, ok := findGap(occupiedTimeline, start, in.Task.Duration, in.Task.IsEndSensitive, in.rigidEnd)
		if !ok {
			conflicts = append(conflicts, in.Task)
			return false
		}
		p := Placed{Task: in.Task, ComputedStart: gapStart, ComputedEnd: gapStart + in.Task.Duration}
		occupiedTimeline = insertOccupied(occupiedTimeline, p)
		tl = append(tl, p)
		return true
	}

	// Tier 0: skeleton locked at PreferredStart.
	for _, in := range skeleton {
		p := Placed{Task: in.Task, ComputedStart: in.Task.PreferredStart, ComputedEnd: in.rigidEnd}
		occupiedTimeline = insertOccupied(occupiedTimeline, p)
		tl = append(tl, p)
	}
	// Tier 1: high priority.
	for _, in := range high {
		place(in)
	}
	// Tier 2: medium priority.
	for _, in := range medium {
		place(in)
	}
	// Tier 3: low priority.
	for _, in := range low {
		place(in)
	}

	sort.SliceStable(tl, func(i, j int) bool {
		return tl[i].ComputedStart < tl[j].ComputedStart
	})
	return Result{Timeline: tl, Conflicts: conflicts}
}

// findGap searches forward from start for a contiguous free slot of length.
// If endSensitive, the gap must end by rigidEnd. Returns the gap's start and
// whether one fits within the day.
func findGap(occupied []Placed, start, length int, endSensitive bool, rigidEnd int) (int, bool) {
	if endSensitive && start+length > rigidEnd {
		return 0, false
	}
	if start+length > task.MaxMinutes {
		return 0, false
	}
	pos := start
	for _, occ := range occupied {
		if occ.ComputedEnd <= pos {
			continue
		}
		if occ.ComputedStart >= pos+length {
			break // the next occupied block starts after our candidate slot ends
		}
		// Overlap: jump past this occupied block.
		pos = occ.ComputedEnd
		if pos+length > task.MaxMinutes {
			return 0, false
		}
		if endSensitive && pos+length > rigidEnd {
			return 0, false
		}
	}
	return pos, true
}

// insertOccupied returns occupied with p inserted, keeping ComputedStart order.
func insertOccupied(occupied []Placed, p Placed) []Placed {
	i := sort.Search(len(occupied), func(j int) bool { return occupied[j].ComputedStart > p.ComputedStart })
	occupied = append(occupied, Placed{})
	copy(occupied[i+1:], occupied[i:])
	occupied[i] = p
	return occupied
}
