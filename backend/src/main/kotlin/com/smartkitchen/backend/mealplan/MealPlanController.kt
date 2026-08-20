package com.smartkitchen.backend.mealplan

import org.springframework.format.annotation.DateTimeFormat
import org.springframework.http.HttpStatus
import org.springframework.security.core.Authentication
import org.springframework.web.bind.annotation.DeleteMapping
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.ResponseStatus
import org.springframework.web.bind.annotation.RestController
import java.time.LocalDate

@RestController
@RequestMapping("/api/meal-plans")
class MealPlanController(
    private val mealPlanService: MealPlanService,
) {

    /** principal에는 JwtAuthFilter가 넣어둔 userId(Long)가 들어있다 */
    @GetMapping
    fun weekly(
        authentication: Authentication,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) from: LocalDate?,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) to: LocalDate?,
    ): List<MealPlanDayResponse> =
        mealPlanService.weekly(authentication.principal as Long, from, to)

    /** 등록 전 부족 안내. 조회만 하고 아무것도 바꾸지 않는다 (D-010) */
    @PostMapping("/preview")
    fun preview(
        authentication: Authentication,
        @RequestBody request: MealPlanPreviewRequest,
    ): MealPlanPreviewResponse =
        mealPlanService.preview(authentication.principal as Long, request)

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    fun create(
        authentication: Authentication,
        @RequestBody request: MealPlanCreateRequest,
    ): MealPlanDetailResponse =
        mealPlanService.create(authentication.principal as Long, request)

    @DeleteMapping("/{id}")
    fun cancel(
        authentication: Authentication,
        @PathVariable id: Long,
    ): MealPlanCancelResponse =
        mealPlanService.cancel(authentication.principal as Long, id)
}
