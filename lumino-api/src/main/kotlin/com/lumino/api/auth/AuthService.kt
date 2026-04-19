package com.lumino.api.auth

import com.lumino.api.auth.dto.*
import com.lumino.api.config.JwtConfig
import com.lumino.api.user.User
import com.lumino.api.user.UserRepository
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.security.MessageDigest
import java.time.Instant
import java.util.Base64
import java.util.UUID

@Service
class AuthService(
    private val userRepository: UserRepository,
    private val refreshTokenRepository: RefreshTokenRepository,
    private val jwtService: JwtService,
    private val passwordEncoder: PasswordEncoder,
    private val jwtConfig: JwtConfig,
    private val googleOAuthService: GoogleOAuthService,
    private val facebookOAuthService: FacebookOAuthService
) {
    @Transactional
    fun register(request: RegisterRequest): AuthResponse {
        if (userRepository.existsByEmail(request.email))
            throw IllegalArgumentException("Email already registered")
        val user = userRepository.save(
            User(email = request.email, passwordHash = passwordEncoder.encode(request.password))
        )
        return issueTokens(user)
    }

    @Transactional
    fun login(request: LoginRequest): AuthResponse {
        val user = userRepository.findByEmail(request.email)
            ?: throw IllegalArgumentException("Invalid credentials")
        if (!passwordEncoder.matches(request.password, user.password))
            throw IllegalArgumentException("Invalid credentials")
        return issueTokens(user)
    }

    @Transactional
    fun refresh(request: RefreshRequest): AuthResponse {
        val hash = sha256(request.refreshToken)
        val token = refreshTokenRepository.findByTokenHashAndRevokedAtIsNull(hash)
            ?: throw IllegalArgumentException("Invalid refresh token")
        if (token.expiresAt.isBefore(Instant.now()))
            throw IllegalArgumentException("Refresh token expired")
        return issueTokens(token.user)
    }

    @Transactional
    fun loginWithGoogle(request: GoogleAuthRequest): AuthResponse {
        val googleUser = googleOAuthService.verifyIdToken(request.idToken)
        val user = userRepository.findByEmail(googleUser.email)
            ?: userRepository.save(
                User(
                    email = googleUser.email,
                    displayName = googleUser.displayName,
                    authProvider = "google"
                )
            )
        if (user.deletedAt != null) throw IllegalArgumentException("Account has been deleted")
        return issueTokens(user)
    }

    @Transactional
    fun loginWithFacebook(request: FacebookAuthRequest): AuthResponse {
        val fbUser = facebookOAuthService.verifyAccessToken(request.accessToken)
        val email = fbUser.email
        val user = if (email != null) {
            userRepository.findByEmail(email) ?: userRepository.save(
                User(email = email, displayName = fbUser.displayName, authProvider = "facebook")
            )
        } else {
            // Facebook did not share email — create an account keyed on Facebook ID
            userRepository.findByFacebookId(fbUser.facebookId) ?: userRepository.save(
                User(facebookId = fbUser.facebookId, displayName = fbUser.displayName, authProvider = "facebook")
            )
        }
        if (user.deletedAt != null) throw IllegalArgumentException("Account has been deleted")
        return issueTokens(user)
    }

    @Transactional
    fun logout(request: RefreshRequest) {
        val hash = sha256(request.refreshToken)
        refreshTokenRepository.revokeByHash(hash, Instant.now())
    }

    private fun issueTokens(user: User): AuthResponse {
        val accessToken = jwtService.generateAccessToken(user.id)
        val rawRefresh = UUID.randomUUID().toString()
        refreshTokenRepository.save(
            RefreshToken(
                user = user,
                tokenHash = sha256(rawRefresh),
                expiresAt = Instant.now().plusSeconds(jwtConfig.refreshTokenExpiryDays * 86_400)
            )
        )
        return AuthResponse(accessToken, rawRefresh)
    }

    private fun sha256(input: String): String =
        Base64.getEncoder().encodeToString(
            MessageDigest.getInstance("SHA-256").digest(input.toByteArray())
        )
}
