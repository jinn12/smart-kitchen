package com.smartkitchen.backend.batch

import com.smartkitchen.backend.domain.MealPlanStatus
import com.smartkitchen.backend.mealplan.MealPlanRepository
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service
import java.math.BigDecimal
import java.time.LocalDate

data class ConfirmBatchResult(
    val targetDate: LocalDate,
    val targetCount: Int,
    val confirmedCount: Int,
    val failedCount: Int,
    val totalConsumed: BigDecimal,
)

/**
 * 예약 확정 배치 (매일 00:10, R-6).
 * 날짜가 지난 PLANNED 계획의 예약분을 FEFO 차감으로 확정한다 (D-002).
 * 반복문 자체는 트랜잭션이 아니다 — 계획 1건이 실패해도 나머지는 계속 처리한다.
 */
@Service
class ConfirmPlansService(
    private val mealPlanRepository: MealPlanRepository,
    private val planConfirmer: PlanConfirmer,
) {
    private val log = LoggerFactory.getLogger(javaClass)

    fun run(today: LocalDate = LocalDate.now()): ConfirmBatchResult {
        val targets = mealPlanRepository.findByStatusAndPlanDateBefore(MealPlanStatus.PLANNED, today)
        var confirmed = 0
        var failed = 0
        var total = BigDecimal.ZERO

        for (plan in targets) {
            try {
                val result = planConfirmer.confirm(plan.id!!)
                if (result.confirmed) {
                    confirmed++
                    total = total.add(result.totalConsumed)
                }
            } catch (e: Exception) {
                failed++
                log.error("계획 확정 실패 planId={} : {}", plan.id, e.message, e)
            }
        }

        val result = ConfirmBatchResult(today, targets.size, confirmed, failed, total)
        log.info(
            "예약 확정 배치 완료 — 기준일 {} / 대상 {}건 / 확정 {}건 / 실패 {}건 / 차감 합계 {}",
            today, targets.size, confirmed, failed, total,
        )
        return result
    }
}
