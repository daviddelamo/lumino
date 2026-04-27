package com.lumino.api.subscription

import com.lumino.api.TestcontainersBase
import com.lumino.api.auth.AuthService
import com.lumino.api.auth.dto.RegisterRequest
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.http.MediaType
import org.springframework.test.context.TestPropertySource
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.get
import org.springframework.test.web.servlet.post
import java.util.UUID

@TestPropertySource(properties = ["revenuecat.webhook-secret=test-webhook-secret"])
class RevenueCatWebhookControllerTest : TestcontainersBase() {

    private val secret = "test-webhook-secret"

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

    private fun postWebhook(body: String) = mockMvc.post("/api/webhooks/revenuecat") {
        contentType = MediaType.APPLICATION_JSON
        header("Authorization", secret)
        content = body
    }

    @Test
    fun `INITIAL_PURCHASE inserts subscription and isPremium becomes true`() {
        val (token, userId) = registerAndGetToken()

        postWebhook("""{"event":{"type":"INITIAL_PURCHASE","app_user_id":"$userId","product_id":"lumino_monthly","expiration_at_ms":9999999999000}}""")
            .andExpect { status { isOk() } }

        mockMvc.get("/api/me") {
            header("Authorization", "Bearer $token")
        }.andExpect {
            status { isOk() }
            jsonPath("$.data.isPremium") { value(true) }
        }
    }

    @Test
    fun `invalid webhook secret returns 401`() {
        mockMvc.post("/api/webhooks/revenuecat") {
            contentType = MediaType.APPLICATION_JSON
            header("Authorization", "wrong-secret")
            content = """{"event":{"type":"INITIAL_PURCHASE","app_user_id":"${UUID.randomUUID()}","product_id":"lumino_monthly","expiration_at_ms":9999999999000}}"""
        }.andExpect { status { isUnauthorized() } }
    }

    @Test
    fun `missing Authorization header returns 401`() {
        mockMvc.post("/api/webhooks/revenuecat") {
            contentType = MediaType.APPLICATION_JSON
            content = """{"event":{"type":"INITIAL_PURCHASE","app_user_id":"${UUID.randomUUID()}","product_id":"lumino_monthly","expiration_at_ms":9999999999000}}"""
        }.andExpect { status { isUnauthorized() } }
    }

    @Test
    fun `EXPIRATION sets isPremium to false`() {
        val (token, userId) = registerAndGetToken()

        postWebhook("""{"event":{"type":"INITIAL_PURCHASE","app_user_id":"$userId","product_id":"lumino_monthly","expiration_at_ms":9999999999000}}""")
            .andExpect { status { isOk() } }

        postWebhook("""{"event":{"type":"EXPIRATION","app_user_id":"$userId","product_id":"lumino_monthly","expiration_at_ms":null}}""")
            .andExpect { status { isOk() } }

        mockMvc.get("/api/me") {
            header("Authorization", "Bearer $token")
        }.andExpect {
            status { isOk() }
            jsonPath("$.data.isPremium") { value(false) }
        }
    }

    @Test
    fun `RENEWAL updates expiry and keeps isPremium true`() {
        val (token, userId) = registerAndGetToken()

        postWebhook("""{"event":{"type":"INITIAL_PURCHASE","app_user_id":"$userId","product_id":"lumino_monthly","expiration_at_ms":9999999999000}}""")
            .andExpect { status { isOk() } }

        postWebhook("""{"event":{"type":"RENEWAL","app_user_id":"$userId","product_id":"lumino_monthly","expiration_at_ms":9999999999999}}""")
            .andExpect { status { isOk() } }

        mockMvc.get("/api/me") {
            header("Authorization", "Bearer $token")
        }.andExpect {
            status { isOk() }
            jsonPath("$.data.isPremium") { value(true) }
        }
    }

    @Test
    fun `CANCELLATION sets isPremium to false`() {
        val (token, userId) = registerAndGetToken()

        postWebhook("""{"event":{"type":"INITIAL_PURCHASE","app_user_id":"$userId","product_id":"lumino_monthly","expiration_at_ms":9999999999000}}""")
            .andExpect { status { isOk() } }

        postWebhook("""{"event":{"type":"CANCELLATION","app_user_id":"$userId","product_id":"lumino_monthly","expiration_at_ms":null}}""")
            .andExpect { status { isOk() } }

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

        postWebhook("""{"event":{"type":"NON_SUBSCRIPTION_PURCHASE","app_user_id":"$userId","product_id":"lumino_lifetime","expiration_at_ms":null}}""")
            .andExpect { status { isOk() } }

        mockMvc.get("/api/me") {
            header("Authorization", "Bearer $token")
        }.andExpect {
            status { isOk() }
            jsonPath("$.data.isPremium") { value(true) }
        }
    }

    @Test
    fun `unknown event type returns 200 and is ignored`() {
        postWebhook("""{"event":{"type":"TRANSFER","app_user_id":"${UUID.randomUUID()}","product_id":"lumino_monthly","expiration_at_ms":null}}""")
            .andExpect { status { isOk() } }
    }
}
