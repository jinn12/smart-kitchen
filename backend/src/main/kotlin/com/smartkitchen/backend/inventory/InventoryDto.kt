package com.smartkitchen.backend.inventory

import com.smartkitchen.backend.domain.InventoryHistoryType
import com.smartkitchen.backend.domain.StorageLocation
import com.smartkitchen.backend.domain.UnitType
import java.math.BigDecimal
import java.time.LocalDate
import java.time.OffsetDateTime

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

/** 배치 단위 처리 (API-23) */
enum class InventoryItemAction {
    /** 잔량을 quantity로 덮어쓴다 (오입력 수정) */
    ADJUST,
    /** 배치를 전부 사용 처리한다 */
    CONSUME,
    /** 배치를 폐기한다 */
    DISCARD,
}

data class InventoryItemUpdateRequest(
    val action: InventoryItemAction,
    /** ADJUST에서만 사용. CONSUME·DISCARD는 무시한다 */
    val quantity: BigDecimal? = null,
)

/** 재고 단위 수정 (API-25). 지금은 보관 장소만 바꾼다 */
data class InventoryUpdateRequest(
    val storageLocation: StorageLocation,
)

/** 재고 상세의 배치 하나 (API-22). 잔량이 남은 배치만 내려간다 */
data class InventoryBatchResponse(
    val id: Long,
    val quantity: BigDecimal,
    val purchasedAt: LocalDate,
    val expiryDate: LocalDate?,
    val dday: Int?,
)

/** 재고 변동 기록 (API-22) */
data class InventoryHistoryResponse(
    val id: Long,
    val type: InventoryHistoryType,
    /** 증가 +, 감소 − */
    val quantity: BigDecimal,
    val refType: String?,
    val refId: Long?,
    val createdAt: OffsetDateTime,
)

/** 재고 상세 (API-22, S-12) */
data class InventoryDetailResponse(
    val summary: InventoryResponse,
    /** FEFO 순: 유통기한 이른 순, NULL은 마지막 (R-2) */
    val batches: List<InventoryBatchResponse>,
    val history: List<InventoryHistoryResponse>,
)
