package com.lumino.api.subscription

import com.fasterxml.jackson.annotation.JsonProperty
import org.springframework.beans.factory.annotation.Value
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

data class RcWebhookPayload(
    val event: RcEvent
)

data class RcEvent(
    val type: String,
    @JsonProperty("app_user_id")  val appUserId: String,
    @JsonProperty("product_id")   val productId: String,
    @JsonProperty("expiration_at_ms") val expirationAtMs: Long?
)

@RestController
@RequestMapping("/api/webhooks")
class RevenueCatWebhookController(
    private val subscriptionService: SubscriptionService,
    @Value("\${revenuecat.webhook-secret}") private val webhookSecret: String
) {

    @PostMapping("/revenuecat")
    fun handle(
        @RequestHeader("Authorization") auth: String?,
        @RequestBody payload: RcWebhookPayload
    ): ResponseEntity<Unit> {
        if (webhookSecret.isBlank() || auth != webhookSecret) {
            return ResponseEntity.status(401).build()
        }
        subscriptionService.handleEvent(
            type        = payload.event.type,
            appUserId   = payload.event.appUserId,
            productId   = payload.event.productId,
            expiresAtMs = payload.event.expirationAtMs
        )
        return ResponseEntity.ok().build()
    }
}
