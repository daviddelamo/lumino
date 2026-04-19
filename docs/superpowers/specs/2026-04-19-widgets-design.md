# Lumino — Home-Screen Widgets Design Spec

**Date:** 2026-04-19
**Phase:** Phase 2 — Retention (1 of 3: Widgets → Mood Tracker → Statistics)
**Platform:** Android
**Status:** Approved

---

## 1. Summary

Add configurable Android home-screen widgets (2×2 and 4×2) that show today's tasks or habits with quick-complete actions. Built with the `home_widget` Flutter package to keep logic Dart-side while rendering via native Android XML layouts.

---

## 2. Scope

### In scope
- 2×2 (small) and 4×2 (large) `AppWidgetProvider` implementations
- Widget configuration screen (type, count, theme)
- Quick-complete: silent for habits, deep-link into app for tasks
- Body tap deep-links to specific item detail
- Automatic widget refresh on data mutations and sync events

### Out of scope
- iOS widgets (future phase)
- Lock-screen widgets
- Interactive Glance/Compose widgets
- Push-triggered widget refresh (server-side)

---

## 3. Architecture

### 3.1 Data Flow

```
Flutter App                   home_widget shared storage        Android Widget
──────────────────            ──────────────────────────        ──────────────
TasksProvider         →  write JSON (today's items)  →         XML RemoteViews
HabitsProvider                                                  reads on update
SyncService
                              SharedPreferences
WidgetUpdateService   →  write config (type/count/theme) →     WidgetConfig.kt
                      ←  complete tap callback         ←       RemoteViews button
```

### 3.2 Key Components

| Component | Layer | Responsibility |
|---|---|---|
| `WidgetUpdateService` | Dart | Serialises today's items to JSON; calls `HomeWidget.updateWidget()` |
| `LuminoSmallWidget` | Kotlin | `AppWidgetProvider` for 2×2; reads shared prefs; renders `RemoteViews` |
| `LuminoLargeWidget` | Kotlin | `AppWidgetProvider` for 4×2; same data, different layout |
| `/widget-config` route | Flutter | Configuration screen launched as Android config activity |
| `onWidgetAction` callback | Dart | Background callback handling complete-tap events |

### 3.3 Shared Preferences Keys

| Key | Value |
|---|---|
| `lumino_widget_type` | `"tasks"` \| `"habits"` |
| `lumino_widget_count` | `3` \| `5` \| `0` (all) |
| `lumino_widget_theme` | `"light"` \| `"dark"` \| `"auto"` |
| `lumino_widget_items` | JSON array of today's items |

---

## 4. Widget Layouts

### 4.1 2×2 Small

```
┌─────────────────────────┐
│ ☀ Today  [Tasks|Habits] │  ← header row
│ ─────────────────────── │
│ ◉ Morning run      ✓   │
│ ◉ Read 30 min      ✓   │
│ ◉ Drink water      ✓   │
│          +2 more        │  ← if items exceed visible count
└─────────────────────────┘
```

- Shows up to 3 items.
- Overflow shown as "+N more" — tapping opens the relevant app tab.

### 4.2 4×2 Large

```
┌─────────────────────────────────────┐
│ ☀ Today · Sat 19 Apr   Tasks|Habits │  ← header
│ ────────────────────────────────── │
│ ◉ Morning run           08:00   ✓   │
│ ◉ Read 30 min           09:30   ✓   │
│ ◉ Drink water           10:00   ✓   │
│ ◉ Meditate              11:00   ✓   │
│ ◉ Evening walk          18:00   ✓   │
└─────────────────────────────────────┘
```

- Shows up to 5 items.
- Time column visible (tasks show start time; habits show reminder time or nothing).
- Same overflow behaviour as small.

### 4.3 Theming

Three XML layout variants keyed on config value:

| Theme setting | Background resource |
|---|---|
| `light` | `widget_bg_light.xml` (white, amber accents) |
| `dark` | `widget_bg_dark.xml` (dark surface, amber accents) |
| `auto` | `@color/widget_background` resolved via `night` resource qualifier |

---

## 5. Interactions

### 5.1 Complete Button Tap

- **Habits** — fires `home_widget` background callback `onWidgetAction('complete', habitId)` → `HabitsNotifier.logEntry()` → marks row dirty → `WidgetUpdateService` refreshes widget data → `HomeWidget.updateWidget()`. App never opens.
- **Tasks** — fires callback → opens app via deep link `/today?task=<id>` → `TodayScreen` scrolls to and highlights the task. User completes from inside the app.

### 5.2 Body Tap (Row, Non-Button Area)

| Tap target | Deep link |
|---|---|
| Habit row | `/habits/<id>` → `HabitDetailScreen` |
| Task row | `/today?task=<id>` → `TodayScreen` scrolled to item |
| Header | `/today` or `/habits` tab root |
| "+N more" | `/today` or `/habits` tab root |

Deep links are handled by the existing `go_router` configuration in `lib/router.dart`. New routes `/habits/:id` and `/today` with `task` query param need to be verified/added.

### 5.3 Widget Configuration Flow

1. User long-presses home screen → selects Lumino widget size.
2. Android launches the config activity pointing to Flutter route `/widget-config`.
3. User selects: **Type** (Tasks / Habits) · **Count** (3 / 5 / All) · **Theme** (Light / Dark / Auto).
4. On "Save" → values written via `HomeWidget.saveWidgetData()` → widget renders immediately.
5. Config can be re-opened by long-pressing the placed widget → "Widget settings".

### 5.4 Refresh Triggers

Widget data is refreshed on any of the following events:

- App returns to foreground (`AppLifecycleState.resumed`)
- `SyncService` completes a sync cycle
- Task created, edited, completed, or deleted
- Habit entry logged or deleted
- Midnight rollover (scheduled via `AlarmManager` from Kotlin side, fires `HomeWidget.updateWidget()`)

---

## 6. Flutter Package

**Package:** [`home_widget`](https://pub.dev/packages/home_widget) (latest stable)

Key APIs used:

```dart
HomeWidget.saveWidgetData<String>('lumino_widget_items', jsonEncode(items));
HomeWidget.updateWidget(androidName: 'LuminoSmallWidget');
HomeWidget.updateWidget(androidName: 'LuminoLargeWidget');
HomeWidget.registerBackgroundCallback(onWidgetAction);
HomeWidget.setAppGroupId('group.com.lumino'); // Android: not needed, but set for future iOS
```

---

## 7. Deep Link Routes (go_router additions)

| Route | Screen | Notes |
|---|---|---|
| `/today` | `TodayScreen` | Already exists |
| `/today?task=<id>` | `TodayScreen` | Scroll + highlight task; new query param handling |
| `/habits` | `HabitsScreen` | Already exists |
| `/habits/:id` | `HabitDetailScreen` | New named route |

---

## 8. Non-Functional Requirements

| # | Requirement |
|---|---|
| NFR-W1 | Widget data refresh completes within 500 ms of a mutation |
| NFR-W2 | Midnight rollover refresh fires within 1 minute of 00:00 local time |
| NFR-W3 | Habit complete tap visible feedback (checkmark) within 200 ms |
| NFR-W4 | Widget renders correctly on Android 8+ (API 26+) |
| NFR-W5 | No crash when widget is present but app data is empty (show friendly empty state) |

---

## 9. Open Questions

- Should the widget show a progress ring (completed/total) in the header, matching the Today screen? Deferred — can add in a polish pass.
- Midnight `AlarmManager` vs `WorkManager` for rollover refresh — decide during implementation based on battery-optimisation constraints.
