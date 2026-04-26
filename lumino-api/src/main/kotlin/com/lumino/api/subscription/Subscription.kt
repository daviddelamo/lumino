package com.lumino.api.subscription

import com.lumino.api.user.User
import jakarta.persistence.*
import java.time.Instant
import java.util.UUID

@Entity
@Table(name = "subscriptions")
class Subscription(
    @Id
    val id: UUID = UUID.randomUUID(),

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    val user: User,

    val rcCustomerId: String,
    val productId: String,
    var status: String = "ACTIVE",
    var expiresAt: Instant? = null,
    val isLifetime: Boolean = false,
    @Column(name = "created_at", updatable = false)
    val createdAt: Instant = Instant.now(),
    var updatedAt: Instant = Instant.now()
) {
    @PreUpdate
    fun onUpdate() { updatedAt = Instant.now() }
}
