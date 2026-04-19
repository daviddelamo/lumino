# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

**Lumino** is a productivity app (tasks, habits, daily planning) consisting of two independent sub-projects:

- `lumino-app/` — Flutter mobile app (Android primary target)
- `lumino-api/` — Spring Boot 3 REST API backend (Kotlin)

---

## lumino-app (Flutter)

### Commands

```bash
cd lumino-app

# Install dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Run all tests
flutter test

# Run a single test file
flutter test test/services/sync_service_test.dart

# Regenerate Drift and Riverpod code after changing tables/providers
dart run build_runner build --delete-conflicting-outputs

# Build release APK
flutter build apk --release
# or split by ABI (smaller):
flutter build apk --split-per-abi --release

# Install to device via ADB
adb install build/app/outputs/flutter-apk/app-release.apk
```

The API base URL is set at compile time via `--dart-define=API_URL=https://...`. The default (`http://10.0.2.2:8080`) points to localhost through the Android emulator bridge.

### Architecture

**State management:** Riverpod (`flutter_riverpod`). Providers live in `*_provider.dart` files co-located with their feature.

**Routing:** `go_router` configured in `lib/router.dart`. All routes are flat (no nested shell routes yet). Initial route is `/onboarding/welcome`; after onboarding completes, navigation pushes to `/today`.

**Local database:** Drift (SQLite) with generated code. Schema defined in `lib/database/tables.dart`. DAOs in `lib/database/daos/`. The `AppDatabase` singleton is exposed via `dbProvider` in `tasks_provider.dart`.

**Offline-first sync:** `SyncService` (`lib/services/sync_service.dart`) runs on app start and on connectivity changes. It pushes rows flagged `dirty = true` to the API, then pulls the latest from the server. Tasks and Habits both carry a `dirty` boolean column.

**API calls:** `ApiClient` (`lib/services/api_client.dart`) wraps Dio. A `QueuedInterceptor` automatically injects the Bearer token and handles 401s by attempting a token refresh before retrying the original request. Tokens are stored in `FlutterSecureStorage` (Android Keystore-backed).

**Feature structure:**
```
lib/features/
  onboarding/   — welcome → goals → quiz → preview → notifications → signup
  today/        — TodayScreen (timeline + progress ring), WeekViewScreen
  habits/       — HabitsScreen, HabitFormScreen, HabitDetailScreen (30-day heatmap)
  me/           — MeScreen (profile, theme toggle, sign-out, account deletion)
lib/shared/     — reusable widgets (ProgressRing, EmptyState)
lib/services/   — ApiClient, AuthService, SyncService, NotificationService
lib/database/   — Drift schema, DAOs, generated files (*.g.dart)
```

**Free tier limit:** `HabitsNotifier.addHabit` enforces a max of 5 habits.

---

## lumino-api (Spring Boot / Kotlin)

### Commands

```bash
cd lumino-api

# Start PostgreSQL (required for running the app and tests)
docker compose up -d

# Run the API (reads from .env or environment variables)
./gradlew bootRun

# Run all tests (Testcontainers — Docker must be running)
./gradlew test

# Run a single test class
./gradlew test --tests "com.lumino.api.task.TaskControllerTest"

# Build JAR
./gradlew bootJar

# Build Docker image
docker build -t lumino-api .
```

Copy `.env.example` to `.env` and set `JWT_SECRET` (Base64-encoded 256-bit value: `openssl rand -base64 32`).

### Architecture

**Domain modules:** `auth`, `task`, `habit`, `user` — each contains entity, repository, service, controller, and `dto/` sub-package.

**Auth flow:** Stateless JWT. `JwtService` issues short-lived access tokens and long-lived refresh tokens stored in the `refresh_tokens` table. `SecurityConfig` protects all routes except `/api/auth/**`. Google OAuth is supported via ID token verification at `/api/auth/google`.

**Response envelope:** All endpoints return `{ "data": ..., "error": ... }` via `ApiResponse<T>` in `common/`.

**Database:** PostgreSQL 16 via Spring Data JPA. Flyway manages migrations in `src/main/resources/db/migration/`.

**Testing:** All integration tests use Testcontainers (real PostgreSQL). No mocking of the database layer.

**Environment variables:**

| Variable | Required | Description |
|---|---|---|
| `DATABASE_URL` | Yes | JDBC URL (default: `jdbc:postgresql://localhost:5432/lumino`) |
| `DATABASE_USERNAME` / `DATABASE_PASSWORD` | Yes | DB credentials (default: `lumino`) |
| `JWT_SECRET` | Yes | Base64-encoded 256-bit secret |
| `GOOGLE_CLIENT_ID` | No | Required only for Google OAuth |
| `PORT` | No | Server port (default: 8080) |
