package com.smartkitchen.backend.batch

import com.smartkitchen.backend.domain.InventoryHistory
import com.smartkitchen.backend.domain.InventoryHistoryType
import com.smartkitchen.backend.domain.InventoryRefType
import com.smartkitchen.backend.domain.MealPlanStatus
import com.smartkitchen.backend.inventory.InventoryHistoryRepository
import com.smartkitchen.backend.inventory.InventoryItemRepository
import com.smartkitchen.backend.inventory.InventoryRepository
import com.smartkitchen.backend.mealplan.MealPlanItemRepository
import com.smartkitchen.backend.mealplan.MealPlanRepository
import org.springframework.stereotype.Component
import org.springframework.transaction.annotation.Transactional
import java.math.BigDecimal

/** 계획 하나의 확정 결과 */
data class PlanConfirmResult(
    val planId: Long,
    val confirmed: Boolean,
    val consumedIngredientCount: Int,
    val totalConsumed: BigDecimal,
)

/**
 * 계획 1건을 확정한다 (R-1 확정, R-2 FEFO, R-6).
 * 계획 단위 트랜잭션이라 한 건이 실패해도 다른 계획에 영향을 주지 않도록
 * 반복문을 도는 쪽(ConfirmPlansService)과 별도 빈으로 나눠 둔다 — 자기호출이면 트랜잭션이 걸리지 않는다.
 */
@Component
class PlanConfirmer(
    private val mealPlanRepository: MealPlanRepository,
    private val mealPlanItemRepository: MealPlanItemRepository,
    private val inventoryRepository: InventoryRepository,
    private val inventoryItemRepository: InventoryItemRepository,
    private val inventoryHistoryRepository: InventoryHistoryRepository,
) {
    @Transactional
    fun confirm(planId: Long): PlanConfirmResult {
        val plan = mealPlanRepository.findById(planId).orElse(null)
            ?: return PlanConfirmResult(planId, false, 0, BigDecimal.ZERO)
        // 이미 확정·취소된 계획은 건드리지 않는다 (재실행 멱등성)
        if (plan.status != MealPlanStatus.PLANNED) {
            return PlanConfirmResult(planId, false, 0, BigDecimal.ZERO)
        }

        val household = plan.household
        val items = mealPlanItemRepository.findByMealPlanIdOrderByIdAsc(planId)
        val locked = if (items.isEmpty()) {
            emptyMap()
        } else {
            inventoryRepository
                .lockByIngredientIds(household.id!!, items.map { it.ingredient.id!! })
                .associateBy { it.ingredient.id!! }
        }

        var consumedCount = 0
        var total = BigDecimal.ZERO

        for (item in items) {
            val inventory = locked[item.ingredient.id!!] ?: continue

            // 등록 후 재고가 줄었을 수 있다(API-23). 실물보다 많이 깎지 않는다
            val consumable = item.reservedQty.min(inventory.quantity).max(BigDecimal.ZERO)
            var remaining = consumable

            // FEFO: 유통기한 이른 배치부터. findActiveBatches가 그 순서를 준다 (R-2)
            for (batch in inventoryItemRepository.findActiveBatches(inventory.id!!)) {
                if (remaining <= BigDecimal.ZERO) break
                val take = remaining.min(batch.quantity)
                batch.quantity = batch.quantity.subtract(take)
                remaining = remaining.subtract(take)
            }
            // 배치 합계가 inventory.quantity보다 적을 수도 있어 실제 깎은 양으로 기록한다
            val deducted = consumable.subtract(remaining)

            // 예약은 스냅샷 전액을 해제한다 (차감량과 별개)
            inventory.reservedQuantity =
                inventory.reservedQuantity.subtract(item.reservedQty).max(BigDecimal.ZERO)
            inventory.quantity = inventoryItemRepository.sumQuantity(inventory.id!!)

            if (deducted > BigDecimal.ZERO) {
                inventoryHistoryRepository.save(
                    InventoryHistory(
                        household = household,
                        ingredient = item.ingredient,
                        type = InventoryHistoryType.CONSUME,
                        quantity = deducted.negate(),   // 감소는 −
                        refType = InventoryRefType.MEAL_PLAN,
                        refId = planId,
                    )
                )
                consumedCount++
                total = total.add(deducted)
            }
        }

        plan.status = MealPlanStatus.CONFIRMED
        return PlanConfirmResult(planId, true, consumedCount, total)
    }
}
