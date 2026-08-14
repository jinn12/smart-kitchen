package com.smartkitchen.backend.domain

import jakarta.persistence.*
import java.math.BigDecimal
import java.time.OffsetDateTime

@Entity
@Table(name = "ingredient")
class Ingredient(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    /** NULL이면 시스템 마스터 식재료 (D-005) */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "household_id")
    var household: Household? = null,

    @Column(nullable = false, length = 50)
    var name: String,

    /** 13종 카테고리 (D-017). DB CHECK가 없어 문자열로 둔다 */
    @Column(nullable = false, length = 30)
    var category: String,

    @Enumerated(EnumType.STRING)
    @Column(name = "unit_type", nullable = false, length = 10)
    var unitType: UnitType,

    /** 표시 전용 포장 단위명. 예: "모" */
    @Column(name = "package_name", length = 20)
    var packageName: String? = null,

    /** 포장 1개의 base_unit 환산값. 예: 두부 1모 = 300(g) */
    @Column(name = "package_size", precision = 10, scale = 2)
    var packageSize: BigDecimal? = null,

    @Enumerated(EnumType.STRING)
    @Column(name = "default_storage", nullable = false, length = 10)
    var defaultStorage: StorageLocation,

    /** 구매·등록일 기준 권장 소비 기간 (D-005, D-007) */
    @Column(name = "default_shelf_life_days")
    var defaultShelfLifeDays: Int? = null,

    /** false면 잔량 정량 관리를 하지 않는다 (D-004) */
    @Column(name = "is_trackable", nullable = false)
    var isTrackable: Boolean = true,

    @Column(name = "is_custom", nullable = false)
    var isCustom: Boolean = false,

    @Column(name = "created_at", nullable = false)
    val createdAt: OffsetDateTime = OffsetDateTime.now(),
)
