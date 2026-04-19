# Lumino API

Spring Boot 3.2.3 REST API backend for the Lumino productivity app.

## Tech Stack

- Kotlin 1.9 + Spring Boot 3.2.3
- Spring Security (stateless JWT)
- Spring Data JPA + PostgreSQL 16
- Flyway migrations
- JJWT 0.12 for JWT signing
- Testcontainers for integration tests

## Prerequisites

- Java 21+
- Docker (for local PostgreSQL)
- Gradle (wrapper included)

## Local Development

### 1. Start PostgreSQL

```bash
docker compose up -d
```

This starts PostgreSQL 16 on port 5432 (credentials: `lumino/lumino`, database: `lumino`).

### 2. Configure environment

Copy `.env.example` and set your values:

```bash
cp .env.example .env
```

Generate a JWT secret (must be Base64-encoded, 256-bit / 32 bytes minimum):

```bash
openssl rand -base64 32
```

### 3. Run the API

```bash
./gradlew bootRun
```

The API starts at `http://localhost:8080`.

### 4. Run tests

```bash
./gradlew test
```

Tests use Testcontainers — Docker must be running. All tests run against a real PostgreSQL container.

## API Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/api/auth/register` | — | Register with email/password |
| POST | `/api/auth/login` | — | Login with email/password |
| POST | `/api/auth/refresh` | — | Refresh access token |
| POST | `/api/auth/logout` | — | Revoke refresh token |
| POST | `/api/auth/google` | — | Login/register with Google ID token |
| GET | `/api/me` | ✓ | Get profile |
| PUT | `/api/me` | ✓ | Update profile |
| DELETE | `/api/me` | ✓ | Delete account |
| GET | `/api/tasks?date=YYYY-MM-DD` | ✓ | List tasks for a day |
| POST | `/api/tasks` | ✓ | Create task |
| PUT | `/api/tasks/{id}` | ✓ | Update task |
| DELETE | `/api/tasks/{id}` | ✓ | Soft-delete task |
| GET | `/api/habits` | ✓ | List active habits |
| POST | `/api/habits` | ✓ | Create habit |
| PUT | `/api/habits/{id}` | ✓ | Update/archive habit |
| POST | `/api/habits/{id}/entries` | ✓ | Log habit entry (upsert by date) |
| GET | `/api/habits/{id}/entries?from=&to=` | ✓ | Get entries in date range |
| GET | `/api/habits/{id}/streak` | ✓ | Get current and longest streak |

All responses use the `{ "data": ..., "error": ... }` envelope.

## Deployment with Docker

### Build the JAR

```bash
./gradlew bootJar
```

### Build the Docker image

```bash
docker build -t lumino-api .
```

### Run the container

```bash
docker run -p 8080:8080 \
  -e DATABASE_URL=jdbc:postgresql://host.docker.internal:5432/lumino \
  -e DATABASE_USERNAME=lumino \
  -e DATABASE_PASSWORD=lumino \
  -e JWT_SECRET=your-base64-secret \
  -e GOOGLE_CLIENT_ID=your-google-client-id \
  lumino-api
```

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DATABASE_URL` | Yes | `jdbc:postgresql://localhost:5432/lumino` | PostgreSQL JDBC URL |
| `DATABASE_USERNAME` | Yes | `lumino` | Database username |
| `DATABASE_PASSWORD` | Yes | `lumino` | Database password |
| `JWT_SECRET` | **Yes** | dev default | Base64-encoded 256-bit secret for JWT signing |
| `GOOGLE_CLIENT_ID` | No | — | Google OAuth client ID (required for `/api/auth/google`) |
| `PORT` | No | `8080` | Server port |
