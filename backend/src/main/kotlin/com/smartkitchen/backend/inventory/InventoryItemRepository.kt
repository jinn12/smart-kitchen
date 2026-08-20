package com.smartkitchen.backend.inventory

import com.smartkitchen.backend.domain.InventoryItem
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
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
}
