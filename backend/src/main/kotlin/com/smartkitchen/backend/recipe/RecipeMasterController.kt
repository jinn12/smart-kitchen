package com.smartkitchen.backend.recipe

import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController

/** 공공 레시피 조회 (API-33, 34). 인증은 필요하나 household 스코프는 없다 */
@RestController
@RequestMapping("/api/recipe-masters")
class RecipeMasterController(
    private val recipeMasterService: RecipeMasterService,
) {

    @GetMapping
    fun search(
        @RequestParam(required = false) keyword: String?,
        @RequestParam(required = false) category: String?,
        @RequestParam(defaultValue = "0") page: Int,
        @RequestParam(defaultValue = "20") size: Int,
    ): RecipeMasterPage =
        recipeMasterService.search(keyword, category, page, size)

    @GetMapping("/{id}")
    fun detail(@PathVariable id: Long): RecipeMasterDetailResponse =
        recipeMasterService.detail(id)
}
