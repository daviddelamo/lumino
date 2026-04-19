package com.lumino.api.habit.dto

import com.lumino.api.habit.HabitEntry
import java.time.Instant
import java.time.LocalDate
import java.util.UUID

data class HabitEntryResponse(
    val id: UUID,
    val entryDate: LocalDate,
    val value: Double,
    val note: String?,
    val loggedAt: Instant
) {
    companion object {
        fun from(e: HabitEntry) = HabitEntryResponse(e.id, e.entryDate, e.value, e.note, e.loggedAt)
    }
}
