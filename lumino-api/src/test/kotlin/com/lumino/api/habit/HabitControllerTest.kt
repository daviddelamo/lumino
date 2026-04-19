package com.lumino.api.habit

import com.fasterxml.jackson.databind.ObjectMapper
import com.lumino.api.TestcontainersBase
import com.lumino.api.auth.AuthService
import com.lumino.api.auth.dto.RegisterRequest
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.http.MediaType
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.get
import org.springframework.test.web.servlet.post
import org.springframework.test.web.servlet.put

class HabitControllerTest : TestcontainersBase() {
    @Autowired lateinit var mockMvc: MockMvc
    @Autowired lateinit var authService: AuthService
    @Autowired lateinit var mapper: ObjectMapper
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
            content = """{"title":"Drink water","iconId":"water","color":"#5B6EF5","type":"count","targetValue":8.0,"unit":"glasses","frequencyRule":"{\"type\":\"daily\"}"}"""
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
            content = """{"title":"Archive me","iconId":"x","color":"#E57373","type":"bool","targetValue":1.0,"frequencyRule":"{\"type\":\"daily\"}"}"""
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

    @Test
    fun `cannot update archived habit returns 404`() {
        val result = mockMvc.post("/api/habits") {
            header("Authorization", "Bearer $token")
            contentType = MediaType.APPLICATION_JSON
            content = """{"title":"Soon archived","iconId":"x","color":"#E57373","type":"bool","targetValue":1.0,"frequencyRule":"{\"type\":\"daily\"}"}"""
        }.andReturn().response.contentAsString
        val habitId = mapper.readTree(result)["data"]["id"].asText()

        mockMvc.put("/api/habits/$habitId") {
            header("Authorization", "Bearer $token")
            contentType = MediaType.APPLICATION_JSON
            content = """{"archived":true}"""
        }.andExpect { status { isOk() } }

        mockMvc.put("/api/habits/$habitId") {
            header("Authorization", "Bearer $token")
            contentType = MediaType.APPLICATION_JSON
            content = """{"title":"Updated after archive"}"""
        }.andExpect {
            status { isNotFound() }
        }
    }

    @Test
    fun `cannot update another user's habit returns 403`() {
        val otherToken = authService.register(
            RegisterRequest("other-habit-${System.nanoTime()}@lumino.app", "secret123")
        ).accessToken

        val result = mockMvc.post("/api/habits") {
            header("Authorization", "Bearer $token")
            contentType = MediaType.APPLICATION_JSON
            content = """{"title":"My habit","iconId":"circle","color":"#E8823A","type":"bool","targetValue":1.0,"frequencyRule":"{\"type\":\"daily\"}"}"""
        }.andReturn().response.contentAsString
        val habitId = mapper.readTree(result)["data"]["id"].asText()

        mockMvc.put("/api/habits/$habitId") {
            header("Authorization", "Bearer $otherToken")
            contentType = MediaType.APPLICATION_JSON
            content = """{"title":"Stolen"}"""
        }.andExpect {
            status { isForbidden() }
        }
    }
}
