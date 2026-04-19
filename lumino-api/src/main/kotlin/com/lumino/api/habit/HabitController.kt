package com.lumino.api.habit

import com.lumino.api.common.ApiResponse
import com.lumino.api.common.CurrentUser
import com.lumino.api.habit.dto.CreateHabitRequest
import com.lumino.api.habit.dto.LogEntryRequest
import com.lumino.api.habit.dto.UpdateHabitRequest
import com.lumino.api.user.User
import jakarta.validation.Valid
import org.springframework.format.annotation.DateTimeFormat
import org.springframework.web.bind.annotation.*
import java.time.LocalDate
import java.util.UUID

@RestController
@RequestMapping("/api/habits")
class HabitController(private val habitService: HabitService) {

    @GetMapping
    fun getHabits(@CurrentUser user: User) =
        ApiResponse.ok(habitService.getHabits(user))

    @PostMapping
    fun createHabit(@CurrentUser user: User, @Valid @RequestBody request: CreateHabitRequest) =
        ApiResponse.ok(habitService.createHabit(user, request))

    @PutMapping("/{id}")
    fun updateHabit(
        @CurrentUser user: User,
        @PathVariable id: UUID,
        @Valid @RequestBody request: UpdateHabitRequest
    ) = ApiResponse.ok(habitService.updateHabit(user, id, request))

    @PostMapping("/{id}/entries")
    fun logEntry(
        @CurrentUser user: User,
        @PathVariable id: UUID,
        @Valid @RequestBody request: LogEntryRequest
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
}
