package com.lumino.api.user.dto

import jakarta.validation.constraints.Size

data class UpdateProfileRequest(
    @field:Size(max = 100) val displayName: String? = null,
    @field:Size(max = 10) val locale: String? = null,
    @field:Size(max = 64) val timezone: String? = null,
    val onboardingProfile: String? = null
)
