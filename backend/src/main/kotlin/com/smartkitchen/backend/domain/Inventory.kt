package com.smartkitchen.backend.domain

import jakarta.persistence.*
import java.math.BigDecimal

@Entity
@Table(name = "inventory")
class Inventory(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "household_id", nullable = false)
    var household: Household,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ingredient_id", nullable = false)
    var ingredient: Ingredient,

    /** 실물 보유량 = 배치(inventory_item) 합계 */
    @Column(nullable = false, precision = 10, scale = 2)
    var quantity: BigDecimal = BigDecimal.ZERO,

    /** 확정 전 계획이 잡아둔 예약량 (D-002) */
    @Column(name = "reserved_quantity", nullable = false, precision = 10, scale = 2)
    var reservedQuantity: BigDecimal = BigDecimal.ZERO,

    /** 등록 시 ingredient.defaultStorage로 초기화하고 사용자가 변경할 수 있다 */
    @Enumerated(EnumType.STRING)
    @Column(name = "storage_location", nullable = false, length = 10)
    var storageLocation: StorageLocation,
)
