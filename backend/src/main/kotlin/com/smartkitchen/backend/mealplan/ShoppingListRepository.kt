package com.smartkitchen.backend.mealplan

import com.smartkitchen.backend.domain.ShoppingList
import com.smartkitchen.backend.domain.ShoppingListItem
import org.springframework.data.jpa.repository.JpaRepository

/** 가구당 1개 (D-009). 없으면 계획 등록 시 만든다 */
interface ShoppingListRepository : JpaRepository<ShoppingList, Long> {
    fun findByHouseholdId(householdId: Long): ShoppingList?
}

interface ShoppingListItemRepository : JpaRepository<ShoppingListItem, Long> {
    /** UNIQUE(list_id, ingredient_id)라 재료당 1행. 중복 대신 수량을 합산한다 */
    fun findByShoppingListIdAndIngredientIdIn(
        shoppingListId: Long,
        ingredientIds: Collection<Long>,
    ): List<ShoppingListItem>
}
