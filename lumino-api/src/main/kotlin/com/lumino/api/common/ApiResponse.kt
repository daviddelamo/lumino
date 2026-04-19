package com.lumino.api.common

data class ApiResponse<T>(
    val data: T? = null,
    val error: String? = null
) {
    companion object {
        fun <T> ok(data: T) = ApiResponse(data = data)
        fun error(message: String) = ApiResponse<Nothing>(error = message)
    }
}
