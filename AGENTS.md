Constraint-Based SchedulerOne LinerA dynamic, relative-time daily task scheduler that uses a priority-tiered, constraint-based bin-packing algorithm to automatically reflow a day's schedule around fixed events based on the user's actual wake-up time.Problem to SolveTime-blocked daily routines rely on absolute timestamps anchored to an assumed wake-up time. When a delay occurs, this rigid structure fails, creating a cascade of scheduling conflicts. Existing tools natively understand absolute time, not relative time, and attempt to fix delays by unpredictably reordering tasks via opaque AI weighting. This system solves the anchor failure by treating tasks as independent objects with bounding constraints and computing a fresh timeline strictly based on the current actual time, preserving the intended sequence without silent drops.MVPA headless, compute-first scheduling engine with decoupled frontends. The user inputs their daily tasks with preferred times, durations, priority levels, and sensitivity bounds. Upon supplying an actual start-of-day time, the system computes the schedule on the fly. It outputs two distinct sets of data: a placed timeline of chronological tasks, and a conflict list of unplaceable tasks for manual user resolution (e.g., dropping or rescheduling low-priority items). V1 excludes recurring templates, automated calendar syncing, and background notifications.Spec Sheet1. Architecture & StackBackend Engine: Go (Golang). Must be designed as a RESTful JSON API to serve independent clients.Database: PostgreSQL.Database Access: Use the sqlx library for clean, performant struct mapping and queries (no heavy ORMs like GORM).Clients: The API must support both a Web App and a Mobile App interface. Endpoints should be stateless and handle standardized JSON payloads.2. Data ModelTimes must be normalized as integers representing "minutes since midnight" (0–1439) to avoid timezone/date-boundary complexity during computation.Task Entity:ID (UUID)Name (String)Duration (Integer, minutes)PreferredStart (Integer, minutes since midnight)IsStartSensitive (Boolean) - Cannot begin before PreferredStart.IsEndSensitive (Boolean) - Cannot end after PreferredStart + Duration.Priority (Integer: 1 = High, 2 = Medium, 3 = Low)(Note: A task where both sensitivity flags are true is considered a "Locked" event, forming the unmovable skeleton of the day).3. Core Algorithm: Two-Pass Priority PlacementThe algorithm computes a fresh schedule from a given CurrentTime integer.Pass 1: Strict Priority Placement (The Greedy Pass)Tasks are evaluated and placed into an occupied timeline list in strict tier order to ensure high-priority items claim optimal slots first.Tier 0 (Skeleton): Filter all tasks where IsStartSensitive AND IsEndSensitive are true. Place them exactly at PreferredStart.Tier 1 (High): Filter Priority 1 tasks. Sort by PreferredStart ascending.Tier 2 (Medium): Filter Priority 2 tasks. Sort by PreferredStart ascending.Tier 3 (Low): Filter Priority 3 tasks. Sort by PreferredStart ascending.Placement Logic (per task during Pass 1):Determine the earliest possible start time: max(CurrentTime, PreferredStart) if IsStartSensitive is true, otherwise just CurrentTime.Search forward along the timeline for a contiguous free gap $\ge$ Duration.If IsEndSensitive is true, the gap must conclude before or exactly at the task's rigid end time.If a valid gap is found, lock the task into the occupied list.If no valid gap exists, flag the task as Unplaceable. Do NOT search backward into occupied slots.Pass 2: Conflict GenerationCollect all unplaceable tasks.Format them into a distinct Conflicts array in the API response.The clients will use this array to prompt the user to take manual action (e.g., "Reschedule [Task Name] (Low Priority) to another day").4. Expected API OutputThe computation endpoint must return a structured payload containing:Timeline: An ordered array of successfully placed tasks, each with absolute ComputedStart and ComputedEnd integers.Conflicts: An array of tasks that failed the placement constraints, including their original parameters so the client can present resolution options.

# Design
**Visual Philosophy**
Combining Hack Club’s high-energy, tactile neo-brutalism with Stardance’s playful retro-arcade aesthetic turns schedule recomputation from a chore into an interactive system. Instead of corporate grid lines, DaySkew uses thick rounded borders, sticker-like badge indicators, high-contrast container cards, and crisp monospaced time metrics.

---

**Color System & Token Hierarchy**

| Token Role | Hex / Style | Purpose |
| --- | --- | --- |
| **Canvas Background** | `#0f1117` (Dark) / `#f9fafb` (Light) | High-contrast neutral backdrop |
| **Card Surface** | `#171a23` with `2px solid #2e3444` | Elevated tactile task blocks |
| **Locked Event (Tier 0)** | `#000000` base with `#ffffff` border | Rigid structural anchor |
| **High Priority (Tier 1)** | `#ec3750` (Hack Club Crimson) | Critical path tasks |
| **Medium Priority (Tier 2)** | `#ff8c37` (Electric Amber) | Standard daily commitments |
| **Low Priority (Tier 3)** | `#33d6a6` (Cyber Mint) | Admin / easily pushed items |
| **Conflict Warning** | `#f5a623` (Arcade Gold) | Highlights unplaceable tasks |

---

**Typography Stack**

* **Headings & Task Names:** *Plus Jakarta Sans* or *Outfit* (Bold, 800-weight, rounded geometric terminals).
* **Time & Technical Metrics:** *JetBrains Mono* or *Fira Code* (Strict monospace for integer timestamps like `09:15`, duration chips `+45m`, and algorithm flags).

---

**Core UI Components**

* **The Reflow Hero Header:** A prominent, tactile wake-up trigger anchored at the top of the screen.
* *Control:* A large, chunky time picker (e.g., `09:45 AM`) paired with a high-contrast action button labeled **REFLOW DAY**.
* *Style:* Soft spring animations on press, 3D offset shadow (`4px 4px 0px #000`), rounded pill shape (`9999px`).


* **Timeline Task Cards:**
* *Structure:* Floating rounded rectangles (`border-radius: 16px`, `border: 2px solid`).
* *Sensitivity Badges:* Sticker-style pill tags in the top corner indicating constraints (e.g., `[START ≥ 08:30]` or `[LOCKED]`).
* *Drift Indicator:* A subtle inline delta badge showing offset from the original preferred time (e.g., `+1h 15m shift`).


* **The Conflict Drawer ("The Bump Zone"):**
* Appears directly below or floating alongside the timeline when Pass 2 produces unplaceable tasks.
* *Card Design:* Dotted border styling with a prominent warning icon.
* *Actions:* Quick-action arcade buttons on the card: **[Tomorrow]**, **[Drop]**, or **[Override Time]**.



---

**Micro-Interactions & Motion**

* **Physics-Based Reflow:** When clicking **REFLOW DAY**, tasks do not hard-cut to new positions. Use spring physics (e.g., Framer Motion / CSS transitions) so tasks physically slide down the timeline into their newly computed slots.
* **Haptic / Tactile Feedback:** Chunky `active:translate-y-1` button presses that mimic physical switches.
* **Conflict Ejection:** Unplaceable tasks pop out of the main schedule flow with a slight bounce into the Conflict Drawer, making constraint collisions explicitly visible.
