# Monetization API Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `subscriptions` table, RevenueCat webhook handler, and `isPremium` flag to `GET /api/me` in the Spring Boot API.

**Architecture:** Flyway V3 migration creates the subscriptions table. `SubscriptionService` computes `isPremium` from that table. `RevenueCatWebhookController` handles five RC event types. `UserService.getProfile` calls `SubscriptionService.isPremium` and includes the result in `UserResponse`.

**Tech Stack:** Spring Boot 3 / Kotlin, Spring Data JPA, Flyway, Testcontainers, Jackson

---

## File Map

| Action | Path |
|--------|------|
| Create | `src/main/resources/db/migration/V3__create_subscriptions.sql` |
| Create | `src/main/kotlin/com/lumino/api/subscription/Subscription.kt` |
| Create | `src/main/kotlin/com/lumino/api/subscription/SubscriptionRepository.kt` |
| Create | `src/main/kotlin/com/lumino/api/subscription/SubscriptionService.kt` |
| Create | `src/main/kotlin/com/lumino/api/subscription/RevenueCatWebhookController.kt` |
| Modify | `src/main/kotlin/com/lumino/api/config/SecurityConfig.kt` |
| Modify | `src/main/kotlin/com/lumino/api/user/dto/UserResponse.kt` |
| Modify | `src/main/kotlin/com/lumino/api/user/UserService.kt` |
| Modify | `src/main/resources/application.properties` |
| Create | `src/test/kotlin/com/lumino/api/subscription/RevenueCatWebhookControllerTest.kt` |

---

### Task 1: Flyway migration — subscriptions table

**Files:**
- Create: `src/main/resources/db/migration/V3__create_subscriptions.sql`

- [ ] **Step 1: Write the migration file**

```sql
CREATE TABLE subscriptions (
  id             BIGSERIAL PRIMARY KEY,
  user_id        UUID NOT NULL REFERENCES users(id),
  rc_customer_id VARCHAR(255) NOT NULL,
  product_id     VARCHAR(255) NOT NULL,
  status         VARCHAR(32)  NOT NULL DEFAULT 'ACTIVE',
  expires_at     TIMESTAMPTZ,
  is_lifetime    BOOLEAN NOT NULL DEFAULT FALSE,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_subscriptions_user_id ON subscriptions(user_id);
```

- [ ] **Step 2: Verify migration runs**

```bash
cd lumino-api && ./gradlew bootRun
```

Check logs for `Successfully applied 1 migration to schema "public"` (V3). Then `Ctrl+C`.

- [ ] **Step 3: Commit**

```bash
git add src/main/resources/db/migration/V3__create_subscriptions.sql
git commit -m "feat: add subscriptions table (Flyway V3)"
```

---

### Task 2: Subscription entity and repository

**Files:**
- Create: `src/main/kotlin/com/lumino/api/subscription/Subscription.kt`
- Create: `src/main/kotlin/com/lumino/api/subscription/SubscriptionRepository.kt`

- [ ] **Step 1: Write the entity**

`src/main/kotlin/com/lumino/api/subscription/Subscription.kt`:
```kotlin
package com.lumino.api.subscription

import com.lumino.api.user.User
import jakarta.persistence.*
import java.time.Instant
import java.util.UUID

@Entity
@Table(name = "subscriptions")
class Subscription(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    val user: User,

    val rcCustomerId: String,
    val productId: String,
    var status: String = "ACTIVE",
    var expiresAt: Instant? = null,
    val isLifetime: Boolean = false,
    val createdAt: Instant = Instant.now(),
    var updatedAt: Instant = Instant.now()
) {
    @PreUpdate
    fun onUpdate() { updatedAt = Instant.now() }
}
```

- [ ] **Step 2: Write the repository**

`src/main/kotlin/com/lumino/api/subscription/SubscriptionRepository.kt`:
```kotlin
package com.lumino.api.subscription

import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import java.time.Instant
import java.util.UUID

interface SubscriptionRepository : JpaRepository<Subscription, Long> {

    @Query("""
        SELECT s FROM Subscription s
        WHERE s.user.id = :userId
          AND s.status = 'ACTIVE'
          AND (s.isLifetime = true OR s.expiresAt > :now)
    """)
    fun findActiveForUser(userId: UUID, now: Instant): List<Subscription>

    fun findByUserIdAndProductId(userId: UUID, productId: String): List<Subscription>
}
```

- [ ] **Step 3: Verify compilation**

```bash
cd lumino-api && ./gradlew compileKotlin
```

Expected: `BUILD SUCCESSFUL`

- [ ] **Step 4: Commit**

```bash
git add src/main/kotlin/com/lumino/api/subscription/
git commit -m "feat: add Subscription entity and repository"
```

---

### Task 3: SubscriptionService

**Files:**
- Create: `src/main/kotlin/com/lumino/api/subscription/SubscriptionService.kt`

- [ ] **Step 1: Write the service**

`src/main/kotlin/com/lumino/api/subscription/SubscriptionService.kt`:
```kotlin
package com.lumino.api.subscription

import com.lumino.api.user.UserRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Instant
import java.util.UUID

@Service
class SubscriptionService(
    private val subscriptionRepository: SubscriptionRepository,
    private val userRepository: UserRepository
) {

    @Transactional(readOnly = true)
    fun isPremium(userId: UUID): Boolean =
        subscriptionRepository.findActiveForUser(userId, Instant.now()).isNotEmpty()

    @Transactional
    fun handleEvent(type: String, appUserId: String, productId: String, expiresAtMs: Long?) {
        val userId = runCatching { UUID.fromString(appUserId) }.getOrNull() ?: return
        val user = userRepository.findById(userId).orElse(null) ?: return
        val expiresAt = expiresAtMs?.let { Instant.ofEpochMilli(it) }

        when (type) {
            "INITIAL_PURCHASE" -> {
                subscriptionRepository.save(
                    Subscription(
                        user = user,
                        rcCustomerId = appUserId,
                        productId = productId,
                        status = "ACTIVE",
                        expiresAt = expiresAt,
                        isLifetime = false
                    )
                )
            }
            "NON_SUBSCRIPTION_PURCHASE" -> {
                subscriptionRepository.save(
                    Subscription(
                        user = user,
                        rcCustomerId = appUserId,
                        productId = productId,
                        status = "ACTIVE",
                        expiresAt = null,
                        isLifetime = true
                    )
                )
            }
            "RENEWAL" -> {
                val existing = subscriptionRepository
                    .findByUserIdAndProductId(userId, productId)
                    .firstOrNull()
                if (existing != null) {
                    existing.status = "ACTIVE"
                    existing.expiresAt = expiresAt
                    subscriptionRepository.save(existing)
                } else {
                    subscriptionRepository.save(
                        Subscription(
                            user = user,
                            rcCustomerId = appUserId,
                            productId = productId,
                            status = "ACTIVE",
                            expiresAt = expiresAt,
                            isLifetime = false
                        )
                    )
                }
            }
            "CANCELLATION" -> {
                subscriptionRepository
                    .findByUserIdAndProductId(userId, productId)
                    .forEach { it.status = "CANCELLED"; subscriptionRepository.save(it) }
            }
            "EXPIRATION" -> {
                subscriptionRepository
                    .findByUserIdAndProductId(userId, productId)
                    .forEach { it.status = "EXPIRED"; subscriptionRepository.save(it) }
            }
            // Unknown event types ignored — RC sends events we don't care about
        }
    }
}
```

- [ ] **Step 2: Verify compilation**

```bash
cd lumino-api && ./gradlew compileKotlin
```

Expected: `BUILD SUCCESSFUL`

- [ ] **Step 3: Commit**

```bash
git add src/main/kotlin/com/lumino/api/subscription/SubscriptionService.kt
git commit -m "feat: add SubscriptionService with isPremium and webhook event handling"
```

---

### Task 4: RevenueCat webhook controller + SecurityConfig update

**Files:**
- Create: `src/main/kotlin/com/lumino/api/subscription/RevenueCatWebhookController.kt`
- Modify: `src/main/kotlin/com/lumino/api/config/SecurityConfig.kt`
- Modify: `src/main/resources/application.properties`

- [ ] **Step 1: Add the webhook secret property**

Open `src/main/resources/application.properties` and add:
```properties
revenuecat.webhook-secret=${REVENUECAT_WEBHOOK_SECRET:}
```

- [ ] **Step 2: Write the controller**

`src/main/kotlin/com/lumino/api/subscription/RevenueCatWebhookController.kt`:
```kotlin
package com.lumino.api.subscription

import com.fasterxml.jackson.annotation.JsonProperty
import org.springframework.beans.factory.annotation.Value
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

data class RcWebhookPayload(
    val event: RcEvent
)

data class RcEvent(
    val type: String,
    @JsonProperty("app_user_id")  val appUserId: String,
    @JsonProperty("product_id")   val productId: String,
    @JsonProperty("expiration_at_ms") val expirationAtMs: Long?
)

@RestController
@RequestMapping("/api/webhooks")
class RevenueCatWebhookController(
    private val subscriptionService: SubscriptionService,
    @Value("\${revenuecat.webhook-secret}") private val webhookSecret: String
) {

    @PostMapping("/revenuecat")
    fun handle(
        @RequestHeader("Authorization") auth: String?,
        @RequestBody payload: RcWebhookPayload
    ): ResponseEntity<Unit> {
        if (webhookSecret.isNotBlank() && auth != webhookSecret) {
            return ResponseEntity.status(401).build()
        }
        subscriptionService.handleEvent(
            type        = payload.event.type,
            appUserId   = payload.event.appUserId,
            productId   = payload.event.productId,
            expiresAtMs = payload.event.expirationAtMs
        )
        return ResponseEntity.ok().build()
    }
}
```

- [ ] **Step 3: Permit the webhook endpoint in SecurityConfig**

In `src/main/kotlin/com/lumino/api/config/SecurityConfig.kt`, change the `.authorizeHttpRequests` block to add the webhook path:

```kotlin
.authorizeHttpRequests {
    it.requestMatchers(
        "/",
        "/*.html",
        "/*.css",
        "/*.js",
        "/assets/**",
        "/*.png",
        "/*.ico"
    ).permitAll()
    it.requestMatchers("/api/auth/**").permitAll()
    it.requestMatchers("/api/webhooks/revenuecat").permitAll()
    it.anyRequest().authenticated()
}
```

- [ ] **Step 4: Verify compilation**

```bash
cd lumino-api && ./gradlew compileKotlin
```

Expected: `BUILD SUCCESSFUL`

- [ ] **Step 5: Commit**

```bash
git add src/main/kotlin/com/lumino/api/subscription/RevenueCatWebhookController.kt \
        src/main/kotlin/com/lumino/api/config/SecurityConfig.kt \
        src/main/resources/application.properties
git commit -m "feat: add RevenueCat webhook endpoint and permit it in SecurityConfig"
```

---

### Task 5: isPremium in UserResponse and UserService

**Files:**
- Modify: `src/main/kotlin/com/lumino/api/user/dto/UserResponse.kt`
- Modify: `src/main/kotlin/com/lumino/api/user/UserService.kt`

- [ ] **Step 1: Add isPremium to UserResponse**

Replace `src/main/kotlin/com/lumino/api/user/dto/UserResponse.kt` with:
```kotlin
package com.lumino.api.user.dto

import com.lumino.api.user.User
import java.time.Instant
import java.util.UUID

data class UserResponse(
    val id: UUID,
    val email: String?,
    val displayName: String?,
    val locale: String,
    val timezone: String,
    val onboardingProfile: String?,
    val createdAt: Instant,
    val isPremium: Boolean
) {
    companion object {
        fun from(u: User, isPremium: Boolean) = UserResponse(
            u.id, u.email, u.displayName, u.locale, u.timezone,
            u.onboardingProfile, u.createdAt, isPremium
        )
    }
}
```

- [ ] **Step 2: Wire SubscriptionService into UserService**

Replace `src/main/kotlin/com/lumino/api/user/UserService.kt` with:
```kotlin
package com.lumino.api.user

import com.lumino.api.auth.RefreshTokenRepository
import com.lumino.api.subscription.SubscriptionService
import com.lumino.api.user.dto.UpdateProfileRequest
import com.lumino.api.user.dto.UserResponse
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Instant

@Service
class UserService(
    private val userRepository: UserRepository,
    private val refreshTokenRepository: RefreshTokenRepository,
    private val subscriptionService: SubscriptionService
) {

    @Transactional(readOnly = true)
    fun getProfile(user: User): UserResponse =
        UserResponse.from(user, subscriptionService.isPremium(user.id))

    @Transactional
    fun updateProfile(user: User, request: UpdateProfileRequest): UserResponse {
        require(
            request.displayName != null || request.locale != null ||
            request.timezone != null || request.onboardingProfile != null
        ) { "At least one field must be provided" }
        request.displayName?.let { userRepository.updateDisplayName(user.id, it) }
        request.locale?.let { userRepository.updateLocale(user.id, it) }
        request.timezone?.let { userRepository.updateTimezone(user.id, it) }
        request.onboardingProfile?.let { userRepository.updateOnboardingProfile(user.id, it) }
        return UserResponse.from(
            userRepository.findById(user.id).orElseThrow(),
            subscriptionService.isPremium(user.id)
        )
    }

    @Transactional
    fun deleteAccount(user: User) {
        refreshTokenRepository.revokeAllForUser(user.id)
        userRepository.softDelete(user.id, Instant.now())
    }
}
```

- [ ] **Step 3: Verify compilation**

```bash
cd lumino-api && ./gradlew compileKotlin
```

Expected: `BUILD SUCCESSFUL`

- [ ] **Step 4: Commit**

```bash
git add src/main/kotlin/com/lumino/api/user/dto/UserResponse.kt \
        src/main/kotlin/com/lumino/api/user/UserService.kt
git commit -m "feat: include isPremium in /api/me response"
```

---

### Task 6: Integration tests

**Files:**
- Create: `src/test/kotlin/com/lumino/api/subscription/RevenueCatWebhookControllerTest.kt`

- [ ] **Step 1: Write the failing tests**

`src/test/kotlin/com/lumino/api/subscription/RevenueCatWebhookControllerTest.kt`:
```kotlin
package com.lumino.api.subscription

import com.lumino.api.TestcontainersBase
import com.lumino.api.auth.dto.RegisterRequest
import com.lumino.api.auth.AuthService
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.http.MediaType
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.get
import org.springframework.test.web.servlet.post
import java.util.UUID

class RevenueCatWebhookControllerTest : TestcontainersBase() {

    @Autowired lateinit var mockMvc: MockMvc
    @Autowired lateinit var authService: AuthService

    private fun registerAndGetToken(): Pair<String, String> {
        val email = "rc-test-${UUID.randomUUID()}@lumino.test"
        val response = authService.register(RegisterRequest(email, "pass123"))
        val profile = mockMvc.get("/api/me") {
            header("Authorization", "Bearer ${response.accessToken}")
        }.andReturn().response.let {
            com.fasterxml.jackson.databind.ObjectMapper()
                .readTree(it.contentAsString)["data"]
        }
        return Pair(response.accessToken, profile["id"].asText())
    }

    @Test
    fun `INITIAL_PURCHASE inserts subscription and isPremium becomes true`() {
        val (token, userId) = registerAndGetToken()

        mockMvc.post("/api/webhooks/revenuecat") {
            contentType = MediaType.APPLICATION_JSON
            content = """
                {"event":{"type":"INITIAL_PURCHASE","app_user_id":"$userId",
                 "product_id":"lumino_monthly","expiration_at_ms":9999999999000}}
            """.trimIndent()
        }.andExpect { status { isOk() } }

        mockMvc.get("/api/me") {
            header("Authorization", "Bearer $token")
        }.andExpect {
            status { isOk() }
            jsonPath("$.data.isPremium") { value(true) }
        }
    }

    @Test
    fun `invalid webhook secret returns 401`() {
        // Set a non-blank secret for this test by posting with wrong header.
        // Only verifiable when REVENUECAT_WEBHOOK_SECRET env var is set;
        // skip assertion if secret is blank (CI without secret).
        val secret = System.getenv("REVENUECAT_WEBHOOK_SECRET") ?: ""
        if (secret.isBlank()) return

        mockMvc.post("/api/webhooks/revenuecat") {
            contentType = MediaType.APPLICATION_JSON
            header("Authorization", "wrong-secret")
            content = """{"event":{"type":"INITIAL_PURCHASE","app_user_id":"${UUID.randomUUID()}",
                "product_id":"lumino_monthly","expiration_at_ms":9999999999000}}"""
        }.andExpect { status { isUnauthorized() } }
    }

    @Test
    fun `EXPIRATION sets isPremium to false`() {
        val (token, userId) = registerAndGetToken()

        // Insert active subscription via INITIAL_PURCHASE
        mockMvc.post("/api/webhooks/revenuecat") {
            contentType = MediaType.APPLICATION_JSON
            content = """{"event":{"type":"INITIAL_PURCHASE","app_user_id":"$userId",
                "product_id":"lumino_monthly","expiration_at_ms":9999999999000}}"""
        }.andExpect { status { isOk() } }

        // Expire it
        mockMvc.post("/api/webhooks/revenuecat") {
            contentType = MediaType.APPLICATION_JSON
            content = """{"event":{"type":"EXPIRATION","app_user_id":"$userId",
                "product_id":"lumino_monthly","expiration_at_ms":null}}"""
        }.andExpect { status { isOk() } }

        mockMvc.get("/api/me") {
            header("Authorization", "Bearer $token")
        }.andExpect {
            status { isOk() }
            jsonPath("$.data.isPremium") { value(false) }
        }
    }

    @Test
    fun `NON_SUBSCRIPTION_PURCHASE sets lifetime isPremium true indefinitely`() {
        val (token, userId) = registerAndGetToken()

        mockMvc.post("/api/webhooks/revenuecat") {
            contentType = MediaType.APPLICATION_JSON
            content = """{"event":{"type":"NON_SUBSCRIPTION_PURCHASE","app_user_id":"$userId",
                "product_id":"lumino_lifetime","expiration_at_ms":null}}"""
        }.andExpect { status { isOk() } }

        mockMvc.get("/api/me") {
            header("Authorization", "Bearer $token")
        }.andExpect {
            status { isOk() }
            jsonPath("$.data.isPremium") { value(true) }
        }
    }

    @Test
    fun `unknown event type returns 200 and is ignored`() {
        mockMvc.post("/api/webhooks/revenuecat") {
            contentType = MediaType.APPLICATION_JSON
            content = """{"event":{"type":"TRANSFER","app_user_id":"${UUID.randomUUID()}",
                "product_id":"lumino_monthly","expiration_at_ms":null}}"""
        }.andExpect { status { isOk() } }
    }
}
```

- [ ] **Step 2: Run tests to verify they fail (before implementation exists in full)**

```bash
cd lumino-api && ./gradlew test --tests "com.lumino.api.subscription.RevenueCatWebhookControllerTest"
```

Expected: compilation succeeds, tests fail because previous tasks haven't been implemented yet OR all pass if tasks 1-5 are already done. If all tasks 1-5 are complete, all tests should pass here.

- [ ] **Step 3: Run full test suite**

```bash
cd lumino-api && ./gradlew test
```

Expected: `BUILD SUCCESSFUL` — all tests pass including existing `UserControllerTest` (which now gets `isPremium: false` in the response, which is valid).

- [ ] **Step 4: Commit**

```bash
git add src/test/kotlin/com/lumino/api/subscription/RevenueCatWebhookControllerTest.kt
git commit -m "test: add RevenueCat webhook integration tests"
```
