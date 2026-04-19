package com.lumino.api.auth

import com.lumino.api.config.JwtConfig
import io.jsonwebtoken.Jwts
import io.jsonwebtoken.io.Decoders
import io.jsonwebtoken.security.Keys
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.stereotype.Service
import java.util.Date
import java.util.UUID
import javax.crypto.SecretKey

@Service
class JwtService(
    private val secret: String,
    private val accessTokenExpiryMs: Long
) {
    @Autowired constructor(config: JwtConfig) : this(config.secret, config.accessTokenExpiryMs)

    private val key: SecretKey by lazy {
        Keys.hmacShaKeyFor(Decoders.BASE64.decode(secret))
    }

    fun generateAccessToken(userId: UUID): String =
        Jwts.builder()
            .subject(userId.toString())
            .issuedAt(Date())
            .expiration(Date(System.currentTimeMillis() + accessTokenExpiryMs))
            .signWith(key)
            .compact()

    fun extractUserId(token: String): UUID =
        runCatching {
            UUID.fromString(
                Jwts.parser().verifyWith(key).build()
                    .parseSignedClaims(token).payload.subject
            )
        }.getOrElse { throw IllegalArgumentException("Invalid token", it) }

    fun isValid(token: String): Boolean = runCatching { extractUserId(token) }.isSuccess
}
