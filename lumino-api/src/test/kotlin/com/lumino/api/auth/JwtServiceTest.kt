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
