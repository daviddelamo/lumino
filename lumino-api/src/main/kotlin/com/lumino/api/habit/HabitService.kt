package com.lumino.api.habit

import com.lumino.api.habit.dto.CreateHabitRequest
import com.lumino.api.habit.dto.HabitEntryResponse
import com.lumino.api.habit.dto.HabitResponse
import com.lumino.api.habit.dto.LogEntryRequest
import com.lumino.api.habit.dto.StreakResponse
import com.lumino.api.habit.dto.UpdateHabitRequest
import com.lumino.api.user.User
import org.springframework.security.access.AccessDeniedException
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Instant
import java.time.LocalDate
import java.time.LocalTime
import java.util.UUID

@Service
class HabitService(
    private val habitRepository: HabitRepository,
    private val habitEntryRepository: HabitEntryRepository
) {

    @Transactional(readOnly = true)
    fun getHabits(user: User): List<HabitResponse> =
        habitRepository.findByUserIdAndArchivedAtIsNull(user.id).map { HabitResponse.from(it) }

    @Transactional
    fun createHabit(user: User, request: CreateHabitRequest): HabitResponse {
        val habit = habitRepository.save(
            Habit(
                user = user,
                title = request.title,
                iconId = request.iconId,
                color = request.color,
                type = request.type,
                targetValue = request.targetValue,
                unit = request.unit,
                frequencyRule = request.frequencyRule,
                reminderTime = request.reminderTime?.let {
                    try { LocalTime.parse(it) } catch (e: Exception) { throw IllegalArgumentException("Invalid reminderTime format, expected HH:mm") }
                }
            )
        )
        return HabitResponse.from(habit)
    }

    @Transactional
    fun updateHabit(user: User, habitId: UUID, request: UpdateHabitRequest): HabitResponse {
        val habit = habitRepository.findById(habitId).orElseThrow { NoSuchElementException("Habit not found") }
        if (habit.archivedAt != null) throw NoSuchElementException("Habit not found")
        if (habit.user.id != user.id) throw AccessDeniedException("Not your habit")
        request.title?.let {
            if (it.isBlank()) throw IllegalArgumentException("title must not be blank")
            habit.title = it
        }
        request.iconId?.let { habit.iconId = it }
        request.color?.let { habit.color = it }
        request.targetValue?.let { habit.targetValue = it }
        request.unit?.let { habit.unit = it }
        request.frequencyRule?.let { habit.frequencyRule = it }
        request.reminderTime?.let {
            habit.reminderTime = try { LocalTime.parse(it) } catch (e: Exception) { throw IllegalArgumentException("Invalid reminderTime format, expected HH:mm") }
        }
        if (request.archived == true) habit.archivedAt = Instant.now()
        return HabitResponse.from(habitRepository.save(habit))
    }

    @Transactional
    fun logEntry(user: User, habitId: UUID, request: LogEntryRequest): HabitEntryResponse {
        val habit = habitRepository.findById(habitId).orElseThrow { NoSuchElementException("Habit not found") }
        if (habit.archivedAt != null) throw NoSuchElementException("Habit not found")
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

    @Transactional(readOnly = true)
    fun getEntries(user: User, habitId: UUID, from: LocalDate, to: LocalDate): List<HabitEntryResponse> {
        val habit = habitRepository.findById(habitId).orElseThrow { NoSuchElementException("Habit not found") }
        if (habit.archivedAt != null) throw NoSuchElementException("Habit not found")
        if (habit.user.id != user.id) throw AccessDeniedException("Not your habit")
        if (from.isAfter(to)) throw IllegalArgumentException("'from' must not be after 'to'")
        return habitEntryRepository.findByHabitIdAndEntryDateBetweenOrderByEntryDate(habitId, from, to)
            .map { HabitEntryResponse.from(it) }
    }

    @Transactional(readOnly = true)
    fun getStreak(user: User, habitId: UUID): StreakResponse {
        val habit = habitRepository.findById(habitId).orElseThrow { NoSuchElementException("Habit not found") }
        if (habit.user.id != user.id) throw AccessDeniedException("Not your habit")
        val sorted = habitEntryRepository.findAllDatesByHabitId(habitId)
        if (sorted.isEmpty()) return StreakResponse(0, 0)
        var currentStreak = 1
        var longestStreak = 1
        var streak = 1
        var currentStreakDone = false
        for (i in 1 until sorted.size) {
            if (sorted[i] == sorted[i - 1].minusDays(1)) {
                streak++
                if (!currentStreakDone) currentStreak = streak
            } else {
                currentStreakDone = true
                streak = 1
            }
            if (streak > longestStreak) longestStreak = streak
        }
        return StreakResponse(currentStreak, longestStreak)
    }
}
