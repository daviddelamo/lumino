package com.lumino.api.auth

import com.lumino.api.user.User
import jakarta.persistence.*
import java.time.Instant
import java.util.UUID

@Entity
@Table(name = "refresh_tokens")
class RefreshToken(
    @Id val id: UUID = UUID.randomUUID(),
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id") val user: User,
    val tokenHash: String,
    val deviceId: String? = null,
    val expiresAt: Instant,
    val revokedAt: Instant? = null,
    val createdAt: Instant = Instant.now()
)
