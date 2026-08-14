package com.smartkitchen.backend.domain

import jakarta.persistence.*
import java.math.BigDecimal
import java.time.OffsetDateTime

@Entity
@Table(name = "inventory_history")
class InventoryHistory(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "household_id", nullable = false)
    var household: Household,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ingredient_id", nullable = false)
    var ingredient: Ingredient,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    var type: InventoryHistoryType,

    /** 증가 +, 감소 - */
    @Column(nullable = false, precision = 10, scale = 2)
    var quantity: BigDecimal,

    /** 예: MEAL_PLAN, SHOPPING_LIST. FK가 아닌 논리 참조라 문자열로 둔다 */
    @Column(name = "ref_type", length = 20)
    var refType: String? = null,

    @Column(name = "ref_id")
    var refId: Long? = null,

    @Column(name = "created_at", nullable = false)
    val createdAt: OffsetDateTime = OffsetDateTime.now(),
)
