package com.lumino.api.habit.dto

data class UpdateHabitRequest(
    val title: String? = null,
    val iconId: String? = null,
    val color: String? = null,
    val targetValue: Double? = null,
    val unit: String? = null,
    val frequencyRule: String? = null,
    val reminderTime: String? = null,
    val archived: Boolean? = null
)
