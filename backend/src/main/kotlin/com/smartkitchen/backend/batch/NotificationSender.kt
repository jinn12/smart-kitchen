package com.smartkitchen.backend.batch

import org.slf4j.LoggerFactory
import org.springframework.stereotype.Component

/** 가구별 임박 요약 (D-013: 임박 또는 만료 항목이 있는 가구에만 하루 1건) */
data class ExpirySummary(
    val householdId: Long,
    val expiringCount: Int,
    val expiredCount: Int,
    /** 표시용 재료명 요약. 앞쪽 몇 건만 */
    val names: List<String>,
)

/**
 * 푸시 발송 창구. FCM 연동은 앱 개발 후에 붙이므로 지금은 로그 구현체만 둔다.
 * 인터페이스를 미리 갈라 두면 발송 채널이 바뀌어도 배치 로직은 그대로다.
 */
interface NotificationSender {
    fun sendExpirySummary(summary: ExpirySummary)
}

@Component
class LoggingNotificationSender : NotificationSender {
    private val log = LoggerFactory.getLogger(javaClass)

    override fun sendExpirySummary(summary: ExpirySummary) {
        log.info(
            "[임박 알림] 가구 {}: 임박 {}건, 만료 {}건 — {}",
            summary.householdId,
            summary.expiringCount,
            summary.expiredCount,
            summary.names.joinToString(", "),
        )
    }
}
