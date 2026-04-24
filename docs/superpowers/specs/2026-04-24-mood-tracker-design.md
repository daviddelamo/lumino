# Mood Tracker — Design Spec
**Date:** 2026-04-24  
**Status:** Approved

---

## Overview

A lightweight mood check-in feature that lets users log a 1–5 mood level once or more per day, optionally annotated with pre-defined tags and a free-text note. Mood history is surfaced on a dedicated screen with a monthly calendar heatmap, a 14-day trend line, and summary stats.

---

## Navigation

| Entry point | Route | Notes |
|---|---|---|
| Emoji button on `TodayScreen` | opens `MoodCheckInSheet` (bottom sheet) | Button shows today's latest mood tile colour if already logged, otherwise neutral |
| "See history →" link in sheet (after save) | `/mood/history` | Pops sheet, pushes history route |
| "Mood history" tile on `MeScreen` | `/mood/history` | Always visible |

---

## Check-in Sheet (`MoodCheckInSheet`)

**Trigger:** Tapping the mood button on `TodayScreen` opens a modal bottom sheet.

**Layout (Option C — coloured tiles):**
- Title: "How are you feeling?"
- 5 equal-width coloured tiles in a horizontal row, each containing an emoji:
  - Level 1 — red (`#E05C5C`) — 😢 Awful
  - Level 2 — orange (`#E8913A`) — 😕 Bad
  - Level 3 — yellow (`#E8C23A`) — 😐 Okay
  - Level 4 — light green (`#8BC48A`) — 🙂 Good
  - Level 5 — green (`#52B788`) — 😄 Amazing
- Selected tile scales up (`height * 1.2`) with a 2 px `#E8823A` border; others remain at base height.
- Label text below each tile (9 px, `#A08070`); selected label uses `#E8823A` bold.
- **Tags section:** 8 pre-defined chips in a wrapping row. Tapping toggles selected state (filled orange `#E8823A` when selected, muted `#EDD8C4` when not).
  - Tags: anxious · calm · energised · tired · grateful · stressed · focused · social
- **Note field:** Optional single-line text input ("Add a note… optional"), shown below tags.
- **Save button:** Full-width, orange (`#E8823A`), disabled until a mood level is selected. On tap: persists entry, triggers sync, dismisses sheet, briefly shows "See history →" snackbar link.

**Multiple entries per day:** Allowed. Each entry is an independent row with its own `loggedAt` timestamp.

---

## Mood History Screen (`/mood/history`)

**Route:** `GoRoute(path: '/mood/history', builder: … MoodHistoryScreen)`

**Layout (Option A — Calendar + Line chart + Stats):**

### Month header
- Left arrow / Month+Year label / Right arrow — navigates months; future months are disabled.

### Calendar heatmap
- 7-column grid, Mon–Sun column headers (1 letter, 8 px).
- Each day cell: 22 px tall, `border-radius: 5`, background = mood colour for that day's **average** level (rounded to nearest integer), using the same 5-colour scale as the check-in tiles.
- Days with no entry: muted `#EDD8C4` at 30% opacity.
- Today's cell: 2 px `#E8823A` border.
- Days in future: empty / invisible.
- Tapping a day cell is out of scope for MVP.

### Trend line chart
- Displays the last 14 calendar days.
- Y-axis: 1–5 (no axis labels rendered; just the line).
- Data points: **average** mood per day. Days with no entry are connected by interpolating (straight line through the gap — handled by `fl_chart` by omitting the null point or connecting).
- Line colour: `#E8823A`, stroke width 2, rounded joins, terminal dot at today.

### Stat callouts (3 tiles in a row)
| Tile | Value | Label |
|---|---|---|
| Emoji of rounded average level | `X.X` numeric | "Avg mood" |
| 🔥 | N | "Day streak" (consecutive days with ≥ 1 entry) |
| ✅ | N/M | "Logged" (entries this month / days in month) |

Stats are computed from the currently displayed month's data, except "streak" which counts backwards from today regardless of displayed month.

### Colour legend
Small row below calendar: 5 colour swatches (level 1 → 5) + label "Low → High".

---

## Data Model

### Drift table — `MoodEntries`

```dart
class MoodEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  IntColumn get moodLevel => integer()();          // 1–5
  TextColumn get tags => text().withDefault(const Constant('[]'))();  // JSON array of strings
  TextColumn get note => text().nullable()();
  DateTimeColumn get loggedAt => dateTime()();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();
}
```

### Drift DAO — `MoodDao`

| Method | Signature | Notes |
|---|---|---|
| `insertEntry` | `Future<int> insertEntry(MoodEntriesCompanion entry)` | Returns new row id |
| `getEntriesForDateRange` | `Future<List<MoodEntry>> getEntriesForDateRange(DateTime from, DateTime to)` | Inclusive, ordered by `loggedAt ASC` |
| `getDirtyEntries` | `Future<List<MoodEntry>> getDirtyEntries(String userId)` | For sync push |
| `markSynced` | `Future<void> markSynced(List<int> ids)` | Sets `dirty = false` |

---

## State Management

**File:** `lib/features/mood/mood_provider.dart`

```dart
class MoodNotifier extends AsyncNotifier<List<MoodEntry>> {
  Future<void> checkIn(int level, List<String> tags, {String? note}) async { … }
  Future<List<MoodEntry>> getEntriesForMonth(int year, int month) async { … }
  Future<List<MoodEntry>> getEntriesForLast14Days() async { … }
}

final moodProvider = AsyncNotifierProvider<MoodNotifier, List<MoodEntry>>(MoodNotifier.new);
```

`MoodNotifier` accesses `AppDatabase` via `ref.read(dbProvider)`. The state holds today's entries (used by `TodayScreen` to colour the mood button).

---

## Sync

`SyncService` gains a `_syncMood(String uid)` method:

1. **Push:** Fetch dirty entries via `MoodDao.getDirtyEntries(uid)`. POST each to `POST /api/mood`. On 201, call `markSynced([id])`.
2. **Pull:** `GET /api/mood?since=<lastPullTimestamp>`. Upsert returned entries locally with `dirty = false`.

`lastMoodPullAt` is stored in `SharedPreferences` (same pattern as tasks/habits).

### API contract (lumino-api — for reference, not implemented in this spec)
- `POST /api/mood` — body: `{ moodLevel, tags, note, loggedAt }`; returns created entry with server-assigned id.
- `GET /api/mood?since=<ISO-8601>` — returns array of entries modified after `since`.

---

## File Structure

```
lib/features/mood/
  mood_check_in_sheet.dart     — MoodCheckInSheet (StatefulWidget)
  mood_history_screen.dart     — MoodHistoryScreen (ConsumerStatefulWidget)
  mood_provider.dart           — MoodNotifier + moodProvider
lib/database/
  tables.dart                  — add MoodEntries table class
  daos/
    mood_dao.dart              — MoodDao
lib/services/
  sync_service.dart            — add _syncMood() method
lib/features/today/
  today_screen.dart            — add mood button; open MoodCheckInSheet
lib/features/me/
  me_screen.dart               — add "Mood history" navigation tile
lib/router.dart                — add /mood/history route
```

---

## Dependencies

- `fl_chart` — **not yet in pubspec.yaml; must be added** for the trend line chart.
- No new Flutter packages required for other UI elements.

---

## Out of Scope (MVP)

- Tapping a calendar day to see its entries.
- Editing or deleting a past mood entry.
- Mood notifications / reminders.
- Habit-mood correlation chart (Statistics phase).
- lumino-api implementation (sync push/pull will silently fail until API endpoint exists).
