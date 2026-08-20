package com.smartkitchen.backend.recipe

import com.smartkitchen.backend.domain.RecipeMaster
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param

interface RecipeMasterRepository : JpaRepository<RecipeMaster, Long> {

    /**
     * 공공 레시피 검색. 시스템 데이터라 household 스코프가 없다.
     * CAST(... AS String)은 필수 — 없으면 null 바인딩 시 PostgreSQL이 파라미터 타입을
     * 추론하지 못한다 (IngredientRepository.search와 동일).
     */
    @Query(
        value = """
        SELECT rm FROM RecipeMaster rm
        WHERE (CAST(:keyword AS String) IS NULL OR rm.name LIKE CONCAT('%', CAST(:keyword AS String), '%'))
          AND (CAST(:category AS String) IS NULL OR rm.category = CAST(:category AS String))
        ORDER BY rm.name ASC
        """,
        countQuery = """
        SELECT COUNT(rm) FROM RecipeMaster rm
        WHERE (CAST(:keyword AS String) IS NULL OR rm.name LIKE CONCAT('%', CAST(:keyword AS String), '%'))
          AND (CAST(:category AS String) IS NULL OR rm.category = CAST(:category AS String))
        """,
    )
    fun search(
        @Param("keyword") keyword: String?,
        @Param("category") category: String?,
        pageable: Pageable,
    ): Page<RecipeMaster>
}
