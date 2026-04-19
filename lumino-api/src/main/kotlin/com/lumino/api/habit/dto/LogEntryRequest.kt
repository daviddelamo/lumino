package com.lumino.api.habit.dto

import jakarta.validation.constraints.Positive
import java.time.LocalDate

data class LogEntryRequest(
    val entryDate: LocalDate,
    @field:Positive val value: Double = 1.0,
    val note: String? = null
)
