package com.smartkitchen.backend.inventory

import com.smartkitchen.backend.domain.InventoryHistory
import org.springframework.data.jpa.repository.JpaRepository

/** 이력은 append-only (도메인 모델 정의서 4장) */
interface InventoryHistoryRepository : JpaRepository<InventoryHistory, Long> {

    /** 상세 화면의 변동 기록. 같은 트랜잭션에서 생긴 동시각 이력은 id로 안정 정렬한다 */
    fun findTop20ByHouseholdIdAndIngredientIdOrderByCreatedAtDescIdDesc(
        householdId: Long,
        ingredientId: Long,
    ): List<InventoryHistory>
}
