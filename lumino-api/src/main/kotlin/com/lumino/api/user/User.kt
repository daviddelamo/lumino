package com.lumino.api.user

import jakarta.persistence.*
import org.hibernate.annotations.JdbcTypeCode
import org.hibernate.type.SqlTypes
import org.springframework.security.core.GrantedAuthority
import org.springframework.security.core.userdetails.UserDetails
import java.time.Instant
import java.util.UUID

@Entity
@Table(name = "users")
class User(
    @Id val id: UUID = UUID.randomUUID(),
    val email: String? = null,
    @Column(name = "password_hash") private val passwordHash: String? = null,
    val displayName: String? = null,
    val authProvider: String = "email",
    @Column(name = "facebook_id") val facebookId: String? = null,
    val locale: String = "en",
    val timezone: String = "UTC",
    @JdbcTypeCode(SqlTypes.JSON) @Column(columnDefinition = "jsonb") val onboardingProfile: String? = null,
    val createdAt: Instant = Instant.now(),
    val deletedAt: Instant? = null
) : UserDetails {
    override fun getAuthorities(): Collection<GrantedAuthority> = emptyList()
    override fun getPassword() = passwordHash
    override fun getUsername() = id.toString()
    override fun isAccountNonExpired() = deletedAt == null
    override fun isAccountNonLocked() = deletedAt == null
    override fun isCredentialsNonExpired() = true
    override fun isEnabled() = deletedAt == null
}
