package com.smartkitchen.backend.shopping

import com.smartkitchen.backend.domain.ShoppingList
import org.springframework.data.jpa.repository.JpaRepository

/** 가구당 1개 (D-009, ERD의 household_id UNIQUE). 없으면 첫 사용 시 만든다 */
interface ShoppingListRepository : JpaRepository<ShoppingList, Long> {
    fun findByHouseholdId(householdId: Long): ShoppingList?
}
