package com.smartkitchen.backend.auth

data class SignupRequest(
    val email: String,
    val password: String,
    val nickname: String?,
)

data class SignupResponse(
    val userId: Long,
    val email: String,
    val nickname: String?, //?는 null값 허용
)

data class LoginRequest(
    val email: String,
    val password: String,
)

data class LoginResponse(
    val accessToken: String,
    val nickname: String?,
)
