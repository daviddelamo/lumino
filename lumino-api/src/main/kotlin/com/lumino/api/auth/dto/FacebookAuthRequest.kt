package com.lumino.api.auth.dto
import jakarta.validation.constraints.NotBlank
data class FacebookAuthRequest(@field:NotBlank val accessToken: String)
