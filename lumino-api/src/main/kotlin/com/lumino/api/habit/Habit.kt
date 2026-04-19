package com.lumino.api.habit

import com.lumino.api.user.User
import jakarta.persistence.*
import org.hibernate.annotations.JdbcTypeCode
import org.hibernate.type.SqlTypes
import java.time.Instant
import java.time.LocalTime
import java.util.UUID

@Entity
@Table(name = "habits")
class Habit(
    @Id val id: UUID = UUID.randomUUID(),
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id") val user: User,
    var title: String,
    var iconId: String = "circle",
    var color: String = "#E8823A",
    var type: String,
    @Column(columnDefinition = "numeric")
    var targetValue: Double = 1.0,
    var unit: String? = null,
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(columnDefinition = "jsonb")
    var frequencyRule: String,
    var reminderTime: LocalTime? = null,
    val createdAt: Instant = Instant.now(),
    var archivedAt: Instant? = null,
    var updatedAt: Instant = Instant.now()
) {
    @PreUpdate
    fun onUpdate() { updatedAt = Instant.now() }
}
