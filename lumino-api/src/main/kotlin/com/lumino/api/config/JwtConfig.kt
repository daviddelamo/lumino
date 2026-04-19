package com.lumino.api.config

import jakarta.annotation.PostConstruct
import org.springframework.boot.context.properties.ConfigurationProperties
import org.springframework.stereotype.Component

@Component
@ConfigurationProperties(prefix = "jwt")
class JwtConfig {
    var secret: String = ""
    var accessTokenExpiryMs: Long = 900_000
    var refreshTokenExpiryDays: Long = 30

    @PostConstruct
    fun validate() {
        require(secret.isNotBlank()) { "jwt.secret must be configured" }
    }
}
