package com.smartkitchen.backend.common

import org.springframework.http.HttpStatus
import java.time.OffsetDateTime
import java.time.ZoneOffset

/**
 * 모든 오류 응답의 공통 본문.
 * 서비스가 던진 한국어 메시지를 message로 그대로 노출하되,
 * 예상 못 한 예외의 내부 메시지는 절대 담지 않는다 (GlobalExceptionHandler 참고).
 */
data class ErrorResponse(
    val timestamp: OffsetDateTime,
    val status: Int,
    val error: String,
    val message: String,
    val path: String,
) {
    companion object {
        fun of(status: HttpStatus, message: String, path: String): ErrorResponse =
            ErrorResponse(
                timestamp = OffsetDateTime.now(ZoneOffset.UTC),
                status = status.value(),
                error = status.reasonPhrase,
                message = message,
                path = path,
            )
    }
}
