package com.lumino.api.subscription

import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import java.time.Instant
import java.util.UUID

interface SubscriptionRepository : JpaRepository<Subscription, UUID> {

    @Query("""
        SELECT s FROM Subscription s
        WHERE s.user.id = :userId
          AND s.status = 'ACTIVE'
          AND (s.isLifetime = true OR s.expiresAt > :now)
    """)
    fun findActiveForUser(userId: UUID, now: Instant): List<Subscription>

    @Query("SELECT s FROM Subscription s WHERE s.user.id = :userId AND s.productId = :productId AND s.status = 'ACTIVE'")
    fun findActiveByUserIdAndProductId(userId: UUID, productId: String): List<Subscription>

    fun findByUserIdAndProductId(userId: UUID, productId: String): List<Subscription>
}
