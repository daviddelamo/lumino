package com.lumino.api.auth.dto
import jakarta.validation.constraints.NotBlank
data class GoogleAuthRequest(@field:NotBlank val idToken: String)
