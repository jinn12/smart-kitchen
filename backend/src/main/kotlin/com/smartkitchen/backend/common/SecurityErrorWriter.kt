package com.smartkitchen.backend.common

import jakarta.servlet.http.HttpServletRequest
import jakarta.servlet.http.HttpServletResponse
import org.springframework.http.HttpStatus
import org.springframework.http.MediaType
import org.springframework.security.access.AccessDeniedException
import org.springframework.security.core.AuthenticationException
import org.springframework.security.web.AuthenticationEntryPoint
import org.springframework.security.web.access.AccessDeniedHandler
import org.springframework.stereotype.Component
import tools.jackson.databind.ObjectMapper

/**
 * 보안 필터 단계의 오류는 DispatcherServlet에 닿지 않아 @RestControllerAdvice가 잡지 못한다.
 * 그래서 여기서 같은 ErrorResponse 형태로 직접 써 준다 — 응답 형식이 갈리지 않게.
 */
@Component
class SecurityErrorWriter(
    private val objectMapper: ObjectMapper,
) {
    fun write(response: HttpServletResponse, request: HttpServletRequest, status: HttpStatus, message: String) {
        response.status = status.value()
        response.contentType = MediaType.APPLICATION_JSON_VALUE
        response.characterEncoding = Charsets.UTF_8.name()
        objectMapper.writeValue(
            response.writer,
            ErrorResponse.of(status, message, request.requestURI),
        )
    }
}

/** 인증되지 않은 요청 — 토큰 없음·위조·만료. 403이 아니라 401이 맞다 */
@Component
class JwtAuthenticationEntryPoint(
    private val writer: SecurityErrorWriter,
) : AuthenticationEntryPoint {
    override fun commence(
        request: HttpServletRequest,
        response: HttpServletResponse,
        authException: AuthenticationException,
    ) {
        writer.write(response, request, HttpStatus.UNAUTHORIZED, "인증이 필요합니다")
    }
}

/**
 * 인증은 됐는데 권한이 모자란 경우. 역할 체계가 아직 없어 실제로는 타지 않지만,
 * 401과 403의 구분을 코드에 남겨 둔다.
 */
@Component
class JwtAccessDeniedHandler(
    private val writer: SecurityErrorWriter,
) : AccessDeniedHandler {
    override fun handle(
        request: HttpServletRequest,
        response: HttpServletResponse,
        accessDeniedException: AccessDeniedException,
    ) {
        writer.write(response, request, HttpStatus.FORBIDDEN, "접근 권한이 없습니다")
    }
}
