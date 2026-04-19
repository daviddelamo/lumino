package com.lumino.api.auth

import com.lumino.api.user.UserRepository
import jakarta.servlet.FilterChain
import jakarta.servlet.http.HttpServletRequest
import jakarta.servlet.http.HttpServletResponse
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.stereotype.Component
import org.springframework.web.filter.OncePerRequestFilter

@Component
class JwtAuthFilter(
    private val jwtService: JwtService,
    private val userRepository: UserRepository
) : OncePerRequestFilter() {

    private val logger = org.slf4j.LoggerFactory.getLogger(JwtAuthFilter::class.java)

    override fun doFilterInternal(
        request: HttpServletRequest,
        response: HttpServletResponse,
        chain: FilterChain
    ) {
        val header = request.getHeader("Authorization")
        if (header != null && header.startsWith("Bearer ")) {
            val token = header.removePrefix("Bearer ")
            runCatching {
                if (jwtService.isValid(token)) {
                    val userId = jwtService.extractUserId(token)
                    userRepository.findById(userId).ifPresent { user ->
                        if (user.isEnabled) {
                            SecurityContextHolder.getContext().authentication =
                                UsernamePasswordAuthenticationToken(user, null, emptyList())
                        }
                    }
                }
            }.onFailure { ex ->
                if (ex !is io.jsonwebtoken.JwtException && ex !is IllegalArgumentException) {
                    logger.warn("Unexpected error processing JWT token", ex)
                }
            }
        }
        chain.doFilter(request, response)
    }
}
