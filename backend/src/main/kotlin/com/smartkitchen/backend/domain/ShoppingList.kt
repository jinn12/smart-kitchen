package com.smartkitchen.backend.domain

import jakarta.persistence.*

/** 가구당 1개 (D-009) */
@Entity
@Table(name = "shopping_list")
class ShoppingList(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "household_id", nullable = false, unique = true)
    var household: Household,
)
