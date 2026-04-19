package com.lumino.api.task

import com.fasterxml.jackson.databind.ObjectMapper
import com.lumino.api.TestcontainersBase
import com.lumino.api.auth.AuthService
import com.lumino.api.auth.dto.RegisterRequest
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.http.MediaType
import org.springframework.test.web.servlet.*

class TaskControllerTest : TestcontainersBase() {
    @Autowired lateinit var mockMvc: MockMvc
    @Autowired lateinit var authService: AuthService
    @Autowired lateinit var mapper: ObjectMapper
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

    @Test
    fun `cannot update another user's task returns 403`() {
        val otherToken = authService.register(
            RegisterRequest("other-${System.nanoTime()}@lumino.app", "secret123")
        ).accessToken

        val result = mockMvc.post("/api/tasks") {
            header("Authorization", "Bearer $token")
            contentType = MediaType.APPLICATION_JSON
            content = """{"title":"My task","iconId":"circle","color":"#E8823A","startAt":"2026-04-17T10:00:00Z"}"""
        }.andReturn().response.contentAsString

        val taskId = mapper.readTree(result)["data"]["id"].asText()

        mockMvc.put("/api/tasks/$taskId") {
            header("Authorization", "Bearer $otherToken")
            contentType = MediaType.APPLICATION_JSON
            content = """{"title":"Stolen"}"""
        }.andExpect {
            status { isForbidden() }
        }
    }

    @Test
    fun `cannot delete another user's task returns 403`() {
        val otherToken = authService.register(
            RegisterRequest("other2-${System.nanoTime()}@lumino.app", "secret123")
        ).accessToken

        val result = mockMvc.post("/api/tasks") {
            header("Authorization", "Bearer $token")
            contentType = MediaType.APPLICATION_JSON
            content = """{"title":"Protected","iconId":"circle","color":"#E8823A","startAt":"2026-04-17T11:00:00Z"}"""
        }.andReturn().response.contentAsString

        val taskId = mapper.readTree(result)["data"]["id"].asText()

        mockMvc.delete("/api/tasks/$taskId") {
            header("Authorization", "Bearer $otherToken")
        }.andExpect {
            status { isForbidden() }
        }
    }
}
