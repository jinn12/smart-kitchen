package com.smartkitchen.backend.shopping

import com.smartkitchen.backend.domain.ShoppingListItem
import org.springframework.data.jpa.repository.EntityGraph
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param

interface ShoppingListItemRepository : JpaRepository<ShoppingListItem, Long> {

    /** 표시에 재료 정보(단위·포장)를 쓰므로 함께 로드한다 */
    @EntityGraph(attributePaths = ["ingredient"])
    fun findByShoppingListId(shoppingListId: Long): List<ShoppingListItem>

    /** UNIQUE(list_id, ingredient_id)라 재료당 1행. 병합 대상 조회용 */
    @EntityGraph(attributePaths = ["ingredient"])
    fun findByShoppingListIdAndIngredientIdIn(
        shoppingListId: Long,
        ingredientIds: Collection<Long>,
    ): List<ShoppingListItem>

    /**
     * 항목 단건을 household 스코프로 조회한다.
     * 없는 id와 남의 household 항목이 똑같이 null이 되므로 존재 여부가 드러나지 않는다 (D-022).
     */
    @Query(
        """
        SELECT si FROM ShoppingListItem si
        JOIN FETCH si.ingredient
        JOIN si.shoppingList sl
        WHERE si.id = :id AND sl.household.id = :householdId
        """
    )
    fun findAccessible(@Param("id") id: Long, @Param("householdId") householdId: Long): ShoppingListItem?
}
