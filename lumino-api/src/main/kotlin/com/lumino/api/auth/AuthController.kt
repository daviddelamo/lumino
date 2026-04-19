package com.lumino.api.auth

import com.lumino.api.auth.dto.*
import com.lumino.api.common.ApiResponse
import jakarta.validation.Valid
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/auth")
class AuthController(private val authService: AuthService) {

    @PostMapping("/register")
    fun register(@Valid @RequestBody request: RegisterRequest) =
        ApiResponse.ok(authService.register(request))

    @PostMapping("/login")
    fun login(@RequestBody request: LoginRequest) =
        ApiResponse.ok(authService.login(request))

    @PostMapping("/refresh")
    fun refresh(@RequestBody request: RefreshRequest) =
        ApiResponse.ok(authService.refresh(request))

    @PostMapping("/logout")
    fun logout(@RequestBody request: RefreshRequest) {
        authService.logout(request)
    }

    @PostMapping("/google")
    fun googleLogin(@Valid @RequestBody request: GoogleAuthRequest) =
        ApiResponse.ok(authService.loginWithGoogle(request))

    @PostMapping("/facebook")
    fun facebookLogin(@Valid @RequestBody request: FacebookAuthRequest) =
        ApiResponse.ok(authService.loginWithFacebook(request))
}
