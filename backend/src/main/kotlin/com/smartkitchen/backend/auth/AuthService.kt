package com.smartkitchen.backend.auth

import com.smartkitchen.backend.domain.AppUser
import com.smartkitchen.backend.domain.Household
import org.springframework.http.HttpStatus
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import org.springframework.web.bind.annotation.ResponseStatus
import org.springframework.web.server.ResponseStatusException

@Service
class AuthService(
    private val userRepository: UserRepository,
    private val householdRepository: HouseholdRepository,
    private val passwordEncoder: PasswordEncoder,
    private val jwtProvider: JwtProvider,
){
    @Transactional
    fun signup(request: SignupRequest): SignupResponse{
        if (userRepository.existsByEmail(request.email)) {
            throw ResponseStatusException(HttpStatus.CONFLICT, "이미 가입된 이메일입니다")
        }

        val household = householdRepository.save(
            Household(name = "${request.nickname ?: request.email}의 집")
        )
        val user = AppUser(
            email = request.email,
            nickname = request.nickname,
            passwordHash = passwordEncoder.encode(request.password)!!,
            household = household,
        )
        val saved = userRepository.save(user)
        return SignupResponse(
            userId = saved.id!!,
            email = saved.email,
            nickname = saved.nickname,
        )
    }
    @Transactional(readOnly = true)
    fun login(request: LoginRequest): LoginResponse {
        val user = userRepository.findByEmail(request.email)
            ?: throw ResponseStatusException(HttpStatus.UNAUTHORIZED, "이메일 또는 비밀번호가 올바르지 않습니다")

        if (!passwordEncoder.matches(request.password, user.passwordHash)) {
            throw ResponseStatusException(HttpStatus.UNAUTHORIZED, "이메일 또는 비밀번호가 올바르지 않습니다")
        }

        return LoginResponse(
            accessToken = jwtProvider.createToken(user.id!!),
            nickname = user.nickname,
        )
    }
}
