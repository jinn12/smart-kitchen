package com.smartkitchen.backend.mealplan

import com.smartkitchen.backend.domain.MealPlanItem
import org.springframework.data.jpa.repository.EntityGraph
import org.springframework.data.jpa.repository.JpaRepository

interface MealPlanItemRepository : JpaRepository<MealPlanItem, Long> {

    /** 취소 시 이 스냅샷의 reservedQty 그대로 되돌린다 — 재계산하지 않는다 (R-1) */
    @EntityGraph(attributePaths = ["ingredient"])
    fun findByMealPlanIdOrderByIdAsc(mealPlanId: Long): List<MealPlanItem>
}
