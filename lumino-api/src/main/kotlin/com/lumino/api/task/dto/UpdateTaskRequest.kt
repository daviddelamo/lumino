package com.lumino.api.task.dto
import java.time.Instant
data class UpdateTaskRequest(
    val title: String? = null,
    val iconId: String? = null,
    val color: String? = null,
    val startAt: Instant? = null,
    val endAt: Instant? = null,
    val repeatRule: String? = null,
    val reminderOffsetMin: Int? = null,
    val notes: String? = null,
    val completedAt: Instant? = null
)
