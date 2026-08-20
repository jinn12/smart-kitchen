package com.smartkitchen.backend.recipe

import org.springframework.http.HttpStatus
import org.springframework.security.core.Authentication
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.ResponseStatus
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/api/recipes")
class RecipeController(
    private val recipeService: RecipeService,
) {

    /** principal에는 JwtAuthFilter가 넣어둔 userId(Long)가 들어있다 */
    @GetMapping
    fun list(authentication: Authentication): List<RecipeSummary> =
        recipeService.list(authentication.principal as Long)

    @GetMapping("/{id}")
    fun detail(
        authentication: Authentication,
        @PathVariable id: Long,
    ): RecipeDetailResponse =
        recipeService.detail(authentication.principal as Long, id)

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    fun create(
        authentication: Authentication,
        @RequestBody request: RecipeCreateRequest,
    ): RecipeDetailResponse =
        recipeService.create(authentication.principal as Long, request)
}
