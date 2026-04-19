package com.lumino.api.habit.dto

import jakarta.validation.constraints.NotBlank

data class CreateHabitRequest(
    @field:NotBlank val title: String,
    val iconId: String = "circle",
    val color: String = "#E8823A",
    @field:NotBlank val type: String,
    val targetValue: Double = 1.0,
    val unit: String? = null,
    @field:NotBlank val frequencyRule: String,
    val reminderTime: String? = null
)
