package com.lumino.api.auth

import com.google.auth.oauth2.TokenVerifier
import jakarta.annotation.PostConstruct
import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Service

@Service
class GoogleOAuthService(
    @Value("\${google.client-id:}") private val clientId: String
) {
    private lateinit var verifier: TokenVerifier

    @PostConstruct
    fun init() {
        if (clientId.isNotBlank()) {
            verifier = TokenVerifier.newBuilder().setAudience(clientId).build()
        }
    }

    fun verifyIdToken(idToken: String): GoogleUserInfo {
        if (clientId.isBlank() || !::verifier.isInitialized)
            throw IllegalArgumentException("Google OAuth is not configured")
        val jwt = try {
            verifier.verify(idToken)
        } catch (e: TokenVerifier.VerificationException) {
            throw IllegalArgumentException("Invalid Google ID token", e)
        }
        val payload = jwt.payload
        return GoogleUserInfo(
            email = payload.get("email") as? String
                ?: throw IllegalArgumentException("No email in Google token"),
            displayName = payload.get("name") as? String
        )
    }

    data class GoogleUserInfo(val email: String, val displayName: String?)
}
