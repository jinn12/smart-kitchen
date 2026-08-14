package com.smartkitchen.backend.domain

import jakarta.persistence.*
import java.time.OffsetDateTime

@Entity
@Table(name = "household")
class Household(

    @Column(nullable = false, length = 50)
    var name: String,

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @Column(name = "created_at", nullable = false)
    val createdAt: OffsetDateTime = OffsetDateTime.now(),
)
