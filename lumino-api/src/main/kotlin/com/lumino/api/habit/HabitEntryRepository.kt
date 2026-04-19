package com.lumino.api.habit

import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import java.time.LocalDate
import java.util.UUID

interface HabitEntryRepository : JpaRepository<HabitEntry, UUID> {
    fun findByHabitIdAndEntryDateBetweenOrderByEntryDate(habitId: UUID, from: LocalDate, to: LocalDate): List<HabitEntry>
    fun findByHabitIdAndEntryDate(habitId: UUID, date: LocalDate): HabitEntry?

    @Query("SELECT e.entryDate FROM HabitEntry e WHERE e.habit.id = :habitId ORDER BY e.entryDate DESC")
    fun findAllDatesByHabitId(habitId: UUID): List<LocalDate>
}
