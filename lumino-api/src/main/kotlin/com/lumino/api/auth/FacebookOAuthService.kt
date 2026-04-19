package com.lumino.api.auth

import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Service
import org.springframework.web.client.RestClient
import org.springframework.web.client.RestClientException

@Service
class FacebookOAuthService(
    @Value("\${facebook.app-id:}") private val appId: String,
    @Value("\${facebook.app-secret:}") private val appSecret: String
) {
    private val restClient = RestClient.create()

    fun verifyAccessToken(accessToken: String): FacebookUserInfo {
        if (appId.isBlank() || appSecret.isBlank())
            throw IllegalArgumentException("Facebook OAuth is not configured")

        // Verify the token belongs to our app and retrieve user info in one call
        val debugUrl = "https://graph.facebook.com/debug_token" +
            "?input_token=$accessToken" +
            "&access_token=$appId|$appSecret"

        val debug = try {
            restClient.get().uri(debugUrl)
                .retrieve()
                .body(Map::class.java)
        } catch (e: RestClientException) {
            throw IllegalArgumentException("Failed to verify Facebook token", e)
        }

        @Suppress("UNCHECKED_CAST")
        val data = (debug?.get("data") as? Map<String, Any>)
            ?: throw IllegalArgumentException("Invalid Facebook debug_token response")

        val isValid = data["is_valid"] as? Boolean ?: false
        if (!isValid) throw IllegalArgumentException("Facebook access token is invalid or expired")

        val tokenAppId = data["app_id"] as? String
        if (tokenAppId != appId) throw IllegalArgumentException("Facebook token was not issued for this app")

        val userId = data["user_id"] as? String
            ?: throw IllegalArgumentException("No user_id in Facebook token")

        // Fetch profile with the verified user token
        val profileUrl = "https://graph.facebook.com/$userId?fields=id,name,email&access_token=$accessToken"
        val profile = try {
            restClient.get().uri(profileUrl)
                .retrieve()
                .body(Map::class.java)
        } catch (e: RestClientException) {
            throw IllegalArgumentException("Failed to fetch Facebook profile", e)
        } ?: throw IllegalArgumentException("Empty Facebook profile response")

        return FacebookUserInfo(
            facebookId = userId,
            email = profile["email"] as? String,
            displayName = profile["name"] as? String
        )
    }

    data class FacebookUserInfo(
        val facebookId: String,
        val email: String?,
        val displayName: String?
    )
}
