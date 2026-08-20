package com.smartkitchen.backend.batch

import com.smartkitchen.backend.auth.HouseholdRepository
import com.smartkitchen.backend.inventory.ExpiryStatus
import com.smartkitchen.backend.inventory.InventoryService
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service

data class ExpiryBatchResult(
    val householdCount: Int,
    val notifiedCount: Int,
)

/**
 * 임박 요약 알림 배치 (매일 09:00, R-5·R-6).
 * 판정은 API-24와 같은 InventoryService.listExpiringByHousehold를 그대로 쓴다 —
 * 화면과 알림의 기준이 갈리지 않게 하기 위해서다 (D-013·D-020).
 */
@Service
class ExpirySummaryService(
    private val householdRepository: HouseholdRepository,
    private val inventoryService: InventoryService,
    private val notificationSender: NotificationSender,
) {
    private val log = LoggerFactory.getLogger(javaClass)

    fun run(): ExpiryBatchResult {
        val households = householdRepository.findAll()
        var notified = 0

        for (household in households) {
            val items = inventoryService.listExpiringByHousehold(household.id!!)
            // 대상이 없는 가구에는 보내지 않는다 (D-013)
            if (items.isEmpty()) continue

            notificationSender.sendExpirySummary(
                ExpirySummary(
                    householdId = household.id!!,
                    expiringCount = items.count { it.expiryStatus == ExpiryStatus.EXPIRING },
                    expiredCount = items.count { it.expiryStatus == ExpiryStatus.EXPIRED },
                    names = items.take(SUMMARY_NAME_LIMIT).map { it.name },
                )
            )
            notified++
        }

        log.info("임박 요약 배치 완료 — 가구 {}곳 중 {}곳 발송", households.size, notified)
        return ExpiryBatchResult(households.size, notified)
    }

    companion object {
        private const val SUMMARY_NAME_LIMIT = 5
    }
}
