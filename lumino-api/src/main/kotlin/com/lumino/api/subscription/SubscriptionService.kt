package com.lumino.api.subscription

import com.lumino.api.user.UserRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Instant
import java.util.UUID

@Service
class SubscriptionService(
    private val subscriptionRepository: SubscriptionRepository,
    private val userRepository: UserRepository
) {

    @Transactional(readOnly = true)
    fun isPremium(userId: UUID): Boolean =
        subscriptionRepository.findActiveForUser(userId, Instant.now()).isNotEmpty()

    @Transactional
    fun handleEvent(type: String, appUserId: String, productId: String, expiresAtMs: Long?) {
        val userId = runCatching { UUID.fromString(appUserId) }.getOrNull() ?: return
        val user = userRepository.findById(userId).orElse(null) ?: return
        val expiresAt = expiresAtMs?.let { Instant.ofEpochMilli(it) }

        when (type) {
            "INITIAL_PURCHASE" -> {
                subscriptionRepository.save(
                    Subscription(
                        user = user,
                        rcCustomerId = appUserId,
                        productId = productId,
                        status = "ACTIVE",
                        expiresAt = expiresAt,
                        isLifetime = false
                    )
                )
            }
            "NON_SUBSCRIPTION_PURCHASE" -> {
                subscriptionRepository.save(
                    Subscription(
                        user = user,
                        rcCustomerId = appUserId,
                        productId = productId,
                        status = "ACTIVE",
                        expiresAt = null,
                        isLifetime = true
                    )
                )
            }
            "RENEWAL" -> {
                val existing = subscriptionRepository
                    .findByUserIdAndProductId(userId, productId)
                    .firstOrNull()
                if (existing != null) {
                    existing.status = "ACTIVE"
                    existing.expiresAt = expiresAt
                    subscriptionRepository.save(existing)
                } else {
                    subscriptionRepository.save(
                        Subscription(
                            user = user,
                            rcCustomerId = appUserId,
                            productId = productId,
                            status = "ACTIVE",
                            expiresAt = expiresAt,
                            isLifetime = false
                        )
                    )
                }
            }
            "CANCELLATION" -> {
                subscriptionRepository
                    .findByUserIdAndProductId(userId, productId)
                    .forEach { it.status = "CANCELLED"; subscriptionRepository.save(it) }
            }
            "EXPIRATION" -> {
                subscriptionRepository
                    .findByUserIdAndProductId(userId, productId)
                    .forEach { it.status = "EXPIRED"; subscriptionRepository.save(it) }
            }
            // Unknown event types are silently ignored
        }
    }
}
