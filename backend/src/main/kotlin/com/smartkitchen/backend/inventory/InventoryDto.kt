package com.smartkitchen.backend.inventory

import com.smartkitchen.backend.domain.StorageLocation
import com.smartkitchen.backend.domain.UnitType
import java.math.BigDecimal
import java.time.LocalDate

/**
 * 배치 일괄 등록의 항목 하나 (API-21).
 * storageLocation은 받지 않는다 — Inventory 생성 시 ingredient.defaultStorage로 초기화한다.
 */
data class InventoryItemCreateRequest(
    val ingredientId: Long,
    val quantity: BigDecimal,
    /** 미입력 시 purchasedAt + ingredient.defaultShelfLifeDays로 자동 계산 (D-017) */
    val expiryDate: LocalDate? = null,
    /** 미입력 시 오늘 */
    val purchasedAt: LocalDate? = null,
)

/** 유통기한 상태 (R-5, D-013). 당일(dday=0)은 임박으로 본다 */
enum class ExpiryStatus {
    EXPIRED,
    EXPIRING,
    NORMAL,
    /** 유통기한이 있는 배치가 없음 */
    NONE,
}

/** 재고 목록의 항목 하나 (API-20). ingredient 단위로 배치를 합산한 결과 */
data class InventoryResponse(
    val ingredientId: Long,
    val name: String,
    val category: String,
    val unitType: UnitType,
    val storageLocation: StorageLocation,
    /** 실물 보유량 = 배치 합계 */
    val totalQuantity: BigDecimal,
    /** 확정 전 계획이 잡아둔 예약량 (D-002) */
    val reservedQuantity: BigDecimal,
    /** 가용 = 잔량 − 예약 (R-1) */
    val availableQuantity: BigDecimal,
    val nearestExpiryDate: LocalDate?,
    /** 배지용. 오늘=0, 지난 것은 음수 */
    val dday: Int?,
    val expiryStatus: ExpiryStatus,
)
