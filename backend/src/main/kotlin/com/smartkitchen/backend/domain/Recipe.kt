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

    /** 직접 입력분과 마스터 복제분 구분 (D-014) */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    var source: RecipeSource = RecipeSource.MANUAL,

    /** source가 MASTER면 반드시 채워진다 (DB의 ck_recipe_master_ref) */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "recipe_master_id")
    var recipeMaster: RecipeMaster? = null,

    @Column(name = "created_at", nullable = false)
    val createdAt: OffsetDateTime = OffsetDateTime.now(),
)
