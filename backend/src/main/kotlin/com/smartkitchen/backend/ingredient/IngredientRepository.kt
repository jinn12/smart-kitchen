package com.smartkitchen.backend.ingredient

import com.smartkitchen.backend.domain.Ingredient
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param

interface IngredientRepository : JpaRepository<Ingredient, Long> {

    /**
     * 마스터(household IS NULL) + 요청자 household의 커스텀만 조회 (D-006).
     * keyword·category는 선택. null이면 해당 조건을 적용하지 않는다.
     *
     * CAST(... AS String)은 필수. 없으면 null 바인딩 시 PostgreSQL이 파라미터 타입을
     * 추론하지 못해 "연산자 없음: character varying ~~ bytea"로 실패한다.
     */
    @Query(
        """
        SELECT i FROM Ingredient i
        WHERE (i.household IS NULL OR i.household.id = :householdId)
          AND (CAST(:keyword AS String) IS NULL OR i.name LIKE CONCAT('%', CAST(:keyword AS String), '%'))
          AND (CAST(:category AS String) IS NULL OR i.category = CAST(:category AS String))
        ORDER BY i.name ASC
        """
    )
    fun search(
        @Param("householdId") householdId: Long,
        @Param("keyword") keyword: String?,
        @Param("category") category: String?,
    ): List<Ingredient>

    /** 같은 household 안에서의 커스텀 이름 중복 검사. 마스터와 같은 이름은 허용한다 */
    fun existsByHouseholdIdAndName(householdId: Long, name: String): Boolean

    /** 요청자가 쓸 수 있는 식재료(마스터 + 내 커스텀)만 한 번에 조회 (D-006) */
    @Query(
        """
        SELECT i FROM Ingredient i
        WHERE i.id IN :ids
          AND (i.household IS NULL OR i.household.id = :householdId)
        """
    )
    fun findAllAccessible(
        @Param("ids") ids: Collection<Long>,
        @Param("householdId") householdId: Long,
    ): List<Ingredient>
}
