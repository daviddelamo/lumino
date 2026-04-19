package com.lumino.api.habit

import org.springframework.data.jpa.repository.JpaRepository
import java.util.UUID

interface HabitRepository : JpaRepository<Habit, UUID> {
    fun findByUserIdAndArchivedAtIsNull(userId: UUID): List<Habit>
}
