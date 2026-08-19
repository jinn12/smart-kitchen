package com.smartkitchen.backend.auth

import com.smartkitchen.backend.domain.AppUser
import org.springframework.data.jpa.repository.JpaRepository

interface UserRepository : JpaRepository<AppUser, Long> {
    fun existsByEmail(email: String): Boolean
}