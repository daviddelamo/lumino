package com.lumino.api.user

import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Modifying
import org.springframework.data.jpa.repository.Query
import org.springframework.transaction.annotation.Transactional
import java.time.Instant
import java.util.UUID

interface UserRepository : JpaRepository<User, UUID> {
    fun findByEmail(email: String): User?
    fun existsByEmail(email: String): Boolean
    fun findByFacebookId(facebookId: String): User?

    @Modifying
    @Transactional
    @Query("UPDATE User u SET u.displayName = :name WHERE u.id = :id")
    fun updateDisplayName(id: UUID, name: String)

    @Modifying
    @Transactional
    @Query("UPDATE User u SET u.locale = :locale WHERE u.id = :id")
    fun updateLocale(id: UUID, locale: String)

    @Modifying
    @Transactional
    @Query("UPDATE User u SET u.timezone = :timezone WHERE u.id = :id")
    fun updateTimezone(id: UUID, timezone: String)

    @Modifying
    @Transactional
    @Query("UPDATE User u SET u.onboardingProfile = :profile WHERE u.id = :id")
    fun updateOnboardingProfile(id: UUID, profile: String)

    @Modifying
    @Transactional
    @Query("UPDATE User u SET u.deletedAt = :deletedAt WHERE u.id = :id")
    fun softDelete(id: UUID, deletedAt: Instant)
}
