package com.smartkitchen.backend.batch

import org.springframework.scheduling.annotation.Scheduled
import org.springframework.stereotype.Component
import java.time.LocalDate

/**
 * 배치 2종의 트리거 (R-6). 로직은 서비스가 갖고 여기서는 시각만 정한다 —
 * 그래야 cron을 기다리지 않고 서비스 메서드로 검증할 수 있다.
 */
@Component
class BatchScheduler(
    private val confirmPlansService: ConfirmPlansService,
    private val expirySummaryService: ExpirySummaryService,
) {
    /** 매일 00:10 — 날짜 지난 PLANNED 계획을 FEFO 차감으로 확정 */
    @Scheduled(cron = "0 10 0 * * *", zone = ZONE)
    fun confirmDuePlans() {
        confirmPlansService.run(LocalDate.now())
    }

    /** 매일 09:00 — 임박·만료 항목이 있는 가구에 요약 1건 */
    @Scheduled(cron = "0 0 9 * * *", zone = ZONE)
    fun notifyExpiring() {
        expirySummaryService.run()
    }

    companion object {
        private const val ZONE = "Asia/Seoul"
    }
}
