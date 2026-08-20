package com.smartkitchen.backend.mealplan

import com.smartkitchen.backend.domain.MealPlan
import com.smartkitchen.backend.domain.MealPlanStatus
import org.springframework.data.jpa.repository.EntityGraph
import org.springframework.data.jpa.repository.JpaRepository
import java.time.LocalDate

interface MealPlanRepository : JpaRepository<MealPlan, Long> {

    /** 주간 식탁. 요리명을 함께 쓰므로 recipe를 동반 로드한다 */
    @EntityGraph(attributePaths = ["recipe"])
    fun findByHouseholdIdAndPlanDateBetweenAndStatusIn(
        householdId: Long,
        from: LocalDate,
        to: LocalDate,
        statuses: Collection<MealPlanStatus>,
    ): List<MealPlan>

    /** 없는 계획과 남의 household 계획을 같은 null로 만든다 (D-022) */
    @EntityGraph(attributePaths = ["recipe"])
    fun findByIdAndHouseholdId(id: Long, householdId: Long): MealPlan?
}
