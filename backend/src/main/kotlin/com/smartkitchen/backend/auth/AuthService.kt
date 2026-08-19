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
        // 1. 이메일 중복이면 예외:
        //    throw ResponseStatusException(HttpStatus.CONFLICT, "이미 가입된 이메일입니다")
        // 2. Household 생성·저장 — 이름은 "${nickname ?: email}의 집" 정도로
        // 3. AppUser 생성 — passwordHash에는 passwordEncoder.encode(request.password)
        // 4. userRepository.save(...) 후 SignupResponse로 변환해 반환

    }
}
