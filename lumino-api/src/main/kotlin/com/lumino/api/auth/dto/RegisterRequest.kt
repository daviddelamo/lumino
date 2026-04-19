package com.lumino.api.auth.dto
import jakarta.validation.constraints.Email
import jakarta.validation.constraints.Size
data class RegisterRequest(
    @field:Email val email: String,
    @field:Size(min = 6) val password: String
)
