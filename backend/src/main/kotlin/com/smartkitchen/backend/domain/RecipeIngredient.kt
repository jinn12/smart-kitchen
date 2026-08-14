package com.smartkitchen.backend.domain

import jakarta.persistence.*
import java.math.BigDecimal

@Entity
@Table(name = "recipe_ingredient")
class RecipeIngredient(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "recipe_id", nullable = false)
    var recipe: Recipe,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ingredient_id", nullable = false)
    var ingredient: Ingredient,

    /** 단위는 ingredient의 base_unit 고정 (D-004) */
    @Column(nullable = false, precision = 10, scale = 2)
    var quantity: BigDecimal,
)
