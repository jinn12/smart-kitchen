package com.smartkitchen.backend.common

import jakarta.servlet.http.HttpServletRequest
import org.slf4j.LoggerFactory
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.http.converter.HttpMessageNotReadableException
import org.springframework.web.HttpRequestMethodNotSupportedException
import org.springframework.web.bind.MethodArgumentNotValidException
import org.springframework.web.bind.MissingServletRequestParameterException
import org.springframework.web.bind.annotation.ExceptionHandler
import org.springframework.web.bind.annotation.RestControllerAdvice
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException
import org.springframework.web.server.ResponseStatusException
import org.springframework.web.servlet.NoHandlerFoundException
import org.springframework.web.servlet.resource.NoResourceFoundException

@RestControllerAdvice
class GlobalExceptionHandler {

    private val log = LoggerFactory.getLogger(javaClass)

    /** 없는 경로. NoResourceFoundException이 ResponseStatusException을 상속하므로 먼저 잡는다 */
    @ExceptionHandler(NoResourceFoundException::class, NoHandlerFoundException::class)
    fun handleNotFound(e: Exception, request: HttpServletRequest): ResponseEntity<ErrorResponse> =
        build(HttpStatus.NOT_FOUND, "요청한 경로를 찾을 수 없습니다", request)

    /** 서비스가 던진 오류. 상태 코드와 한국어 사유를 그대로 내보낸다 */
    @ExceptionHandler(ResponseStatusException::class)
    fun handleResponseStatus(
        e: ResponseStatusException,
        request: HttpServletRequest,
    ): ResponseEntity<ErrorResponse> {
        val status = HttpStatus.valueOf(e.statusCode.value())
        return build(status, e.reason ?: status.reasonPhrase, request)
    }

    /** 본문 JSON이 깨졌거나 enum·숫자 타입이 맞지 않는 경우 */
    @ExceptionHandler(
        HttpMessageNotReadableException::class,
        MethodArgumentTypeMismatchException::class,
        MissingServletRequestParameterException::class,
        MethodArgumentNotValidException::class,
    )
    fun handleBadRequest(e: Exception, request: HttpServletRequest): ResponseEntity<ErrorResponse> {
        // 파싱 실패 원인은 내부 정보라 로그로만 남긴다
        log.debug("요청 형식 오류 {} : {}", request.requestURI, e.message)
        return build(HttpStatus.BAD_REQUEST, "요청 형식이 올바르지 않습니다", request)
    }

    @ExceptionHandler(HttpRequestMethodNotSupportedException::class)
    fun handleMethodNotAllowed(
        e: HttpRequestMethodNotSupportedException,
        request: HttpServletRequest,
    ): ResponseEntity<ErrorResponse> =
        build(HttpStatus.METHOD_NOT_ALLOWED, "지원하지 않는 요청 방식입니다", request)

    /**
     * 예상하지 못한 모든 예외. 내부 메시지·스택은 응답에 담지 않고 로그에만 남긴다.
     * 여기서 새는 한 줄이 DB 구조나 라이브러리 버전을 알려주는 단서가 된다.
     */
    @ExceptionHandler(Exception::class)
    fun handleUnexpected(e: Exception, request: HttpServletRequest): ResponseEntity<ErrorResponse> {
        log.error("처리되지 않은 예외 {} {}", request.method, request.requestURI, e)
        return build(HttpStatus.INTERNAL_SERVER_ERROR, "서버 오류가 발생했습니다", request)
    }

    private fun build(
        status: HttpStatus,
        message: String,
        request: HttpServletRequest,
    ): ResponseEntity<ErrorResponse> =
        ResponseEntity.status(status).body(ErrorResponse.of(status, message, request.requestURI))
}
