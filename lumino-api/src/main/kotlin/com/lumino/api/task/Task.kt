package com.lumino.api.task

import com.lumino.api.user.User
import jakarta.persistence.*
import org.hibernate.annotations.JdbcTypeCode
import org.hibernate.type.SqlTypes
import java.time.Instant
import java.util.UUID

@Entity
@Table(name = "tasks")
class Task(
    @Id val id: UUID = UUID.randomUUID(),
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id") val user: User,
    var title: String,
    var iconId: String = "circle",
    var color: String = "#E8823A",
    var startAt: Instant,
    var endAt: Instant? = null,
    @JdbcTypeCode(SqlTypes.JSON) var repeatRule: String? = null,
    var reminderOffsetMin: Int? = null,
    var notes: String? = null,
    var completedAt: Instant? = null,
    var deletedAt: Instant? = null,
    var updatedAt: Instant = Instant.now()
) {
    @PreUpdate
    fun onUpdate() { updatedAt = Instant.now() }
}
