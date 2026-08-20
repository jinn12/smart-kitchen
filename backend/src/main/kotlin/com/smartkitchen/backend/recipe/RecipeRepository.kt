package com.smartkitchen.backend.recipe

import com.smartkitchen.backend.domain.Recipe
import org.springframework.data.jpa.repository.JpaRepository

interface RecipeRepository : JpaRepository<Recipe, Long> {

    fun findByHouseholdIdOrderByNameAsc(householdId: Long): List<Recipe>

    /** 없는 요리와 남의 household 요리를 같은 null로 만든다 (D-022) */
    fun findByIdAndHouseholdId(id: Long, householdId: Long): Recipe?
}
