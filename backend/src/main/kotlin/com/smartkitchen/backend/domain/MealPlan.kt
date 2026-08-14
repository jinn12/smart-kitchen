package com.smartkitchen.backend.domain

import jakarta.persistence.*
import java.time.LocalDate
import java.time.OffsetDateTime

@Entity
@Table(name = "meal_plan")
class MealPlan(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "household_id", nullable = false)
    var household: Household,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "recipe_id", nullable = false)
    var recipe: Recipe,

    @Column(name = "plan_date", nullable = false)
    var planDate: LocalDate,

    @Enumerated(EnumType.STRING)
    @Column(name = "meal_type", nullable = false, length = 10)
    var mealType: MealType,

    /** 선택 인분. 기본값은 recipe.servings (D-015) */
    @Column(nullable = false)
    var servings: Int,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    var status: MealPlanStatus = MealPlanStatus.PLANNED,

    @Column(name = "created_at", nullable = false)
    val createdAt: OffsetDateTime = OffsetDateTime.now(),
)
