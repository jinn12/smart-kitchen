package com.smartkitchen.backend.inventory

import com.smartkitchen.backend.domain.InventoryItem
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import java.math.BigDecimal
import java.time.LocalDate

/** 재고별 가장 임박한 유통기한 (D-배지용, R-5) */
interface NearestExpiryRow {
    val inventoryId: Long
    val nearestExpiryDate: LocalDate?
}

interface InventoryItemRepository : JpaRepository<InventoryItem, Long> {

    /**
     * 소진되지 않은(quantity > 0) 배치만 대상으로 한다 (R-2).
     * MIN은 NULL을 무시하므로 유통기한 없는 배치는 자연히 제외된다 (FEFO 마지막 순서와 일관).
     */
    @Query(
        """
        SELECT b.inventory.id AS inventoryId, MIN(b.expiryDate) AS nearestExpiryDate
        FROM InventoryItem b
        WHERE b.inventory.id IN :inventoryIds
          AND b.quantity > 0
        GROUP BY b.inventory.id
        """
    )
    fun findNearestExpiry(@Param("inventoryIds") inventoryIds: Collection<Long>): List<NearestExpiryRow>

    /** 상세 화면의 배치 목록. FEFO 차감 순서 그대로 내려준다 (R-2) */
    @Query(
        """
        SELECT b FROM InventoryItem b
        WHERE b.inventory.id = :inventoryId
          AND b.quantity > 0
        ORDER BY b.expiryDate ASC NULLS LAST, b.purchasedAt ASC, b.id ASC
        """
    )
    fun findActiveBatches(@Param("inventoryId") inventoryId: Long): List<InventoryItem>

    /**
     * 배치 단건을 household 스코프로 조회한다 (D-006).
     * 없는 id와 남의 household 배치가 똑같이 null이 되므로 존재 여부가 드러나지 않는다.
     */
    @Query(
        """
        SELECT b FROM InventoryItem b
        JOIN FETCH b.inventory i
        JOIN FETCH i.ingredient
        WHERE b.id = :id AND i.household.id = :householdId
        """
    )
    fun findAccessible(@Param("id") id: Long, @Param("householdId") householdId: Long): InventoryItem?

    /** 배치 변경 후 inventory.quantity 재계산용 (ERD: quantity = 배치 합계) */
    @Query("SELECT COALESCE(SUM(b.quantity), 0) FROM InventoryItem b WHERE b.inventory.id = :inventoryId")
    fun sumQuantity(@Param("inventoryId") inventoryId: Long): BigDecimal
}
