package com.lumino.api.habit.dto

import com.lumino.api.habit.Habit
import java.time.Instant
import java.util.UUID

data class HabitResponse(
    val id: UUID,
    val title: String,
    val iconId: String,
    val color: String,
    val type: String,
    val targetValue: Double,
    val unit: String?,
    val frequencyRule: String,
    val reminderTime: String?,
    val createdAt: Instant,
    val updatedAt: Instant,
    val archivedAt: Instant?
) {
    companion object {
        fun from(h: Habit) = HabitResponse(
            h.id, h.title, h.iconId, h.color, h.type, h.targetValue,
            h.unit, h.frequencyRule, h.reminderTime?.toString(),
            h.createdAt, h.updatedAt, h.archivedAt
        )
    }
}
