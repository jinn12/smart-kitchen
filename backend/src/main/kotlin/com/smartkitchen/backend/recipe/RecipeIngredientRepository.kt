package com.smartkitchen.backend.recipe

import com.smartkitchen.backend.domain.RecipeIngredient
import org.springframework.data.jpa.repository.EntityGraph
import org.springframework.data.jpa.repository.JpaRepository

interface RecipeIngredientRepository : JpaRepository<RecipeIngredient, Long> {

    /** 목록의 cookableNow 계산용. 요리 N건의 재료를 한 번에 가져온다 (N+1 방지) */
    @EntityGraph(attributePaths = ["ingredient"])
    fun findByRecipeIdIn(recipeIds: Collection<Long>): List<RecipeIngredient>

    @EntityGraph(attributePaths = ["ingredient"])
    fun findByRecipeIdOrderByIdAsc(recipeId: Long): List<RecipeIngredient>
}
