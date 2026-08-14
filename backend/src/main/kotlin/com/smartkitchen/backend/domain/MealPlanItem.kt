package com.smartkitchen.backend.domain

import jakarta.persistence.*
import java.math.BigDecimal

/** 계획별 예약 스냅샷 (R-1, D-010) */
@Entity
@Table(name = "meal_plan_item")
class MealPlanItem(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "meal_plan_id", nullable = false)
    var mealPlan: MealPlan,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ingredient_id", nullable = false)
    var ingredient: Ingredient,

    /** 재료량 × (MealPlan.servings ÷ Recipe.servings) (D-015) */
    @Column(name = "required_qty", nullable = false, precision = 10, scale = 2)
    var requiredQty: BigDecimal,

    /** "있는 만큼 사용" 시 requiredQty보다 작을 수 있다 */
    @Column(name = "reserved_qty", nullable = false, precision = 10, scale = 2)
    var reservedQty: BigDecimal,
)
