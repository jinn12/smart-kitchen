package com.smartkitchen.backend.inventory

import com.smartkitchen.backend.domain.Inventory
import com.smartkitchen.backend.domain.StorageLocation
import jakarta.persistence.LockModeType
import org.springframework.data.jpa.repository.EntityGraph
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Lock
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param

interface InventoryRepository : JpaRepository<Inventory, Long> {

    /** 재료당 1행 (ERD의 UNIQUE(household_id, ingredient_id)) */
    @EntityGraph(attributePaths = ["ingredient"])
    fun findByHouseholdIdAndIngredientId(householdId: Long, ingredientId: Long): Inventory?

    /** 보관 장소 필터 없음. 이름 표시에 쓰므로 ingredient를 함께 로드한다 */
    @EntityGraph(attributePaths = ["ingredient"])
    fun findByHouseholdIdOrderByIngredientNameAsc(householdId: Long): List<Inventory>

    @EntityGraph(attributePaths = ["ingredient"])
    fun findByHouseholdIdAndStorageLocationOrderByIngredientNameAsc(
        householdId: Long,
        storageLocation: StorageLocation,
    ): List<Inventory>

    /**
     * 예약 증감(R-1)용 행 잠금. 가용량을 읽고 min을 계산해 다시 쓰는 read-compute-write라
     * 잠금 없이는 동시 요청이 같은 가용량을 보고 각자 예약해 reserved가 quantity를 넘을 수 있다.
     * ingredient.id 오름차순으로 잠가 계획 간 교착을 막는다.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query(
        """
        SELECT i FROM Inventory i
        WHERE i.household.id = :householdId AND i.ingredient.id IN :ingredientIds
        ORDER BY i.ingredient.id ASC
        """
    )
    fun lockByIngredientIds(
        @Param("householdId") householdId: Long,
        @Param("ingredientIds") ingredientIds: Collection<Long>,
    ): List<Inventory>
}
