package com.smartkitchen.backend.domain

import jakarta.persistence.*
import java.time.OffsetDateTime

@Entity
@Table(name = "recipe")
class Recipe(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "household_id", nullable = false)
    var household: Household,

    @Column(nullable = false, length = 50)
    var name: String,

    /** 재료량의 기준 인분 (D-015) */
    @Column(nullable = false)
    var servings: Int = 1,

    @Column(name = "created_at", nullable = false)
    val createdAt: OffsetDateTime = OffsetDateTime.now(),
)
