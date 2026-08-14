package com.smartkitchen.backend.domain

import jakarta.persistence.*
import java.time.OffsetDateTime

@Entity
@Table(name = "app_user")
class AppUser(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "household_id", nullable = false)
    var household: Household,

    @Column(nullable = false, unique = true, length = 255)
    var email: String,

    @Column(name = "password_hash", nullable = false, length = 100)
    var passwordHash: String,

    @Column(length = 30)
    var nickname: String? = null,

    @Column(name = "created_at", nullable = false)
    val createdAt: OffsetDateTime = OffsetDateTime.now(),
)
