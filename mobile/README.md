# DaySkew Mobile (Flutter)

The Flutter client for the DaySkew scheduler — a headless constraint-based
reflow engine. Renders the computed timeline, the wake-up "REFLOW DAY" hero,
and the Pass 2 conflict Bump Zone per the AGENTS.md design system
(neo-brutalism + retro arcade).

## Features

- **Reflow hero** — pick your actual wake-up time and hit REFLOW DAY.
- **Timeline** — placed tasks as tier-colored cards with sensitivity badges,
  mono time chips, and drift indicators.
- **Bump Zone** — unplaceable tasks with manual-resolution actions:
  Tomorrow (dismiss), Drop (delete), Override Time (edit).
- **Task management** — create/edit/drop tasks across all CRUD endpoints.

## Install

Public Android builds are published as GitHub Releases:
[github.com/Trephyyy/dayskew/releases](https://github.com/Trephyyy/dayskew/releases).
On a version tag push (`v*`), a workflow builds the APK and attaches
`DaySkew-<tag>.apk` automatically.

## Run

```sh
flutter pub get
flutter run
```

The app targets the public API by default (`https://dayskew.danailmihov.com/api`,
whose `/api` prefix is stripped by a reverse proxy on the server). For local
dev, override it (Android emulators reach the host via `10.0.2.2`):

```sh
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Start the backend with `make compose` from the repo root.

## Layout

- `lib/src/models/` — Task, PlacedTask, ScheduleResult (mirrors the Go API)
- `lib/src/services/api_client.dart` — stateless REST client
- `lib/src/state/app_controller.dart` — ChangeNotifier app state
- `lib/src/screens/` — home (timeline + reflow) and task management screens
- `lib/src/widgets/` — hero, timeline cards, conflict drawer, neo buttons
- `lib/src/theme/` — color system and typography tokens
- `lib/src/utils/time_format.dart` — minutes-since-midnight formatting

## Test

```sh
flutter analyze
flutter test
```