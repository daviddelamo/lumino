# Lumino — MVP Design Spec

**Date:** 2026-04-17
**Phase:** MVP (Phase 1)
**Platforms:** Android only
**Status:** Approved

---

## 1. Product Summary

Lumino (tagline: *Daily Rhythm*) is a daily planner and habit tracker app for Android. It is an independent clone of Me+ Daily Routine Planner, built with original branding and assets. The MVP covers onboarding, a daily planner, basic habit tracking, and cloud sync. Paywall and subscriptions are deferred to Phase 2.

**Brand:** Warm amber palette (`#E8823A` primary, `#F7C59F` accent, `#A8D5BA` supporting green), serif wordmark, rounded UI, pastel tone. Design principles: gentle encouragement, never guilt; skimmable at a glance; one-thumb reachability.

---

## 2. MVP Scope

### In scope
- Onboarding flow (goals + quiz + routine preview + sign-up)
- Daily planner (Today timeline, Week view, task CRUD, local notifications)
- Habit tracker (list, add/edit, detail with heatmap, streak)
- Cloud sync (JWT auth, online-first with local Drift cache)
- Profile / Settings screen

### Deferred to Phase 2
- Paywall and subscriptions (RevenueCat)
- Mood tracker
- Content library (meditations, soundscapes)
- Home-screen and lock-screen widgets
- Routine runner / timer mode
- Statistics wrapped reports

---

## 3. Architecture

### 3.1 System Overview

```
Flutter App (Android)          Spring Boot API            Data Stores
─────────────────────          ──────────────────         ───────────
UI Layer (Screens)    ⇄  REST  REST Controllers    →      PostgreSQL
Riverpod Providers             Service Layer               Redis (sessions)
Repository Layer               JWT Auth Filter
Drift (SQLite cache)           JPA Repositories
HTTP Client (Dio)
```

### 3.2 Tech Stack

| Layer | Choice | Reason |
|---|---|---|
| Mobile framework | Flutter 3.x | Single codebase, rich animation, strong Android support |
| State management | Riverpod | Reactive, testable, idiomatic Flutter |
| Local storage | Drift (SQLite) | Reactive queries, works offline, typed schema |
| HTTP client | Dio | Interceptors for JWT refresh, logging |
| Backend framework | Spring Boot (Kotlin) | Team expertise, mature ecosystem |
| Backend API style | REST | Simple, no schema maintenance overhead |
| Primary database | PostgreSQL | Relational, JSONB for flexible fields |
| Session store | Redis | Fast token lookup and rate limiting |
| Auth | Spring Boot JWT (self-hosted) | No vendor dependency; Email + Google OAuth |

### 3.3 Sync Strategy

Online-first with local cache:
- Reads: Flutter reads from Drift (local) for instant UI; data is populated on app start / pull-to-refresh from server.
- Writes: Flutter writes to Drift immediately (instant feedback), then fires async API call. Server state is authoritative; full refresh overwrites local on next sync.
- Dirty flag: Drift rows carry a `dirty: bool` column. A background `SyncService` processes dirty rows on connectivity events.
- Conflict resolution: server wins on full refresh.

### 3.4 Auth Flow

1. User registers or logs in (email/password or Google OAuth code).
2. Spring Boot verifies credentials, issues JWT (15-min TTL) + refresh token (30-day TTL).
3. Refresh token stored in Android Keystore via `flutter_secure_storage`.
4. Dio interceptor auto-refreshes JWT on 401.
5. Anonymous local mode: no account required; data stays local until user signs up.

---

## 4. Data Model

### 4.1 PostgreSQL (backend) — key tables

```sql
users (
  id UUID PK, email TEXT UNIQUE NULLABLE,
  display_name TEXT, auth_provider TEXT,
  locale TEXT, timezone TEXT,
  onboarding_profile JSONB,   -- { goals, quiz, suggested_routine }
  created_at TIMESTAMPTZ, deleted_at TIMESTAMPTZ
)

tasks (
  id UUID PK, user_id UUID FK,
  title TEXT, icon_id TEXT, color TEXT,
  start_at TIMESTAMPTZ, end_at TIMESTAMPTZ,
  repeat_rule JSONB, reminder_offset_min INT,
  notes TEXT, completed_at TIMESTAMPTZ, deleted_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
)

habits (
  id UUID PK, user_id UUID FK,
  title TEXT, icon_id TEXT, color TEXT,
  type TEXT CHECK (type IN ('bool','count','duration')),
  target_value NUMERIC, unit TEXT,
  frequency_rule JSONB, reminder_time TIME,
  created_at TIMESTAMPTZ, archived_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
)

habit_entries (
  id UUID PK, habit_id UUID FK,
  entry_date DATE, value NUMERIC, note TEXT,
  logged_at TIMESTAMPTZ
)

refresh_tokens (
  id UUID PK, user_id UUID FK,
  token_hash TEXT, device_id TEXT,
  expires_at TIMESTAMPTZ, revoked_at TIMESTAMPTZ
)
```

### 4.2 Drift (local Flutter)

Same shape as PostgreSQL tables, plus:
- `synced_at DATETIME` — timestamp of last successful sync
- `dirty INTEGER` (0/1) — marks rows needing a sync push

`onboarding_profile` stored as a JSON string column on the local users table.

---

## 5. REST API

All endpoints require `Authorization: Bearer <jwt>` unless noted. Response envelope: `{ "data": ..., "error": null }`.

### Auth (`/api/auth`)
```
POST /register        { email, password }
POST /login           { email, password } → { jwt, refresh_token }
POST /google          { code }            → { jwt, refresh_token }
POST /refresh         { refresh_token }   → { jwt }
POST /logout          { refresh_token }
```

### Tasks (`/api/tasks`)
```
GET    /?date=YYYY-MM-DD         tasks for a day
POST   /                         create task
PUT    /{id}                     update (title, time, completed_at, etc.)
DELETE /{id}                     soft delete
```

### Habits (`/api/habits`)
```
GET    /                         all active habits
POST   /                         create habit
PUT    /{id}                     update / archive
GET    /{id}/entries?from=&to=   entries for date range
POST   /{id}/entries             log entry
DELETE /{id}/entries/{entryId}   delete entry
```

### User (`/api/me`)
```
GET    /               profile + onboarding data
PUT    /               update profile
DELETE /               delete account (30-day soft delete)
GET    /export         CSV export of all data
```

---

## 6. Screens & Navigation

### 6.1 Navigation Structure
- **Onboarding** (one-time, before main app)
- **Bottom tab bar:** Today · Habits · Me
- **Global FAB:** quick-add sheet (task or habit)

### 6.2 Onboarding Flow (6 steps)

| Step | Content |
|---|---|
| 1. Welcome | Animated Lumino logo + tagline. CTA: "Get Started" |
| 2. Goals | Multi-select chips: Better sleep, Exercise, Mindfulness, Study, Work focus, Self-care, Nutrition, Journaling, Hydration |
| 3. Quiz | 3 questions: chronotype (morning/night), structure preference (rigid/flexible), habit style (solo/social) |
| 4. Routine preview | Starter routine generated **client-side** from quiz answers (pure Dart logic, no server call). Shown as a card list. "Looks good!" CTA |
| 5. Notifications | Contextual permission request. Skippable. |
| 6. Sign up | Email + Google OAuth. "Skip for now" prominent — skipping = local-only mode |

### 6.3 Today Tab

- **Today View:** date header, progress ring (completed/total tasks), vertical scrollable timeline, task cards (icon · title · time · complete button), friendly empty state, FAB
- **Add/Edit Task sheet:** title, icon picker (300 icons), color row, start time, duration, repeat rule, reminder toggle, notes
- **Week View:** 7-column header strip with per-day completion dot, tap → Day view, swipe to navigate weeks

### 6.4 Habits Tab

- **Habit List:** today's habits, streak badge, progress bar, quick-complete tap, FAB → add. MVP enforces a 5-habit UI cap (no paywall backend yet — the limit is a simple count check in the Flutter repository layer, enforced before the add-habit screen opens)
- **Add/Edit Habit:** title, icon, color, type (Boolean/Count/Duration), frequency, optional reminder time
- **Habit Detail:** current streak, longest streak, 30-day heatmap, this-month % completion, recent entries log, edit/archive

### 6.5 Me Tab

Account status, sign in/out, notification settings, Light/Dark theme toggle, CSV export, account deletion, app version.

---

## 7. Non-Functional Requirements (MVP subset)

| # | Requirement |
|---|---|
| NFR-P1 | Cold start < 2s on a mid-range 2023 Android device |
| NFR-P2 | Task completion tap → visible feedback < 100 ms |
| NFR-R1 | Crash-free session rate ≥ 99.5% |
| NFR-Sec1 | TLS 1.2+ for all network traffic |
| NFR-Sec2 | JWT + refresh token in Android Keystore |
| NFR-A1 | WCAG 2.1 AA for all core screens |
| NFR-I1 | Launch in English; strings externalized from day 1 for future i18n |
| NFR-M1 | ≥ 70% unit test coverage on business logic (services, repositories) |

---

## 8. Feature Tracker

Tracked in `docs/FEATURES.md`. Format: checkboxes per feature, grouped by epic. Updated as each item is implemented.

---

## 9. Development Roadmap (MVP)

Assumes: 1–2 mobile engineers, 1 backend engineer, 1 designer (part-time).

| Phase | Duration | Deliverables |
|---|---|---|
| 0 — Setup | 1 week | Repos, CI, Flutter skeleton, Spring Boot skeleton, PostgreSQL schema, Drift schema |
| 1 — Onboarding | 2 weeks | All 6 onboarding screens, local routine generation, notification permission |
| 2 — Daily Planner | 3 weeks | Today view, add/edit task, repeat rules, local notifications, week view |
| 3 — Habits | 2 weeks | Habit list, add/edit, detail + heatmap, streak computation |
| 4 — Auth + Sync | 2 weeks | JWT auth, Google OAuth, Drift dirty-flag sync, SyncService |
| 5 — Profile + Polish | 1 week | Me screen, theme toggle, CSV export, empty states, animations |
| 6 — QA + Launch | 1 week | Internal testing, crash monitoring (Sentry), Play Store internal track |

**Total: ~12 weeks**

---

## 10. Open Questions (Phase 2 decisions)

- Lifetime purchase tier: launch with Phase 2 paywall or A/B test later?
- HealthKit/Health Connect integration: Phase 2 or Phase 3?
- Social/accountability features: evaluate after D30 retention data.
- Family plan: assess after monetization baseline established.
