package com.smartkitchen.backend.recipe

import com.smartkitchen.backend.domain.RecipeMasterIngredient
import org.springframework.data.jpa.repository.EntityGraph
import org.springframework.data.jpa.repository.JpaRepository

interface RecipeMasterIngredientRepository : JpaRepository<RecipeMasterIngredient, Long> {

    /** 매핑 확인 화면용. matchedIngredient는 NULL일 수 있고, 그 항목이 사용자 지정 대상이다 (D-007) */
    @EntityGraph(attributePaths = ["matchedIngredient"])
    fun findByRecipeMasterIdOrderByIdAsc(recipeMasterId: Long): List<RecipeMasterIngredient>
}
