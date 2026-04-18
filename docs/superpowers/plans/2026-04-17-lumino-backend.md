# Lumino Backend Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Lumino REST API — auth, tasks, habits, and user profile — using Spring Boot (Kotlin) backed by PostgreSQL.

**Architecture:** Stateless JWT-secured REST API. Spring Security filter chain validates Bearer tokens on every request except `/api/auth/**`. PostgreSQL via Spring Data JPA; Flyway manages schema migrations. Refresh tokens stored in PostgreSQL.

**Tech Stack:** Kotlin 1.9, Spring Boot 3.2, Spring Security, Spring Data JPA, Flyway, PostgreSQL 16, JJWT 0.12, Testcontainers (tests), Gradle Kotlin DSL.

---

## File Map

```
lumino-api/
├── build.gradle.kts
├── settings.gradle.kts
├── docker-compose.yml
├── src/main/kotlin/com/lumino/api/
│   ├── LuminoApiApplication.kt
│   ├── common/
│   │   ├── ApiResponse.kt            – response envelope { data, error }
│   │   ├── GlobalExceptionHandler.kt – @RestControllerAdvice
│   │   └── CurrentUser.kt            – @CurrentUser annotation + resolver
│   ├── config/
│   │   ├── SecurityConfig.kt         – filter chain, BCrypt bean
│   │   └── JwtConfig.kt              – JWT properties binding
│   ├── auth/
│   │   ├── JwtService.kt             – generate/validate JWT
│   │   ├── JwtAuthFilter.kt          – OncePerRequestFilter
│   │   ├── RefreshToken.kt           – JPA entity
│   │   ├── RefreshTokenRepository.kt
│   │   ├── AuthService.kt            – register, login, refresh, logout, google
│   │   ├── AuthController.kt         – POST /api/auth/*
│   │   └── dto/
│   │       ├── RegisterRequest.kt
│   │       ├── LoginRequest.kt
│   │       ├── GoogleAuthRequest.kt
│   │       ├── RefreshRequest.kt
│   │       └── AuthResponse.kt
│   ├── user/
│   │   ├── User.kt                   – JPA entity
│   │   ├── UserRepository.kt
│   │   ├── UserService.kt            – profile, soft-delete, CSV export
│   │   ├── UserController.kt         – GET/PUT/DELETE /api/me
│   │   └── dto/
│   │       ├── UpdateProfileRequest.kt
│   │       └── UserResponse.kt
│   ├── task/
│   │   ├── Task.kt                   – JPA entity
│   │   ├── TaskRepository.kt
│   │   ├── TaskService.kt
│   │   ├── TaskController.kt         – GET/POST/PUT/DELETE /api/tasks
│   │   └── dto/
│   │       ├── CreateTaskRequest.kt
│   │       ├── UpdateTaskRequest.kt
│   │       └── TaskResponse.kt
│   └── habit/
│       ├── Habit.kt                  – JPA entity
│       ├── HabitEntry.kt             – JPA entity
│       ├── HabitRepository.kt
│       ├── HabitEntryRepository.kt
│       ├── HabitService.kt           – streak computation
│       ├── HabitController.kt        – /api/habits + /api/habits/{id}/entries
│       └── dto/
│           ├── CreateHabitRequest.kt
│           ├── UpdateHabitRequest.kt
│           ├── HabitResponse.kt
│           ├── LogEntryRequest.kt
│           └── HabitEntryResponse.kt
├── src/main/resources/
│   ├── application.yml
│   └── db/migration/V1__init.sql
└── src/test/kotlin/com/lumino/api/
    ├── TestcontainersBase.kt
    ├── auth/AuthControllerTest.kt
    ├── task/TaskControllerTest.kt
    └── habit/HabitControllerTest.kt
```

---

## Task 1: Project Bootstrap

**Files:**
- Create: `lumino-api/settings.gradle.kts`
- Create: `lumino-api/build.gradle.kts`
- Create: `lumino-api/docker-compose.yml`
- Create: `lumino-api/src/main/resources/application.yml`
- Create: `lumino-api/src/main/kotlin/com/lumino/api/LuminoApiApplication.kt`

- [ ] **Step 1: Create project skeleton**

```bash
mkdir -p lumino-api/src/main/kotlin/com/lumino/api
mkdir -p lumino-api/src/main/resources/db/migration
mkdir -p lumino-api/src/test/kotlin/com/lumino/api
```

- [ ] **Step 2: Write `settings.gradle.kts`**

```kotlin
rootProject.name = "lumino-api"
```

- [ ] **Step 3: Write `build.gradle.kts`**

```kotlin
plugins {
    kotlin("jvm") version "1.9.22"
    kotlin("plugin.spring") version "1.9.22"
    kotlin("plugin.jpa") version "1.9.22"
    id("org.springframework.boot") version "3.2.3"
    id("io.spring.dependency-management") version "1.1.4"
}

group = "com.lumino"
version = "0.0.1-SNAPSHOT"

java { sourceCompatibility = JavaVersion.VERSION_21 }

repositories { mavenCentral() }

dependencies {
    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("org.springframework.boot:spring-boot-starter-data-jpa")
    implementation("org.springframework.boot:spring-boot-starter-security")
    implementation("org.springframework.boot:spring-boot-starter-validation")
    implementation("org.flywaydb:flyway-core")
    implementation("org.flywaydb:flyway-database-postgresql")
    implementation("com.fasterxml.jackson.module:jackson-module-kotlin")
    implementation("io.jsonwebtoken:jjwt-api:0.12.3")
    runtimeOnly("io.jsonwebtoken:jjwt-impl:0.12.3")
    runtimeOnly("io.jsonwebtoken:jjwt-jackson:0.12.3")
    runtimeOnly("org.postgresql:postgresql")
    testImplementation("org.springframework.boot:spring-boot-starter-test")
    testImplementation("org.springframework.security:spring-security-test")
    testImplementation("org.testcontainers:postgresql:1.19.4")
    testImplementation("org.testcontainers:junit-jupiter:1.19.4")
}

tasks.withType<Test> { useJUnitPlatform() }
```

- [ ] **Step 4: Write `docker-compose.yml`**

```yaml
version: '3.8'
services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: lumino
      POSTGRES_USER: lumino
      POSTGRES_PASSWORD: lumino
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
volumes:
  postgres_data:
```

- [ ] **Step 5: Write `src/main/resources/application.yml`**

```yaml
spring:
  datasource:
    url: ${DATABASE_URL:jdbc:postgresql://localhost:5432/lumino}
    username: ${DATABASE_USERNAME:lumino}
    password: ${DATABASE_PASSWORD:lumino}
  jpa:
    hibernate:
      ddl-auto: validate
    properties:
      hibernate:
        dialect: org.hibernate.dialect.PostgreSQLDialect
  flyway:
    enabled: true
    locations: classpath:db/migration

jwt:
  secret: ${JWT_SECRET:dGhpcy1pcy1hLTI1Ni1iaXQtc2VjcmV0LWtleS1mb3ItbHVtaW5vLWFwcA==}
  access-token-expiry-ms: 900000
  refresh-token-expiry-days: 30

server:
  port: ${PORT:8080}
```

- [ ] **Step 6: Write `LuminoApiApplication.kt`**

```kotlin
package com.lumino.api

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication

@SpringBootApplication
class LuminoApiApplication

fun main(args: Array<String>) {
    runApplication<LuminoApiApplication>(*args)
}
```

- [ ] **Step 7: Start Docker and verify it runs**

```bash
cd lumino-api
docker compose up -d
./gradlew bootRun
# Expected: "Started LuminoApiApplication" in logs, no errors
```

- [ ] **Step 8: Commit**

```bash
git add lumino-api/
git commit -m "feat: bootstrap Spring Boot project with Gradle and Docker Compose"
```

---

## Task 2: Database Migration

**Files:**
- Create: `lumino-api/src/main/resources/db/migration/V1__init.sql`
- Create: `lumino-api/src/test/kotlin/com/lumino/api/TestcontainersBase.kt`

- [ ] **Step 1: Write `V1__init.sql`**

```sql
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE,
    password_hash TEXT,
    display_name TEXT,
    auth_provider TEXT NOT NULL DEFAULT 'email',
    locale TEXT NOT NULL DEFAULT 'en',
    timezone TEXT NOT NULL DEFAULT 'UTC',
    onboarding_profile JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    icon_id TEXT NOT NULL DEFAULT 'circle',
    color TEXT NOT NULL DEFAULT '#E8823A',
    start_at TIMESTAMPTZ NOT NULL,
    end_at TIMESTAMPTZ,
    repeat_rule JSONB,
    reminder_offset_min INT,
    notes TEXT,
    completed_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE habits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    icon_id TEXT NOT NULL DEFAULT 'circle',
    color TEXT NOT NULL DEFAULT '#E8823A',
    type TEXT NOT NULL CHECK (type IN ('bool', 'count', 'duration')),
    target_value NUMERIC NOT NULL DEFAULT 1,
    unit TEXT,
    frequency_rule JSONB NOT NULL,
    reminder_time TIME,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    archived_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE habit_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    habit_id UUID NOT NULL REFERENCES habits(id) ON DELETE CASCADE,
    entry_date DATE NOT NULL,
    value NUMERIC NOT NULL DEFAULT 1,
    note TEXT,
    logged_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (habit_id, entry_date)
);

CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash TEXT NOT NULL,
    device_id TEXT,
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_tasks_user_date ON tasks(user_id, start_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_habits_user ON habits(user_id) WHERE archived_at IS NULL;
CREATE INDEX idx_habit_entries_habit_date ON habit_entries(habit_id, entry_date);
CREATE INDEX idx_refresh_tokens_hash ON refresh_tokens(token_hash) WHERE revoked_at IS NULL;
```

- [ ] **Step 2: Write `TestcontainersBase.kt`**

```kotlin
package com.lumino.api

import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.test.context.DynamicPropertyRegistry
import org.springframework.test.context.DynamicPropertySource
import org.testcontainers.containers.PostgreSQLContainer
import org.testcontainers.junit.jupiter.Testcontainers

@SpringBootTest
@AutoConfigureMockMvc
@Testcontainers
abstract class TestcontainersBase {
    companion object {
        private val postgres = PostgreSQLContainer<Nothing>("postgres:16-alpine").apply {
            withDatabaseName("lumino_test")
            withUsername("lumino")
            withPassword("lumino")
            start()
        }

        @JvmStatic
        @DynamicPropertySource
        fun configureProperties(registry: DynamicPropertyRegistry) {
            registry.add("spring.datasource.url", postgres::getJdbcUrl)
            registry.add("spring.datasource.username", postgres::getUsername)
            registry.add("spring.datasource.password", postgres::getPassword)
        }
    }
}
```

- [ ] **Step 3: Verify migration runs**

```bash
./gradlew test --tests "com.lumino.api.*"
# Expected: PASS (no tests yet, but Flyway migration should succeed on container start)
```

- [ ] **Step 4: Commit**

```bash
git add lumino-api/src/main/resources/db/migration/ lumino-api/src/test/
git commit -m "feat: add Flyway schema migration and Testcontainers base"
```

---

## Task 3: Common Infrastructure

**Files:**
- Create: `lumino-api/src/main/kotlin/com/lumino/api/common/ApiResponse.kt`
- Create: `lumino-api/src/main/kotlin/com/lumino/api/common/GlobalExceptionHandler.kt`
- Create: `lumino-api/src/main/kotlin/com/lumino/api/common/CurrentUser.kt`

- [ ] **Step 1: Write `ApiResponse.kt`**

```kotlin
package com.lumino.api.common

data class ApiResponse<T>(
    val data: T? = null,
    val error: String? = null
) {
    companion object {
        fun <T> ok(data: T) = ApiResponse(data = data)
        fun error(message: String) = ApiResponse<Nothing>(error = message)
    }
}
```

- [ ] **Step 2: Write `GlobalExceptionHandler.kt`**

```kotlin
package com.lumino.api.common

import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.security.access.AccessDeniedException
import org.springframework.web.bind.MethodArgumentNotValidException
import org.springframework.web.bind.annotation.ExceptionHandler
import org.springframework.web.bind.annotation.RestControllerAdvice

@RestControllerAdvice
class GlobalExceptionHandler {

    @ExceptionHandler(IllegalArgumentException::class)
    fun handleBadRequest(ex: IllegalArgumentException) =
        ResponseEntity.badRequest().body(ApiResponse.error(ex.message ?: "Bad request"))

    @ExceptionHandler(NoSuchElementException::class)
    fun handleNotFound(ex: NoSuchElementException) =
        ResponseEntity.status(HttpStatus.NOT_FOUND).body(ApiResponse.error("Not found"))

    @ExceptionHandler(AccessDeniedException::class)
    fun handleForbidden(ex: AccessDeniedException) =
        ResponseEntity.status(HttpStatus.FORBIDDEN).body(ApiResponse.error("Forbidden"))

    @ExceptionHandler(MethodArgumentNotValidException::class)
    fun handleValidation(ex: MethodArgumentNotValidException): ResponseEntity<ApiResponse<Nothing>> {
        val message = ex.bindingResult.fieldErrors.joinToString("; ") { "${it.field}: ${it.defaultMessage}" }
        return ResponseEntity.badRequest().body(ApiResponse.error(message))
    }
}
```

- [ ] **Step 3: Write `CurrentUser.kt`** (annotation + argument resolver to inject the authenticated `User` into controller methods)

```kotlin
package com.lumino.api.common

import com.lumino.api.user.User
import org.springframework.core.MethodParameter
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.stereotype.Component
import org.springframework.web.bind.support.WebDataBinderFactory
import org.springframework.web.context.request.NativeWebRequest
import org.springframework.web.method.support.HandlerMethodArgumentResolver
import org.springframework.web.method.support.ModelAndViewContainer

@Target(AnnotationTarget.VALUE_PARAMETER)
@Retention(AnnotationRetention.RUNTIME)
annotation class CurrentUser

@Component
class CurrentUserArgumentResolver : HandlerMethodArgumentResolver {
    override fun supportsParameter(parameter: MethodParameter) =
        parameter.hasParameterAnnotation(CurrentUser::class.java) &&
        parameter.parameterType == User::class.java

    override fun resolveArgument(
        parameter: MethodParameter,
        mavContainer: ModelAndViewContainer?,
        webRequest: NativeWebRequest,
        binderFactory: WebDataBinderFactory?
    ): User = SecurityContextHolder.getContext().authentication?.principal as? User
        ?: throw AccessDeniedException("Not authenticated")
}
```

- [ ] **Step 4: Register argument resolver in `WebMvcConfig.kt`**

Create `lumino-api/src/main/kotlin/com/lumino/api/config/WebMvcConfig.kt`:

```kotlin
package com.lumino.api.config

import com.lumino.api.common.CurrentUserArgumentResolver
import org.springframework.context.annotation.Configuration
import org.springframework.web.method.support.HandlerMethodArgumentResolver
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer

@Configuration
class WebMvcConfig(private val currentUserArgumentResolver: CurrentUserArgumentResolver) : WebMvcConfigurer {
    override fun addArgumentResolvers(resolvers: MutableList<HandlerMethodArgumentResolver>) {
        resolvers.add(currentUserArgumentResolver)
    }
}
```

- [ ] **Step 5: Commit**

```bash
git add lumino-api/src/main/kotlin/com/lumino/api/common/ lumino-api/src/main/kotlin/com/lumino/api/config/
git commit -m "feat: add ApiResponse wrapper, GlobalExceptionHandler, and CurrentUser resolver"
```

---

## Task 4: User Entity + JWT Service

**Files:**
- Create: `lumino-api/src/main/kotlin/com/lumino/api/user/User.kt`
- Create: `lumino-api/src/main/kotlin/com/lumino/api/user/UserRepository.kt`
- Create: `lumino-api/src/main/kotlin/com/lumino/api/config/JwtConfig.kt`
- Create: `lumino-api/src/main/kotlin/com/lumino/api/auth/JwtService.kt`
- Create: `lumino-api/src/test/kotlin/com/lumino/api/auth/JwtServiceTest.kt`

- [ ] **Step 1: Write the failing test**

```kotlin
// src/test/kotlin/com/lumino/api/auth/JwtServiceTest.kt
package com.lumino.api.auth

import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test
import java.util.UUID

class JwtServiceTest {
    private val jwtService = JwtService(
        secret = "dGhpcy1pcy1hLTI1Ni1iaXQtc2VjcmV0LWtleS1mb3ItbHVtaW5vLWFwcA==",
        accessTokenExpiryMs = 900_000L
    )

    @Test
    fun `generates token and extracts userId`() {
        val userId = UUID.randomUUID()
        val token = jwtService.generateAccessToken(userId)
        assertEquals(userId, jwtService.extractUserId(token))
    }

    @Test
    fun `isValid returns false for garbage token`() {
        assertFalse(jwtService.isValid("not.a.token"))
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
./gradlew test --tests "com.lumino.api.auth.JwtServiceTest"
# Expected: FAIL — JwtService class not found
```

- [ ] **Step 3: Write `JwtConfig.kt`**

```kotlin
package com.lumino.api.config

import org.springframework.boot.context.properties.ConfigurationProperties
import org.springframework.stereotype.Component

@Component
@ConfigurationProperties(prefix = "jwt")
class JwtConfig {
    var secret: String = ""
    var accessTokenExpiryMs: Long = 900_000
    var refreshTokenExpiryDays: Long = 30
}
```

- [ ] **Step 4: Write `User.kt`** (implements `UserDetails` so Spring Security can use it directly)

```kotlin
package com.lumino.api.user

import jakarta.persistence.*
import org.springframework.security.core.GrantedAuthority
import org.springframework.security.core.userdetails.UserDetails
import java.time.Instant
import java.util.UUID

@Entity
@Table(name = "users")
class User(
    @Id val id: UUID = UUID.randomUUID(),
    val email: String? = null,
    @Column(name = "password_hash") private val passwordHash: String? = null,
    val displayName: String? = null,
    val authProvider: String = "email",
    val locale: String = "en",
    val timezone: String = "UTC",
    @Column(columnDefinition = "jsonb") val onboardingProfile: String? = null,
    val createdAt: Instant = Instant.now(),
    val deletedAt: Instant? = null
) : UserDetails {
    override fun getAuthorities(): Collection<GrantedAuthority> = emptyList()
    override fun getPassword() = passwordHash
    override fun getUsername() = id.toString()
    override fun isAccountNonExpired() = deletedAt == null
    override fun isAccountNonLocked() = deletedAt == null
    override fun isCredentialsNonExpired() = true
    override fun isEnabled() = deletedAt == null
}
```

- [ ] **Step 5: Write `UserRepository.kt`**

```kotlin
package com.lumino.api.user

import org.springframework.data.jpa.repository.JpaRepository
import java.util.UUID

interface UserRepository : JpaRepository<User, UUID> {
    fun findByEmail(email: String): User?
    fun existsByEmail(email: String): Boolean
}
```

- [ ] **Step 6: Write `JwtService.kt`**

```kotlin
package com.lumino.api.auth

import com.lumino.api.config.JwtConfig
import io.jsonwebtoken.Jwts
import io.jsonwebtoken.io.Decoders
import io.jsonwebtoken.security.Keys
import org.springframework.stereotype.Service
import java.util.Date
import java.util.UUID
import javax.crypto.SecretKey

@Service
class JwtService(
    private val secret: String,
    private val accessTokenExpiryMs: Long
) {
    constructor(config: JwtConfig) : this(config.secret, config.accessTokenExpiryMs)

    private val key: SecretKey by lazy {
        Keys.hmacShaKeyFor(Decoders.BASE64.decode(secret))
    }

    fun generateAccessToken(userId: UUID): String =
        Jwts.builder()
            .subject(userId.toString())
            .issuedAt(Date())
            .expiration(Date(System.currentTimeMillis() + accessTokenExpiryMs))
            .signWith(key)
            .compact()

    fun extractUserId(token: String): UUID =
        UUID.fromString(
            Jwts.parser().verifyWith(key).build()
                .parseSignedClaims(token).payload.subject
        )

    fun isValid(token: String): Boolean = runCatching { extractUserId(token) }.isSuccess
}
```

- [ ] **Step 7: Run test to verify it passes**

```bash
./gradlew test --tests "com.lumino.api.auth.JwtServiceTest"
# Expected: PASS
```

- [ ] **Step 8: Commit**

```bash
git add lumino-api/src/main/kotlin/com/lumino/api/ lumino-api/src/test/
git commit -m "feat: add User entity, UserRepository, and JwtService"
```

---

## Task 5: Auth — Register and Login

**Files:**
- Create: `lumino-api/src/main/kotlin/com/lumino/api/auth/dto/*.kt`
- Create: `lumino-api/src/main/kotlin/com/lumino/api/auth/RefreshToken.kt`
- Create: `lumino-api/src/main/kotlin/com/lumino/api/auth/RefreshTokenRepository.kt`
- Create: `lumino-api/src/main/kotlin/com/lumino/api/auth/AuthService.kt`
- Create: `lumino-api/src/main/kotlin/com/lumino/api/auth/AuthController.kt`
- Create: `lumino-api/src/test/kotlin/com/lumino/api/auth/AuthControllerTest.kt`

- [ ] **Step 1: Write the failing test**

```kotlin
// src/test/kotlin/com/lumino/api/auth/AuthControllerTest.kt
package com.lumino.api.auth

import com.lumino.api.TestcontainersBase
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.http.MediaType
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.post

class AuthControllerTest : TestcontainersBase() {
    @Autowired lateinit var mockMvc: MockMvc

    @Test
    fun `register creates a user and returns tokens`() {
        mockMvc.post("/api/auth/register") {
            contentType = MediaType.APPLICATION_JSON
            content = """{"email":"test@lumino.app","password":"secret123"}"""
        }.andExpect {
            status { isOk() }
            jsonPath("$.data.accessToken") { exists() }
            jsonPath("$.data.refreshToken") { exists() }
        }
    }

    @Test
    fun `login with correct credentials returns tokens`() {
        mockMvc.post("/api/auth/register") {
            contentType = MediaType.APPLICATION_JSON
            content = """{"email":"login@lumino.app","password":"secret123"}"""
        }
        mockMvc.post("/api/auth/login") {
            contentType = MediaType.APPLICATION_JSON
            content = """{"email":"login@lumino.app","password":"secret123"}"""
        }.andExpect {
            status { isOk() }
            jsonPath("$.data.accessToken") { exists() }
        }
    }

    @Test
    fun `login with wrong password returns 400`() {
        mockMvc.post("/api/auth/register") {
            contentType = MediaType.APPLICATION_JSON
            content = """{"email":"bad@lumino.app","password":"correct"}"""
        }
        mockMvc.post("/api/auth/login") {
            contentType = MediaType.APPLICATION_JSON
            content = """{"email":"bad@lumino.app","password":"wrong"}"""
        }.andExpect {
            status { isBadRequest() }
        }
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
./gradlew test --tests "com.lumino.api.auth.AuthControllerTest"
# Expected: FAIL — AuthController not found / 404
```

- [ ] **Step 3: Write DTOs**

```kotlin
// dto/RegisterRequest.kt
package com.lumino.api.auth.dto
import jakarta.validation.constraints.Email
import jakarta.validation.constraints.Size
data class RegisterRequest(
    @field:Email val email: String,
    @field:Size(min = 6) val password: String
)

// dto/LoginRequest.kt
package com.lumino.api.auth.dto
data class LoginRequest(val email: String, val password: String)

// dto/AuthResponse.kt
package com.lumino.api.auth.dto
data class AuthResponse(val accessToken: String, val refreshToken: String)

// dto/RefreshRequest.kt
package com.lumino.api.auth.dto
data class RefreshRequest(val refreshToken: String)

// dto/GoogleAuthRequest.kt
package com.lumino.api.auth.dto
data class GoogleAuthRequest(val idToken: String)
```

- [ ] **Step 4: Write `RefreshToken.kt`**

```kotlin
package com.lumino.api.auth

import com.lumino.api.user.User
import jakarta.persistence.*
import java.time.Instant
import java.util.UUID

@Entity
@Table(name = "refresh_tokens")
class RefreshToken(
    @Id val id: UUID = UUID.randomUUID(),
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id") val user: User,
    val tokenHash: String,
    val deviceId: String? = null,
    val expiresAt: Instant,
    val revokedAt: Instant? = null,
    val createdAt: Instant = Instant.now()
)
```

- [ ] **Step 5: Write `RefreshTokenRepository.kt`**

```kotlin
package com.lumino.api.auth

import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Modifying
import org.springframework.data.jpa.repository.Query
import java.util.UUID

interface RefreshTokenRepository : JpaRepository<RefreshToken, UUID> {
    fun findByTokenHashAndRevokedAtIsNull(hash: String): RefreshToken?

    @Modifying
    @Query("UPDATE RefreshToken r SET r.revokedAt = CURRENT_TIMESTAMP WHERE r.user.id = :userId")
    fun revokeAllForUser(userId: UUID)
}
```

- [ ] **Step 6: Write `AuthService.kt`**

```kotlin
package com.lumino.api.auth

import com.lumino.api.auth.dto.*
import com.lumino.api.config.JwtConfig
import com.lumino.api.user.User
import com.lumino.api.user.UserRepository
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.security.MessageDigest
import java.time.Instant
import java.util.Base64
import java.util.UUID

@Service
class AuthService(
    private val userRepository: UserRepository,
    private val refreshTokenRepository: RefreshTokenRepository,
    private val jwtService: JwtService,
    private val passwordEncoder: PasswordEncoder,
    private val jwtConfig: JwtConfig
) {
    @Transactional
    fun register(request: RegisterRequest): AuthResponse {
        if (userRepository.existsByEmail(request.email))
            throw IllegalArgumentException("Email already registered")
        val user = userRepository.save(
            User(email = request.email, passwordHash = passwordEncoder.encode(request.password))
        )
        return issueTokens(user)
    }

    fun login(request: LoginRequest): AuthResponse {
        val user = userRepository.findByEmail(request.email)
            ?: throw IllegalArgumentException("Invalid credentials")
        if (!passwordEncoder.matches(request.password, user.password))
            throw IllegalArgumentException("Invalid credentials")
        return issueTokens(user)
    }

    @Transactional
    fun refresh(request: RefreshRequest): AuthResponse {
        val hash = sha256(request.refreshToken)
        val token = refreshTokenRepository.findByTokenHashAndRevokedAtIsNull(hash)
            ?: throw IllegalArgumentException("Invalid refresh token")
        if (token.expiresAt.isBefore(Instant.now()))
            throw IllegalArgumentException("Refresh token expired")
        return issueTokens(token.user)
    }

    @Transactional
    fun logout(request: RefreshRequest) {
        val hash = sha256(request.refreshToken)
        val token = refreshTokenRepository.findByTokenHashAndRevokedAtIsNull(hash) ?: return
        refreshTokenRepository.save(token.copy(revokedAt = Instant.now()))
    }

    private fun issueTokens(user: User): AuthResponse {
        val accessToken = jwtService.generateAccessToken(user.id)
        val rawRefresh = UUID.randomUUID().toString()
        refreshTokenRepository.save(
            RefreshToken(
                user = user,
                tokenHash = sha256(rawRefresh),
                expiresAt = Instant.now().plusSeconds(jwtConfig.refreshTokenExpiryDays * 86_400)
            )
        )
        return AuthResponse(accessToken, rawRefresh)
    }

    private fun sha256(input: String): String =
        Base64.getEncoder().encodeToString(
            MessageDigest.getInstance("SHA-256").digest(input.toByteArray())
        )
}
```

- [ ] **Step 7: Write `AuthController.kt`**

```kotlin
package com.lumino.api.auth

import com.lumino.api.auth.dto.*
import com.lumino.api.common.ApiResponse
import jakarta.validation.Valid
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/auth")
class AuthController(private val authService: AuthService) {

    @PostMapping("/register")
    fun register(@Valid @RequestBody request: RegisterRequest) =
        ApiResponse.ok(authService.register(request))

    @PostMapping("/login")
    fun login(@RequestBody request: LoginRequest) =
        ApiResponse.ok(authService.login(request))

    @PostMapping("/refresh")
    fun refresh(@RequestBody request: RefreshRequest) =
        ApiResponse.ok(authService.refresh(request))

    @PostMapping("/logout")
    fun logout(@RequestBody request: RefreshRequest) {
        authService.logout(request)
    }
}
```

- [ ] **Step 8: Add a temporary `SecurityConfig.kt` that permits all requests (will be secured in Task 6)**

Create `lumino-api/src/main/kotlin/com/lumino/api/config/SecurityConfig.kt`:

```kotlin
package com.lumino.api.config

import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.security.config.annotation.web.builders.HttpSecurity
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.security.web.SecurityFilterChain

@Configuration
@EnableWebSecurity
class SecurityConfig {
    @Bean
    fun filterChain(http: HttpSecurity): SecurityFilterChain =
        http.csrf { it.disable() }
            .authorizeHttpRequests { it.anyRequest().permitAll() }
            .build()

    @Bean
    fun passwordEncoder(): PasswordEncoder = BCryptPasswordEncoder()
}
```

- [ ] **Step 9: Run test to verify it passes**

```bash
./gradlew test --tests "com.lumino.api.auth.AuthControllerTest"
# Expected: PASS (all 3 tests green)
```

- [ ] **Step 10: Commit**

```bash
git add lumino-api/src/
git commit -m "feat: add register, login, refresh, and logout auth endpoints"
```

---

## Task 6: JWT Auth Filter + Security Config

**Files:**
- Create: `lumino-api/src/main/kotlin/com/lumino/api/auth/JwtAuthFilter.kt`
- Modify: `lumino-api/src/main/kotlin/com/lumino/api/config/SecurityConfig.kt`
- Modify: `lumino-api/src/test/kotlin/com/lumino/api/auth/AuthControllerTest.kt` (add protected endpoint test)

- [ ] **Step 1: Add failing test for protected endpoint**

Add to `AuthControllerTest.kt`:

```kotlin
@Test
fun `request without token to protected endpoint returns 401`() {
    mockMvc.get("/api/me").andExpect { status { isUnauthorized() } }
}

@Test
fun `request with valid token to protected endpoint succeeds`() {
    val reg = mockMvc.post("/api/auth/register") {
        contentType = MediaType.APPLICATION_JSON
        content = """{"email":"protected@lumino.app","password":"secret123"}"""
    }.andReturn().response.contentAsString

    // Extract accessToken from JSON response
    val token = com.fasterxml.jackson.databind.ObjectMapper()
        .readTree(reg)["data"]["accessToken"].asText()

    mockMvc.get("/api/me") {
        header("Authorization", "Bearer $token")
    }.andExpect { status { isOk() } }
}
```

- [ ] **Step 2: Run test to verify the new tests fail**

```bash
./gradlew test --tests "com.lumino.api.auth.AuthControllerTest"
# Expected: 2 new tests FAIL (no /api/me endpoint yet, no 401 on missing token)
```

- [ ] **Step 3: Write `JwtAuthFilter.kt`**

```kotlin
package com.lumino.api.auth

import com.lumino.api.user.UserRepository
import jakarta.servlet.FilterChain
import jakarta.servlet.http.HttpServletRequest
import jakarta.servlet.http.HttpServletResponse
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.stereotype.Component
import org.springframework.web.filter.OncePerRequestFilter

@Component
class JwtAuthFilter(
    private val jwtService: JwtService,
    private val userRepository: UserRepository
) : OncePerRequestFilter() {

    override fun doFilterInternal(
        request: HttpServletRequest,
        response: HttpServletResponse,
        chain: FilterChain
    ) {
        val header = request.getHeader("Authorization")
        if (header != null && header.startsWith("Bearer ")) {
            val token = header.removePrefix("Bearer ")
            if (jwtService.isValid(token)) {
                val userId = jwtService.extractUserId(token)
                userRepository.findById(userId).ifPresent { user ->
                    SecurityContextHolder.getContext().authentication =
                        UsernamePasswordAuthenticationToken(user, null, emptyList())
                }
            }
        }
        chain.doFilter(request, response)
    }
}
```

- [ ] **Step 4: Replace `SecurityConfig.kt` with the secure version**

```kotlin
package com.lumino.api.config

import com.lumino.api.auth.JwtAuthFilter
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.security.config.annotation.web.builders.HttpSecurity
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity
import org.springframework.security.config.http.SessionCreationPolicy
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.security.web.SecurityFilterChain
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter

@Configuration
@EnableWebSecurity
class SecurityConfig(private val jwtAuthFilter: JwtAuthFilter) {

    @Bean
    fun filterChain(http: HttpSecurity): SecurityFilterChain =
        http
            .csrf { it.disable() }
            .sessionManagement { it.sessionCreationPolicy(SessionCreationPolicy.STATELESS) }
            .authorizeHttpRequests {
                it.requestMatchers("/api/auth/**").permitAll()
                it.anyRequest().authenticated()
            }
            .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter::class.java)
            .build()

    @Bean
    fun passwordEncoder(): PasswordEncoder = BCryptPasswordEncoder()
}
```

- [ ] **Step 5: Add a minimal `/api/me` stub to `UserController.kt`** (full implementation in Task 9)

Create `lumino-api/src/main/kotlin/com/lumino/api/user/UserController.kt`:

```kotlin
package com.lumino.api.user

import com.lumino.api.common.ApiResponse
import com.lumino.api.common.CurrentUser
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/api/me")
class UserController {
    @GetMapping
    fun getProfile(@CurrentUser user: User) =
        ApiResponse.ok(mapOf("id" to user.id, "email" to user.email, "displayName" to user.displayName))
}
```

- [ ] **Step 6: Run all auth tests**

```bash
./gradlew test --tests "com.lumino.api.auth.AuthControllerTest"
# Expected: all 5 tests PASS
```

- [ ] **Step 7: Commit**

```bash
git add lumino-api/src/
git commit -m "feat: add JWT auth filter and secure all endpoints except /api/auth/**"
```

---

## Task 7: Tasks API

**Files:**
- Create: `lumino-api/src/main/kotlin/com/lumino/api/task/Task.kt`
- Create: `lumino-api/src/main/kotlin/com/lumino/api/task/TaskRepository.kt`
- Create: `lumino-api/src/main/kotlin/com/lumino/api/task/dto/*.kt`
- Create: `lumino-api/src/main/kotlin/com/lumino/api/task/TaskService.kt`
- Create: `lumino-api/src/main/kotlin/com/lumino/api/task/TaskController.kt`
- Create: `lumino-api/src/test/kotlin/com/lumino/api/task/TaskControllerTest.kt`

- [ ] **Step 1: Write failing tests**

```kotlin
// src/test/kotlin/com/lumino/api/task/TaskControllerTest.kt
package com.lumino.api.task

import com.fasterxml.jackson.databind.ObjectMapper
import com.lumino.api.TestcontainersBase
import com.lumino.api.auth.dto.RegisterRequest
import com.lumino.api.auth.AuthService
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.http.MediaType
import org.springframework.test.web.servlet.*

class TaskControllerTest : TestcontainersBase() {
    @Autowired lateinit var mockMvc: MockMvc
    @Autowired lateinit var authService: AuthService
    private val mapper = ObjectMapper()
    private lateinit var token: String

    @BeforeEach
    fun setup() {
        val reg = authService.register(RegisterRequest("task-test-${System.nanoTime()}@lumino.app", "secret123"))
        token = reg.accessToken
    }

    @Test
    fun `create task and retrieve it for the day`() {
        mockMvc.post("/api/tasks") {
            header("Authorization", "Bearer $token")
            contentType = MediaType.APPLICATION_JSON
            content = """{"title":"Morning run","iconId":"run","color":"#E8823A","startAt":"2026-04-17T07:00:00Z","endAt":"2026-04-17T07:30:00Z"}"""
        }.andExpect {
            status { isOk() }
            jsonPath("$.data.title") { value("Morning run") }
        }

        mockMvc.get("/api/tasks?date=2026-04-17") {
            header("Authorization", "Bearer $token")
        }.andExpect {
            status { isOk() }
            jsonPath("$.data[0].title") { value("Morning run") }
        }
    }

    @Test
    fun `complete a task`() {
        val result = mockMvc.post("/api/tasks") {
            header("Authorization", "Bearer $token")
            contentType = MediaType.APPLICATION_JSON
            content = """{"title":"Complete me","iconId":"check","color":"#4CAF82","startAt":"2026-04-17T09:00:00Z"}"""
        }.andReturn().response.contentAsString

        val taskId = mapper.readTree(result)["data"]["id"].asText()

        mockMvc.put("/api/tasks/$taskId") {
            header("Authorization", "Bearer $token")
            contentType = MediaType.APPLICATION_JSON
            content = """{"completedAt":"2026-04-17T09:05:00Z"}"""
        }.andExpect {
            status { isOk() }
            jsonPath("$.data.completedAt") { exists() }
        }
    }

    @Test
    fun `delete task soft-deletes it`() {
        val result = mockMvc.post("/api/tasks") {
            header("Authorization", "Bearer $token")
            contentType = MediaType.APPLICATION_JSON
            content = """{"title":"Delete me","iconId":"trash","color":"#E57373","startAt":"2026-04-17T10:00:00Z"}"""
        }.andReturn().response.contentAsString

        val taskId = mapper.readTree(result)["data"]["id"].asText()

        mockMvc.delete("/api/tasks/$taskId") {
            header("Authorization", "Bearer $token")
        }.andExpect { status { isOk() } }

        mockMvc.get("/api/tasks?date=2026-04-17") {
            header("Authorization", "Bearer $token")
        }.andExpect {
            jsonPath("$.data[?(@.id == '$taskId')]") { doesNotExist() }
        }
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
./gradlew test --tests "com.lumino.api.task.TaskControllerTest"
# Expected: FAIL — TaskController not found
```

- [ ] **Step 3: Write `Task.kt`**

```kotlin
package com.lumino.api.task

import com.lumino.api.user.User
import jakarta.persistence.*
import java.time.Instant
import java.util.UUID

@Entity
@Table(name = "tasks")
class Task(
    @Id val id: UUID = UUID.randomUUID(),
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id") val user: User,
    var title: String,
    var iconId: String = "circle",
    var color: String = "#E8823A",
    var startAt: Instant,
    var endAt: Instant? = null,
    @Column(columnDefinition = "jsonb") var repeatRule: String? = null,
    var reminderOffsetMin: Int? = null,
    var notes: String? = null,
    var completedAt: Instant? = null,
    var deletedAt: Instant? = null,
    var updatedAt: Instant = Instant.now()
)
```

- [ ] **Step 4: Write `TaskRepository.kt`**

```kotlin
package com.lumino.api.task

import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import java.time.Instant
import java.util.UUID

interface TaskRepository : JpaRepository<Task, UUID> {
    @Query("""
        SELECT t FROM Task t
        WHERE t.user.id = :userId
          AND t.deletedAt IS NULL
          AND t.startAt >= :startOfDay
          AND t.startAt < :endOfDay
        ORDER BY t.startAt
    """)
    fun findByUserAndDate(userId: UUID, startOfDay: Instant, endOfDay: Instant): List<Task>
}
```

- [ ] **Step 5: Write DTOs**

```kotlin
// dto/CreateTaskRequest.kt
package com.lumino.api.task.dto
import jakarta.validation.constraints.NotBlank
import java.time.Instant
data class CreateTaskRequest(
    @field:NotBlank val title: String,
    val iconId: String = "circle",
    val color: String = "#E8823A",
    val startAt: Instant,
    val endAt: Instant? = null,
    val repeatRule: String? = null,
    val reminderOffsetMin: Int? = null,
    val notes: String? = null
)

// dto/UpdateTaskRequest.kt
package com.lumino.api.task.dto
import java.time.Instant
data class UpdateTaskRequest(
    val title: String? = null,
    val iconId: String? = null,
    val color: String? = null,
    val startAt: Instant? = null,
    val endAt: Instant? = null,
    val repeatRule: String? = null,
    val reminderOffsetMin: Int? = null,
    val notes: String? = null,
    val completedAt: Instant? = null
)

// dto/TaskResponse.kt
package com.lumino.api.task.dto
import com.lumino.api.task.Task
import java.time.Instant
import java.util.UUID
data class TaskResponse(
    val id: UUID, val title: String, val iconId: String, val color: String,
    val startAt: Instant, val endAt: Instant?, val repeatRule: String?,
    val reminderOffsetMin: Int?, val notes: String?,
    val completedAt: Instant?, val updatedAt: Instant
) {
    companion object {
        fun from(t: Task) = TaskResponse(
            t.id, t.title, t.iconId, t.color, t.startAt, t.endAt,
            t.repeatRule, t.reminderOffsetMin, t.notes, t.completedAt, t.updatedAt
        )
    }
}
```

- [ ] **Step 6: Write `TaskService.kt`**

```kotlin
package com.lumino.api.task

import com.lumino.api.task.dto.*
import com.lumino.api.user.User
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneOffset
import java.util.UUID

@Service
class TaskService(private val taskRepository: TaskRepository) {

    fun getTasksForDay(user: User, date: LocalDate): List<TaskResponse> {
        val start = date.atStartOfDay().toInstant(ZoneOffset.UTC)
        val end = date.plusDays(1).atStartOfDay().toInstant(ZoneOffset.UTC)
        return taskRepository.findByUserAndDate(user.id, start, end).map { TaskResponse.from(it) }
    }

    @Transactional
    fun createTask(user: User, request: CreateTaskRequest): TaskResponse {
        val task = taskRepository.save(
            Task(
                user = user, title = request.title, iconId = request.iconId,
                color = request.color, startAt = request.startAt, endAt = request.endAt,
                repeatRule = request.repeatRule, reminderOffsetMin = request.reminderOffsetMin,
                notes = request.notes
            )
        )
        return TaskResponse.from(task)
    }

    @Transactional
    fun updateTask(user: User, taskId: UUID, request: UpdateTaskRequest): TaskResponse {
        val task = taskRepository.findById(taskId).orElseThrow { NoSuchElementException("Task not found") }
        if (task.user.id != user.id) throw AccessDeniedException("Not your task")
        request.title?.let { task.title = it }
        request.iconId?.let { task.iconId = it }
        request.color?.let { task.color = it }
        request.startAt?.let { task.startAt = it }
        request.endAt?.let { task.endAt = it }
        request.repeatRule?.let { task.repeatRule = it }
        request.reminderOffsetMin?.let { task.reminderOffsetMin = it }
        request.notes?.let { task.notes = it }
        request.completedAt?.let { task.completedAt = it }
        task.updatedAt = Instant.now()
        return TaskResponse.from(taskRepository.save(task))
    }

    @Transactional
    fun deleteTask(user: User, taskId: UUID) {
        val task = taskRepository.findById(taskId).orElseThrow { NoSuchElementException("Task not found") }
        if (task.user.id != user.id) throw AccessDeniedException("Not your task")
        task.deletedAt = Instant.now()
        taskRepository.save(task)
    }
}
```

- [ ] **Step 7: Write `TaskController.kt`**

```kotlin
package com.lumino.api.task

import com.lumino.api.common.ApiResponse
import com.lumino.api.common.CurrentUser
import com.lumino.api.task.dto.CreateTaskRequest
import com.lumino.api.task.dto.UpdateTaskRequest
import com.lumino.api.user.User
import jakarta.validation.Valid
import org.springframework.format.annotation.DateTimeFormat
import org.springframework.web.bind.annotation.*
import java.time.LocalDate
import java.util.UUID

@RestController
@RequestMapping("/api/tasks")
class TaskController(private val taskService: TaskService) {

    @GetMapping
    fun getTasks(
        @CurrentUser user: User,
        @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) date: LocalDate
    ) = ApiResponse.ok(taskService.getTasksForDay(user, date))

    @PostMapping
    fun createTask(@CurrentUser user: User, @Valid @RequestBody request: CreateTaskRequest) =
        ApiResponse.ok(taskService.createTask(user, request))

    @PutMapping("/{id}")
    fun updateTask(
        @CurrentUser user: User,
        @PathVariable id: UUID,
        @RequestBody request: UpdateTaskRequest
    ) = ApiResponse.ok(taskService.updateTask(user, id, request))

    @DeleteMapping("/{id}")
    fun deleteTask(@CurrentUser user: User, @PathVariable id: UUID) {
        taskService.deleteTask(user, id)
    }
}
```

- [ ] **Step 8: Run tests**

```bash
./gradlew test --tests "com.lumino.api.task.TaskControllerTest"
# Expected: PASS (all 3 tests green)
```

- [ ] **Step 9: Commit**

```bash
git add lumino-api/src/
git commit -m "feat: add Tasks API (CRUD, soft delete, filter by date)"
```

---

## Task 8: Habits API

**Files:**
- Create: `lumino-api/src/main/kotlin/com/lumino/api/habit/Habit.kt`
- Create: `lumino-api/src/main/kotlin/com/lumino/api/habit/HabitRepository.kt`
- Create: `lumino-api/src/main/kotlin/com/lumino/api/habit/dto/*.kt`
- Create: `lumino-api/src/main/kotlin/com/lumino/api/habit/HabitService.kt`
- Create: `lumino-api/src/main/kotlin/com/lumino/api/habit/HabitController.kt`
- Create: `lumino-api/src/test/kotlin/com/lumino/api/habit/HabitControllerTest.kt`

- [ ] **Step 1: Write failing test**

```kotlin
// src/test/kotlin/com/lumino/api/habit/HabitControllerTest.kt
package com.lumino.api.habit

import com.fasterxml.jackson.databind.ObjectMapper
import com.lumino.api.TestcontainersBase
import com.lumino.api.auth.AuthService
import com.lumino.api.auth.dto.RegisterRequest
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.http.MediaType
import org.springframework.test.web.servlet.*

class HabitControllerTest : TestcontainersBase() {
    @Autowired lateinit var mockMvc: MockMvc
    @Autowired lateinit var authService: AuthService
    private val mapper = ObjectMapper()
    private lateinit var token: String

    @BeforeEach
    fun setup() {
        token = authService.register(RegisterRequest("habit-${System.nanoTime()}@lumino.app", "secret123")).accessToken
    }

    @Test
    fun `create habit and list it`() {
        mockMvc.post("/api/habits") {
            header("Authorization", "Bearer $token")
            contentType = MediaType.APPLICATION_JSON
            content = """{"title":"Drink water","iconId":"water","color":"#5B6EF5","type":"count","targetValue":8,"unit":"glasses","frequencyRule":{"type":"daily"}}"""
        }.andExpect {
            status { isOk() }
            jsonPath("$.data.title") { value("Drink water") }
        }

        mockMvc.get("/api/habits") {
            header("Authorization", "Bearer $token")
        }.andExpect {
            status { isOk() }
            jsonPath("$.data[0].title") { value("Drink water") }
        }
    }

    @Test
    fun `archive habit removes it from list`() {
        val result = mockMvc.post("/api/habits") {
            header("Authorization", "Bearer $token")
            contentType = MediaType.APPLICATION_JSON
            content = """{"title":"Archive me","iconId":"x","color":"#E57373","type":"bool","targetValue":1,"frequencyRule":{"type":"daily"}}"""
        }.andReturn().response.contentAsString
        val habitId = mapper.readTree(result)["data"]["id"].asText()

        mockMvc.put("/api/habits/$habitId") {
            header("Authorization", "Bearer $token")
            contentType = MediaType.APPLICATION_JSON
            content = """{"archived":true}"""
        }.andExpect { status { isOk() } }

        mockMvc.get("/api/habits") {
            header("Authorization", "Bearer $token")
        }.andExpect {
            jsonPath("$.data[?(@.id == '$habitId')]") { doesNotExist() }
        }
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
./gradlew test --tests "com.lumino.api.habit.HabitControllerTest"
# Expected: FAIL — HabitController not found
```

- [ ] **Step 3: Write `Habit.kt`**

```kotlin
package com.lumino.api.habit

import com.lumino.api.user.User
import jakarta.persistence.*
import java.time.Instant
import java.time.LocalTime
import java.util.UUID

@Entity
@Table(name = "habits")
class Habit(
    @Id val id: UUID = UUID.randomUUID(),
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id") val user: User,
    var title: String,
    var iconId: String = "circle",
    var color: String = "#E8823A",
    var type: String,
    var targetValue: Double = 1.0,
    var unit: String? = null,
    @Column(columnDefinition = "jsonb") var frequencyRule: String,
    var reminderTime: LocalTime? = null,
    val createdAt: Instant = Instant.now(),
    var archivedAt: Instant? = null,
    var updatedAt: Instant = Instant.now()
)
```

- [ ] **Step 4: Write `HabitRepository.kt`**

```kotlin
package com.lumino.api.habit

import org.springframework.data.jpa.repository.JpaRepository
import java.util.UUID

interface HabitRepository : JpaRepository<Habit, UUID> {
    fun findByUserIdAndArchivedAtIsNull(userId: UUID): List<Habit>
}
```

- [ ] **Step 5: Write DTOs**

```kotlin
// dto/CreateHabitRequest.kt
package com.lumino.api.habit.dto
import jakarta.validation.constraints.NotBlank
data class CreateHabitRequest(
    @field:NotBlank val title: String,
    val iconId: String = "circle",
    val color: String = "#E8823A",
    val type: String,          // "bool" | "count" | "duration"
    val targetValue: Double = 1.0,
    val unit: String? = null,
    val frequencyRule: String, // JSON string: {"type":"daily"} or {"type":"weekly","days":[1,2,3]}
    val reminderTime: String? = null  // "HH:mm"
)

// dto/UpdateHabitRequest.kt
package com.lumino.api.habit.dto
data class UpdateHabitRequest(
    val title: String? = null,
    val iconId: String? = null,
    val color: String? = null,
    val targetValue: Double? = null,
    val unit: String? = null,
    val frequencyRule: String? = null,
    val reminderTime: String? = null,
    val archived: Boolean? = null
)

// dto/HabitResponse.kt
package com.lumino.api.habit.dto
import com.lumino.api.habit.Habit
import java.time.Instant
import java.util.UUID
data class HabitResponse(
    val id: UUID, val title: String, val iconId: String, val color: String,
    val type: String, val targetValue: Double, val unit: String?,
    val frequencyRule: String, val reminderTime: String?,
    val createdAt: Instant, val updatedAt: Instant
) {
    companion object {
        fun from(h: Habit) = HabitResponse(
            h.id, h.title, h.iconId, h.color, h.type, h.targetValue,
            h.unit, h.frequencyRule, h.reminderTime?.toString(),
            h.createdAt, h.updatedAt
        )
    }
}
```

- [ ] **Step 6: Write `HabitService.kt`**

```kotlin
package com.lumino.api.habit

import com.lumino.api.habit.dto.*
import com.lumino.api.user.User
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Instant
import java.time.LocalTime
import java.util.UUID

@Service
class HabitService(private val habitRepository: HabitRepository) {

    fun getHabits(user: User): List<HabitResponse> =
        habitRepository.findByUserIdAndArchivedAtIsNull(user.id).map { HabitResponse.from(it) }

    @Transactional
    fun createHabit(user: User, request: CreateHabitRequest): HabitResponse {
        val habit = habitRepository.save(
            Habit(
                user = user, title = request.title, iconId = request.iconId,
                color = request.color, type = request.type, targetValue = request.targetValue,
                unit = request.unit, frequencyRule = request.frequencyRule,
                reminderTime = request.reminderTime?.let { LocalTime.parse(it) }
            )
        )
        return HabitResponse.from(habit)
    }

    @Transactional
    fun updateHabit(user: User, habitId: UUID, request: UpdateHabitRequest): HabitResponse {
        val habit = habitRepository.findById(habitId).orElseThrow { NoSuchElementException() }
        if (habit.user.id != user.id) throw AccessDeniedException("Not your habit")
        request.title?.let { habit.title = it }
        request.iconId?.let { habit.iconId = it }
        request.color?.let { habit.color = it }
        request.targetValue?.let { habit.targetValue = it }
        request.unit?.let { habit.unit = it }
        request.frequencyRule?.let { habit.frequencyRule = it }
        request.reminderTime?.let { habit.reminderTime = LocalTime.parse(it) }
        if (request.archived == true) habit.archivedAt = Instant.now()
        habit.updatedAt = Instant.now()
        return HabitResponse.from(habitRepository.save(habit))
    }
}
```

- [ ] **Step 7: Write `HabitController.kt`** (entries endpoints added in Task 9)

```kotlin
package com.lumino.api.habit

import com.lumino.api.common.ApiResponse
import com.lumino.api.common.CurrentUser
import com.lumino.api.habit.dto.CreateHabitRequest
import com.lumino.api.habit.dto.UpdateHabitRequest
import com.lumino.api.user.User
import jakarta.validation.Valid
import org.springframework.web.bind.annotation.*
import java.util.UUID

@RestController
@RequestMapping("/api/habits")
class HabitController(private val habitService: HabitService) {

    @GetMapping
    fun getHabits(@CurrentUser user: User) = ApiResponse.ok(habitService.getHabits(user))

    @PostMapping
    fun createHabit(@CurrentUser user: User, @Valid @RequestBody request: CreateHabitRequest) =
        ApiResponse.ok(habitService.createHabit(user, request))

    @PutMapping("/{id}")
    fun updateHabit(
        @CurrentUser user: User,
        @PathVariable id: UUID,
        @RequestBody request: UpdateHabitRequest
    ) = ApiResponse.ok(habitService.updateHabit(user, id, request))
}
```

- [ ] **Step 8: Run tests**

```bash
./gradlew test --tests "com.lumino.api.habit.HabitControllerTest"
# Expected: PASS
```

- [ ] **Step 9: Commit**

```bash
git add lumino-api/src/
git commit -m "feat: add Habits API (CRUD, archive)"
```

---

## Task 9: Habit Entries API

**Files:**
- Create: `lumino-api/src/main/kotlin/com/lumino/api/habit/HabitEntry.kt`
- Create: `lumino-api/src/main/kotlin/com/lumino/api/habit/HabitEntryRepository.kt`
- Create: `lumino-api/src/main/kotlin/com/lumino/api/habit/dto/LogEntryRequest.kt`
- Create: `lumino-api/src/main/kotlin/com/lumino/api/habit/dto/HabitEntryResponse.kt`
- Modify: `lumino-api/src/main/kotlin/com/lumino/api/habit/HabitService.kt`
- Modify: `lumino-api/src/main/kotlin/com/lumino/api/habit/HabitController.kt`
- Modify: `lumino-api/src/test/kotlin/com/lumino/api/habit/HabitControllerTest.kt`

- [ ] **Step 1: Add failing tests for entries**

Add to `HabitControllerTest.kt`:

```kotlin
@Test
fun `log habit entry and retrieve it`() {
    val result = mockMvc.post("/api/habits") {
        header("Authorization", "Bearer $token")
        contentType = MediaType.APPLICATION_JSON
        content = """{"title":"Read","iconId":"book","color":"#9B72D0","type":"duration","targetValue":30,"unit":"min","frequencyRule":{"type":"daily"}}"""
    }.andReturn().response.contentAsString
    val habitId = mapper.readTree(result)["data"]["id"].asText()

    mockMvc.post("/api/habits/$habitId/entries") {
        header("Authorization", "Bearer $token")
        contentType = MediaType.APPLICATION_JSON
        content = """{"entryDate":"2026-04-17","value":30}"""
    }.andExpect {
        status { isOk() }
        jsonPath("$.data.value") { value(30) }
    }

    mockMvc.get("/api/habits/$habitId/entries?from=2026-04-01&to=2026-04-30") {
        header("Authorization", "Bearer $token")
    }.andExpect {
        status { isOk() }
        jsonPath("$.data[0].entryDate") { value("2026-04-17") }
    }
}

@Test
fun `streak is computed correctly`() {
    val result = mockMvc.post("/api/habits") {
        header("Authorization", "Bearer $token")
        contentType = MediaType.APPLICATION_JSON
        content = """{"title":"Meditate","iconId":"yoga","color":"#E8823A","type":"bool","targetValue":1,"frequencyRule":{"type":"daily"}}"""
    }.andReturn().response.contentAsString
    val habitId = mapper.readTree(result)["data"]["id"].asText()

    listOf("2026-04-15", "2026-04-16", "2026-04-17").forEach { date ->
        mockMvc.post("/api/habits/$habitId/entries") {
            header("Authorization", "Bearer $token")
            contentType = MediaType.APPLICATION_JSON
            content = """{"entryDate":"$date","value":1}"""
        }
    }

    mockMvc.get("/api/habits/$habitId/streak") {
        header("Authorization", "Bearer $token")
    }.andExpect {
        status { isOk() }
        jsonPath("$.data.currentStreak") { value(3) }
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
./gradlew test --tests "com.lumino.api.habit.HabitControllerTest.log habit entry and retrieve it"
# Expected: FAIL
```

- [ ] **Step 3: Write `HabitEntry.kt`**

```kotlin
package com.lumino.api.habit

import jakarta.persistence.*
import java.time.Instant
import java.time.LocalDate
import java.util.UUID

@Entity
@Table(name = "habit_entries")
class HabitEntry(
    @Id val id: UUID = UUID.randomUUID(),
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "habit_id") val habit: Habit,
    val entryDate: LocalDate,
    var value: Double = 1.0,
    var note: String? = null,
    val loggedAt: Instant = Instant.now()
)
```

- [ ] **Step 4: Write `HabitEntryRepository.kt`**

```kotlin
package com.lumino.api.habit

import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import java.time.LocalDate
import java.util.UUID

interface HabitEntryRepository : JpaRepository<HabitEntry, UUID> {
    fun findByHabitIdAndEntryDateBetweenOrderByEntryDate(
        habitId: UUID, from: LocalDate, to: LocalDate
    ): List<HabitEntry>

    fun findByHabitIdAndEntryDate(habitId: UUID, date: LocalDate): HabitEntry?

    @Query("""
        SELECT e.entryDate FROM HabitEntry e
        WHERE e.habit.id = :habitId
        ORDER BY e.entryDate DESC
    """)
    fun findAllDatesByHabitId(habitId: UUID): List<LocalDate>
}
```

- [ ] **Step 5: Write DTOs**

```kotlin
// dto/LogEntryRequest.kt
package com.lumino.api.habit.dto
import java.time.LocalDate
data class LogEntryRequest(val entryDate: LocalDate, val value: Double = 1.0, val note: String? = null)

// dto/HabitEntryResponse.kt
package com.lumino.api.habit.dto
import com.lumino.api.habit.HabitEntry
import java.time.LocalDate
import java.util.UUID
data class HabitEntryResponse(val id: UUID, val entryDate: LocalDate, val value: Double, val note: String?) {
    companion object { fun from(e: HabitEntry) = HabitEntryResponse(e.id, e.entryDate, e.value, e.note) }
}

// dto/StreakResponse.kt
package com.lumino.api.habit.dto
data class StreakResponse(val currentStreak: Int, val longestStreak: Int)
```

- [ ] **Step 6: Add entry and streak methods to `HabitService.kt`**

Add these methods to `HabitService`:

```kotlin
@Transactional
fun logEntry(user: User, habitId: UUID, request: LogEntryRequest): HabitEntryResponse {
    val habit = habitRepository.findById(habitId).orElseThrow { NoSuchElementException() }
    if (habit.user.id != user.id) throw AccessDeniedException("Not your habit")
    val existing = habitEntryRepository.findByHabitIdAndEntryDate(habitId, request.entryDate)
    val entry = if (existing != null) {
        existing.value = request.value
        existing.note = request.note
        habitEntryRepository.save(existing)
    } else {
        habitEntryRepository.save(HabitEntry(habit = habit, entryDate = request.entryDate, value = request.value, note = request.note))
    }
    return HabitEntryResponse.from(entry)
}

fun getEntries(user: User, habitId: UUID, from: LocalDate, to: LocalDate): List<HabitEntryResponse> {
    val habit = habitRepository.findById(habitId).orElseThrow { NoSuchElementException() }
    if (habit.user.id != user.id) throw AccessDeniedException("Not your habit")
    return habitEntryRepository.findByHabitIdAndEntryDateBetweenOrderByEntryDate(habitId, from, to)
        .map { HabitEntryResponse.from(it) }
}

fun getStreak(user: User, habitId: UUID): StreakResponse {
    val habit = habitRepository.findById(habitId).orElseThrow { NoSuchElementException() }
    if (habit.user.id != user.id) throw AccessDeniedException("Not your habit")
    val dates = habitEntryRepository.findAllDatesByHabitId(habitId).toSortedSet().reversed()
    var current = 0
    var longest = 0
    var streak = 0
    var prev: LocalDate? = null
    for (date in dates) {
        streak = if (prev == null || prev == date.plusDays(1)) streak + 1 else 1
        if (current == 0 && (prev == null || prev == date.plusDays(1))) current = streak
        if (streak > longest) longest = streak
        prev = date
    }
    return StreakResponse(current, longest)
}
```

Also add `private val habitEntryRepository: HabitEntryRepository` to the constructor.

- [ ] **Step 7: Add entry endpoints to `HabitController.kt`**

Add to `HabitController`:

```kotlin
@PostMapping("/{id}/entries")
fun logEntry(
    @CurrentUser user: User,
    @PathVariable id: UUID,
    @RequestBody request: LogEntryRequest
) = ApiResponse.ok(habitService.logEntry(user, id, request))

@GetMapping("/{id}/entries")
fun getEntries(
    @CurrentUser user: User,
    @PathVariable id: UUID,
    @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) from: LocalDate,
    @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) to: LocalDate
) = ApiResponse.ok(habitService.getEntries(user, id, from, to))

@GetMapping("/{id}/streak")
fun getStreak(@CurrentUser user: User, @PathVariable id: UUID) =
    ApiResponse.ok(habitService.getStreak(user, id))
```

- [ ] **Step 8: Run all habit tests**

```bash
./gradlew test --tests "com.lumino.api.habit.HabitControllerTest"
# Expected: PASS (all 4 tests)
```

- [ ] **Step 9: Commit**

```bash
git add lumino-api/src/
git commit -m "feat: add habit entries API and streak computation"
```

---

## Task 10: User Profile API

**Files:**
- Modify: `lumino-api/src/main/kotlin/com/lumino/api/user/UserController.kt`
- Create: `lumino-api/src/main/kotlin/com/lumino/api/user/UserService.kt`
- Create: `lumino-api/src/main/kotlin/com/lumino/api/user/dto/UpdateProfileRequest.kt`
- Create: `lumino-api/src/main/kotlin/com/lumino/api/user/dto/UserResponse.kt`

- [ ] **Step 1: Write DTOs**

```kotlin
// dto/UpdateProfileRequest.kt
package com.lumino.api.user.dto
data class UpdateProfileRequest(
    val displayName: String? = null,
    val locale: String? = null,
    val timezone: String? = null,
    val onboardingProfile: String? = null  // JSON string
)

// dto/UserResponse.kt
package com.lumino.api.user.dto
import com.lumino.api.user.User
import java.util.UUID
data class UserResponse(val id: UUID, val email: String?, val displayName: String?, val locale: String, val timezone: String, val onboardingProfile: String?) {
    companion object {
        fun from(u: User) = UserResponse(u.id, u.email, u.displayName, u.locale, u.timezone, u.onboardingProfile)
    }
}
```

- [ ] **Step 2: Write `UserService.kt`**

```kotlin
package com.lumino.api.user

import com.lumino.api.habit.HabitEntryRepository
import com.lumino.api.habit.HabitRepository
import com.lumino.api.task.TaskRepository
import com.lumino.api.user.dto.UpdateProfileRequest
import com.lumino.api.user.dto.UserResponse
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Instant

@Service
class UserService(
    private val userRepository: UserRepository,
    private val taskRepository: TaskRepository,
    private val habitRepository: HabitRepository
) {
    fun getProfile(user: User) = UserResponse.from(user)

    @Transactional
    fun updateProfile(user: User, request: UpdateProfileRequest): UserResponse {
        val updated = userRepository.findById(user.id).orElseThrow()
        request.displayName?.let {
            // Use reflection-free approach: create new User with updated field
            // Spring Data JPA update via query
            userRepository.updateDisplayName(user.id, it)
        }
        request.onboardingProfile?.let {
            userRepository.updateOnboardingProfile(user.id, it)
        }
        return UserResponse.from(userRepository.findById(user.id).orElseThrow())
    }

    @Transactional
    fun deleteAccount(user: User) {
        userRepository.softDelete(user.id, Instant.now())
    }

    fun exportCsv(user: User): String {
        val tasks = taskRepository.findAll().filter { it.user.id == user.id && it.deletedAt == null }
        val habits = habitRepository.findByUserIdAndArchivedAtIsNull(user.id)
        val sb = StringBuilder()
        sb.appendLine("# Tasks")
        sb.appendLine("id,title,startAt,completedAt")
        tasks.forEach { sb.appendLine("${it.id},${it.title},${it.startAt},${it.completedAt ?: ""}") }
        sb.appendLine()
        sb.appendLine("# Habits")
        sb.appendLine("id,title,type,targetValue")
        habits.forEach { sb.appendLine("${it.id},${it.title},${it.type},${it.targetValue}") }
        return sb.toString()
    }
}
```

- [ ] **Step 3: Add update queries to `UserRepository.kt`**

```kotlin
@Modifying
@Query("UPDATE User u SET u.displayName = :name WHERE u.id = :id")
fun updateDisplayName(id: UUID, name: String)

@Modifying
@Query("UPDATE User u SET u.onboardingProfile = :profile WHERE u.id = :id")
fun updateOnboardingProfile(id: UUID, profile: String)

@Modifying
@Query("UPDATE User u SET u.deletedAt = :deletedAt WHERE u.id = :id")
fun softDelete(id: UUID, deletedAt: Instant)
```

- [ ] **Step 4: Replace `UserController.kt` with full implementation**

```kotlin
package com.lumino.api.user

import com.lumino.api.common.ApiResponse
import com.lumino.api.common.CurrentUser
import com.lumino.api.user.dto.UpdateProfileRequest
import org.springframework.http.HttpHeaders
import org.springframework.http.MediaType
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/me")
class UserController(private val userService: UserService) {

    @GetMapping
    fun getProfile(@CurrentUser user: User) = ApiResponse.ok(userService.getProfile(user))

    @PutMapping
    fun updateProfile(@CurrentUser user: User, @RequestBody request: UpdateProfileRequest) =
        ApiResponse.ok(userService.updateProfile(user, request))

    @DeleteMapping
    fun deleteAccount(@CurrentUser user: User) {
        userService.deleteAccount(user)
    }

    @GetMapping("/export")
    fun exportData(@CurrentUser user: User): ResponseEntity<String> {
        val csv = userService.exportCsv(user)
        return ResponseEntity.ok()
            .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"lumino-export.csv\"")
            .contentType(MediaType.TEXT_PLAIN)
            .body(csv)
    }
}
```

- [ ] **Step 5: Run all tests**

```bash
./gradlew test
# Expected: all tests PASS
```

- [ ] **Step 6: Commit**

```bash
git add lumino-api/src/
git commit -m "feat: add user profile API (GET/PUT/DELETE/export)"
```

---

## Task 11: Google OAuth Endpoint

**Files:**
- Create: `lumino-api/src/main/kotlin/com/lumino/api/auth/GoogleOAuthService.kt`
- Modify: `lumino-api/src/main/kotlin/com/lumino/api/auth/AuthController.kt`
- Modify: `lumino-api/build.gradle.kts`

- [ ] **Step 1: Add Google auth library to `build.gradle.kts`**

```kotlin
implementation("com.google.auth:google-auth-library-oauth2-http:1.23.0")
```

- [ ] **Step 2: Write `GoogleOAuthService.kt`**

```kotlin
package com.lumino.api.auth

import com.google.auth.oauth2.TokenVerifier
import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Service

@Service
class GoogleOAuthService(
    @Value("\${google.client-id:}") private val clientId: String
) {
    fun verifyIdToken(idToken: String): GoogleUserInfo {
        val verifier = TokenVerifier.newBuilder().setAudience(clientId).build()
        val payload = verifier.verify(idToken)
        return GoogleUserInfo(
            googleId = payload.subject,
            email = payload["email"] as? String ?: throw IllegalArgumentException("No email in token"),
            displayName = payload["name"] as? String
        )
    }

    data class GoogleUserInfo(val googleId: String, val email: String, val displayName: String?)
}
```

- [ ] **Step 3: Add `POST /api/auth/google` to `AuthService.kt`**

Add this method to `AuthService`:

```kotlin
@Transactional
fun loginWithGoogle(request: GoogleAuthRequest): AuthResponse {
    val googleUser = googleOAuthService.verifyIdToken(request.idToken)
    val user = userRepository.findByEmail(googleUser.email)
        ?: userRepository.save(
            User(
                email = googleUser.email,
                displayName = googleUser.displayName,
                authProvider = "google"
            )
        )
    return issueTokens(user)
}
```

Also add `private val googleOAuthService: GoogleOAuthService` to the constructor.

- [ ] **Step 4: Add endpoint to `AuthController.kt`**

```kotlin
@PostMapping("/google")
fun googleLogin(@RequestBody request: GoogleAuthRequest) =
    ApiResponse.ok(authService.loginWithGoogle(request))
```

- [ ] **Step 5: Add `GOOGLE_CLIENT_ID` to `application.yml`**

```yaml
google:
  client-id: ${GOOGLE_CLIENT_ID:}
```

- [ ] **Step 6: Run all tests**

```bash
./gradlew test
# Expected: all tests PASS (Google endpoint only tested via integration manually)
```

- [ ] **Step 7: Commit**

```bash
git add lumino-api/
git commit -m "feat: add Google OAuth endpoint"
```

---

## Task 12: Final Wiring + Production Config

**Files:**
- Create: `lumino-api/.env.example`
- Create: `lumino-api/Dockerfile`
- Modify: `lumino-api/src/main/resources/application.yml`

- [ ] **Step 1: Write `.env.example`**

```bash
DATABASE_URL=jdbc:postgresql://localhost:5432/lumino
DATABASE_USERNAME=lumino
DATABASE_PASSWORD=lumino
JWT_SECRET=change-me-to-a-256-bit-base64-encoded-secret
GOOGLE_CLIENT_ID=your-google-client-id.apps.googleusercontent.com
PORT=8080
```

- [ ] **Step 2: Write `Dockerfile`**

```dockerfile
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY build/libs/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

- [ ] **Step 3: Run full test suite**

```bash
./gradlew test
# Expected: all tests PASS, zero failures
```

- [ ] **Step 4: Build the jar**

```bash
./gradlew bootJar
# Expected: BUILD SUCCESSFUL, jar in build/libs/
```

- [ ] **Step 5: Commit**

```bash
git add lumino-api/
git commit -m "feat: add Dockerfile and env example for production deployment"
```
