package com.lumino.api.user

import com.fasterxml.jackson.databind.ObjectMapper
import com.lumino.api.TestcontainersBase
import com.lumino.api.auth.AuthService
import com.lumino.api.auth.dto.RegisterRequest
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.http.MediaType
import org.springframework.test.web.servlet.*

class UserControllerTest : TestcontainersBase() {
    @Autowired lateinit var mockMvc: MockMvc
    @Autowired lateinit var authService: AuthService
    @Autowired lateinit var mapper: ObjectMapper
    private lateinit var token: String

    @BeforeEach
    fun setup() {
        token = authService.register(RegisterRequest("me-${System.nanoTime()}@lumino.app", "secret123")).accessToken
    }

    @Test
    fun `get profile returns user data`() {
        mockMvc.get("/api/me") {
            header("Authorization", "Bearer $token")
        }.andExpect {
            status { isOk() }
            jsonPath("$.data.email") { exists() }
            jsonPath("$.data.locale") { value("en") }
        }
    }

    @Test
    fun `update profile persists changes`() {
        mockMvc.put("/api/me") {
            header("Authorization", "Bearer $token")
            contentType = MediaType.APPLICATION_JSON
            content = """{"displayName":"Test User","locale":"es","timezone":"Europe/Madrid"}"""
        }.andExpect {
            status { isOk() }
            jsonPath("$.data.displayName") { value("Test User") }
            jsonPath("$.data.locale") { value("es") }
            jsonPath("$.data.timezone") { value("Europe/Madrid") }
        }

        mockMvc.get("/api/me") {
            header("Authorization", "Bearer $token")
        }.andExpect {
            jsonPath("$.data.displayName") { value("Test User") }
        }
    }

    @Test
    fun `delete account returns 204 then subsequent request returns 401`() {
        mockMvc.delete("/api/me") {
            header("Authorization", "Bearer $token")
        }.andExpect { status { isNoContent() } }

        // The deleted user's token is still valid JWT-wise, but the user.isEnabled() returns false
        // Spring Security should reject the request
        mockMvc.get("/api/me") {
            header("Authorization", "Bearer $token")
        }.andExpect {
            status { isUnauthorized() }
        }
    }
}
