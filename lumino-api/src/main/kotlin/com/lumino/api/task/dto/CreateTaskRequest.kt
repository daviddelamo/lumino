package com.lumino.api.task.dto
import jakarta.validation.constraints.NotBlank
import java.time.Instant
data class CreateTaskRequest(
    @field:NotBlank val title: String,
    val iconId: String = "circle",
    val color: String = "#E8823A",
    val startAt: Instant,
    val endAt: Instant? = null,
    val repeatRule: String? = null,
    val reminderOffsetMin: Int? = null,
    val notes: String? = null
)
