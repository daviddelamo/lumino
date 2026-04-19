package com.lumino.api.task.dto
import com.lumino.api.task.Task
import java.time.Instant
import java.util.UUID
data class TaskResponse(
    val id: UUID, val title: String, val iconId: String, val color: String,
    val startAt: Instant, val endAt: Instant?, val repeatRule: String?,
    val reminderOffsetMin: Int?, val notes: String?,
    val completedAt: Instant?, val updatedAt: Instant
) {
    companion object {
        fun from(t: Task) = TaskResponse(
            t.id, t.title, t.iconId, t.color, t.startAt, t.endAt,
            t.repeatRule, t.reminderOffsetMin, t.notes, t.completedAt, t.updatedAt
        )
    }
}
