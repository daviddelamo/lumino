package com.lumino.api.task

import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import java.time.Instant
import java.util.UUID

interface TaskRepository : JpaRepository<Task, UUID> {
    @Query("""
        SELECT t FROM Task t
        WHERE t.user.id = :userId
          AND t.deletedAt IS NULL
          AND t.startAt >= :startOfDay
          AND t.startAt < :endOfDay
        ORDER BY t.startAt
    """)
    fun findByUserAndDate(userId: UUID, startOfDay: Instant, endOfDay: Instant): List<Task>
}
