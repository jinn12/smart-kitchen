package com.smartkitchen.backend.inventory

import com.smartkitchen.backend.domain.Inventory
import com.smartkitchen.backend.domain.StorageLocation
import org.springframework.data.jpa.repository.EntityGraph
import org.springframework.data.jpa.repository.JpaRepository

interface InventoryRepository : JpaRepository<Inventory, Long> {

    /** 재료당 1행 (ERD의 UNIQUE(household_id, ingredient_id)) */
    fun findByHouseholdIdAndIngredientId(householdId: Long, ingredientId: Long): Inventory?

    /** 보관 장소 필터 없음. 이름 표시에 쓰므로 ingredient를 함께 로드한다 */
    @EntityGraph(attributePaths = ["ingredient"])
    fun findByHouseholdIdOrderByIngredientNameAsc(householdId: Long): List<Inventory>

    @EntityGraph(attributePaths = ["ingredient"])
    fun findByHouseholdIdAndStorageLocationOrderByIngredientNameAsc(
        householdId: Long,
        storageLocation: StorageLocation,
    ): List<Inventory>
}
