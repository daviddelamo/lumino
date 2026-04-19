package com.lumino.api.user

import com.lumino.api.common.ApiResponse
import com.lumino.api.common.CurrentUser
import com.lumino.api.user.dto.UpdateProfileRequest
import jakarta.validation.Valid
import org.springframework.http.HttpStatus
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/me")
class UserController(private val userService: UserService) {

    @GetMapping
    fun getProfile(@CurrentUser user: User) = ApiResponse.ok(userService.getProfile(user))

    @PutMapping
    fun updateProfile(@CurrentUser user: User, @Valid @RequestBody request: UpdateProfileRequest) =
        ApiResponse.ok(userService.updateProfile(user, request))

    @DeleteMapping
    @ResponseStatus(HttpStatus.NO_CONTENT)
    fun deleteAccount(@CurrentUser user: User) {
        userService.deleteAccount(user)
    }
}
