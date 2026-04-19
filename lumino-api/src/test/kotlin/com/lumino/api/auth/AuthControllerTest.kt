package com.lumino.api.auth

import com.lumino.api.TestcontainersBase
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.http.MediaType
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.get
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

        val token = com.fasterxml.jackson.databind.ObjectMapper()
            .readTree(reg)["data"]["accessToken"].asText()

        mockMvc.get("/api/me") {
            header("Authorization", "Bearer $token")
        }.andExpect { status { isOk() } }
    }
}
