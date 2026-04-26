package com.lumino.api.user

import com.lumino.api.auth.RefreshTokenRepository
import com.lumino.api.subscription.SubscriptionService
import com.lumino.api.user.dto.UpdateProfileRequest
import com.lumino.api.user.dto.UserResponse
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Instant

@Service
class UserService(
    private val userRepository: UserRepository,
    private val refreshTokenRepository: RefreshTokenRepository,
    private val subscriptionService: SubscriptionService
) {

    @Transactional(readOnly = true)
    fun getProfile(user: User): UserResponse =
        UserResponse.from(user, subscriptionService.isPremium(user.id))

    @Transactional
    fun updateProfile(user: User, request: UpdateProfileRequest): UserResponse {
        require(
            request.displayName != null || request.locale != null ||
            request.timezone != null || request.onboardingProfile != null
        ) { "At least one field must be provided" }
        request.displayName?.let { userRepository.updateDisplayName(user.id, it) }
        request.locale?.let { userRepository.updateLocale(user.id, it) }
        request.timezone?.let { userRepository.updateTimezone(user.id, it) }
        request.onboardingProfile?.let { userRepository.updateOnboardingProfile(user.id, it) }
        return UserResponse.from(
            userRepository.findById(user.id).orElseThrow(),
            subscriptionService.isPremium(user.id)
        )
    }

    @Transactional
    fun deleteAccount(user: User) {
        refreshTokenRepository.revokeAllForUser(user.id)
        userRepository.softDelete(user.id, Instant.now())
    }
}
