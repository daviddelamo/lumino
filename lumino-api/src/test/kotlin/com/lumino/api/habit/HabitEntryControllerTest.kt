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

class HabitEntryControllerTest : TestcontainersBase() {
    @Autowired lateinit var mockMvc: MockMvc
    @Autowired lateinit var authService: AuthService
    @Autowired lateinit var mapper: ObjectMapper
    private lateinit var token: String
    private lateinit var habitId: String

    @BeforeEach
    fun setup() {
        token = authService.register(RegisterRequest("entry-${System.nanoTime()}@lumino.app", "secret123")).accessToken
        val result = mockMvc.post("/api/habits") {
            header("Authorization", "Bearer $token")
            contentType = MediaType.APPLICATION_JSON
            content = """{"title":"Meditate","iconId":"yoga","color":"#E8823A","type":"bool","targetValue":1.0,"frequencyRule":"{\"type\":\"daily\"}"}"""
        }.andReturn().response.contentAsString
        habitId = mapper.readTree(result)["data"]["id"].asText()
    }

    @Test
    fun `log habit entry and retrieve it`() {
        mockMvc.post("/api/habits/$habitId/entries") {
            header("Authorization", "Bearer $token")
            contentType = MediaType.APPLICATION_JSON
            content = """{"entryDate":"2026-04-17","value":1.0}"""
        }.andExpect {
            status { isOk() }
            jsonPath("$.data.value") { value(1.0) }
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
        listOf("2026-04-15", "2026-04-16", "2026-04-17").forEach { date ->
            mockMvc.post("/api/habits/$habitId/entries") {
                header("Authorization", "Bearer $token")
                contentType = MediaType.APPLICATION_JSON
                content = """{"entryDate":"$date","value":1.0}"""
            }.andExpect { status { isOk() } }
        }

        mockMvc.get("/api/habits/$habitId/streak") {
            header("Authorization", "Bearer $token")
        }.andExpect {
            status { isOk() }
            jsonPath("$.data.currentStreak") { value(3) }
            jsonPath("$.data.longestStreak") { value(3) }
        }
    }

    @Test
    fun `logging entry twice on same date updates the existing entry`() {
        mockMvc.post("/api/habits/$habitId/entries") {
            header("Authorization", "Bearer $token")
            contentType = MediaType.APPLICATION_JSON
            content = """{"entryDate":"2026-04-17","value":1.0}"""
        }
        mockMvc.post("/api/habits/$habitId/entries") {
            header("Authorization", "Bearer $token")
            contentType = MediaType.APPLICATION_JSON
            content = """{"entryDate":"2026-04-17","value":2.0}"""
        }.andExpect {
            status { isOk() }
            jsonPath("$.data.value") { value(2.0) }
        }

        mockMvc.get("/api/habits/$habitId/entries?from=2026-04-17&to=2026-04-17") {
            header("Authorization", "Bearer $token")
        }.andExpect {
            status { isOk() }
            jsonPath("$.data.length()") { value(1) }
        }
    }

    @Test
    fun `streak with gap returns correct currentStreak`() {
        // Log Apr 16 and Apr 17 (current streak=2), but NOT Apr 15
        // Then log Apr 13 and Apr 14 (older run=2, shouldn't affect current)
        listOf("2026-04-13", "2026-04-14", "2026-04-16", "2026-04-17").forEach { date ->
            mockMvc.post("/api/habits/$habitId/entries") {
                header("Authorization", "Bearer $token")
                contentType = MediaType.APPLICATION_JSON
                content = """{"entryDate":"$date","value":1.0}"""
            }.andExpect { status { isOk() } }
        }

        mockMvc.get("/api/habits/$habitId/streak") {
            header("Authorization", "Bearer $token")
        }.andExpect {
            status { isOk() }
            jsonPath("$.data.currentStreak") { value(2) }
            jsonPath("$.data.longestStreak") { value(2) }
        }
    }

    @Test
    fun `streak with no entries returns zero`() {
        mockMvc.get("/api/habits/$habitId/streak") {
            header("Authorization", "Bearer $token")
        }.andExpect {
            status { isOk() }
            jsonPath("$.data.currentStreak") { value(0) }
            jsonPath("$.data.longestStreak") { value(0) }
        }
    }

    @Test
    fun `cannot log entry for another user's habit returns 403`() {
        val otherToken = authService.register(
            RegisterRequest("entry-other-${System.nanoTime()}@lumino.app", "secret123")
        ).accessToken

        mockMvc.post("/api/habits/$habitId/entries") {
            header("Authorization", "Bearer $otherToken")
            contentType = MediaType.APPLICATION_JSON
            content = """{"entryDate":"2026-04-17","value":1.0}"""
        }.andExpect {
            status { isForbidden() }
        }
    }
}
