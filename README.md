# Lumino

A productivity app for building daily rhythms — plan your tasks, track your habits, and stay consistent over time.

Lumino is an offline-first mobile app backed by an optional cloud sync API. It works without an account and syncs automatically when you sign in.

## Repository Structure

```
lumino-app/   Flutter app (Android)
lumino-api/   Spring Boot REST API (Kotlin)
docs/         Feature tracker and design documents
```

## lumino-app

### Requirements

- Flutter 3.22+
- Android SDK with a connected device or emulator

### Run locally

```bash
cd lumino-app
flutter pub get
flutter run
```

By default the app points to `http://10.0.2.2:8080` (localhost through the Android emulator bridge). To target a different API, pass the URL at build time:

```bash
flutter run --dart-define=API_URL=https://your-api-host.com
```

### Run tests

```bash
flutter test
```

### Regenerate database / provider code

Run this after modifying Drift table definitions or Riverpod providers:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Build a release APK

```bash
flutter build apk --split-per-abi --release
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

---

## lumino-api

### Requirements

- Java 21+
- Docker (for local PostgreSQL and integration tests)

### Run locally

```bash
cd lumino-api

# Start PostgreSQL
docker compose up -d

# Copy and configure environment
cp .env.example .env
# Edit .env — generate a JWT secret with: openssl rand -base64 32

# Start the API (http://localhost:8080)
./gradlew bootRun
```

### Run tests

Tests use Testcontainers and require Docker to be running.

```bash
./gradlew test

# Single test class
./gradlew test --tests "com.lumino.api.task.TaskControllerTest"
```

### Environment variables

| Variable | Required | Description |
|---|---|---|
| `DATABASE_URL` | Yes | PostgreSQL JDBC URL |
| `DATABASE_USERNAME` | Yes | Database username |
| `DATABASE_PASSWORD` | Yes | Database password |
| `JWT_SECRET` | Yes | Base64-encoded 256-bit secret (`openssl rand -base64 32`) |
| `GOOGLE_CLIENT_ID` | No | Required only for Google OAuth login |
| `PORT` | No | Server port (default: 8080) |

### Deploy with Docker

The API includes a multi-stage Dockerfile and a Coolify-ready compose file.

```bash
# Build and run locally with Docker
docker build -t lumino-api lumino-api/
docker run -p 8080:8080 \
  -e DATABASE_URL=jdbc:postgresql://host.docker.internal:5432/lumino \
  -e DATABASE_USERNAME=lumino \
  -e DATABASE_PASSWORD=lumino \
  -e JWT_SECRET=your-base64-secret \
  lumino-api
```

For Coolify deployment, point the service at `lumino-api/docker-compose.prod.yml` and set the environment variables through the Coolify dashboard.

---

## API Reference

All endpoints return `{ "data": ..., "error": ... }`. Authenticated routes require `Authorization: Bearer <access_token>`.

| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/api/auth/register` | | Register with email + password |
| POST | `/api/auth/login` | | Login with email + password |
| POST | `/api/auth/refresh` | | Refresh access token |
| POST | `/api/auth/logout` | | Revoke refresh token |
| POST | `/api/auth/google` | | Login / register with Google ID token |
| GET | `/api/me` | ✓ | Get profile |
| PUT | `/api/me` | ✓ | Update profile |
| DELETE | `/api/me` | ✓ | Delete account |
| GET | `/api/tasks?date=YYYY-MM-DD` | ✓ | List tasks for a day |
| POST | `/api/tasks` | ✓ | Create task |
| PUT | `/api/tasks/{id}` | ✓ | Update task |
| DELETE | `/api/tasks/{id}` | ✓ | Soft-delete task |
| GET | `/api/habits` | ✓ | List active habits |
| POST | `/api/habits` | ✓ | Create habit |
| PUT | `/api/habits/{id}` | ✓ | Update / archive habit |
| POST | `/api/habits/{id}/entries` | ✓ | Log habit entry (upsert by date) |
| GET | `/api/habits/{id}/entries?from=&to=` | ✓ | Get entries in date range |
| GET | `/api/habits/{id}/streak` | ✓ | Get current and longest streak |

## License

MIT — see [LICENSE](LICENSE).
