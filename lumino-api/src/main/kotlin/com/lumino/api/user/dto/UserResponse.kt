package com.lumino.api.user.dto

import com.lumino.api.user.User
import java.time.Instant
import java.util.UUID

data class UserResponse(
    val id: UUID,
    val email: String?,
    val displayName: String?,
    val locale: String,
    val timezone: String,
    val onboardingProfile: String?,
    val createdAt: Instant
) {
    companion object {
        fun from(u: User) = UserResponse(u.id, u.email, u.displayName, u.locale, u.timezone, u.onboardingProfile, u.createdAt)
    }
}
