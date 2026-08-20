package com.smartkitchen.backend.ingredient

import org.springframework.http.HttpStatus
import org.springframework.security.core.Authentication
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.ResponseStatus
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/api/ingredients")
class IngredientController(
    private val ingredientService: IngredientService,
) {

    /** principal에는 JwtAuthFilter가 넣어둔 userId(Long)가 들어있다 */
    @GetMapping
    fun search(
        authentication: Authentication,
        @RequestParam(required = false) keyword: String?,
        @RequestParam(required = false) category: String?,
    ): List<IngredientResponse> =
        ingredientService.search(authentication.principal as Long, keyword, category)

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    fun create(
        authentication: Authentication,
        @RequestBody request: IngredientCreateRequest,
    ): IngredientResponse =
        ingredientService.create(authentication.principal as Long, request)
}
