package com.smartkitchen.backend.mealplan

import com.smartkitchen.backend.domain.MealPlanStatus
import com.smartkitchen.backend.domain.MealType
import com.smartkitchen.backend.domain.UnitType
import java.math.BigDecimal
import java.time.LocalDate

// ---------------------------------------------------------------- 미리보기 (API-41)

data class MealPlanPreviewRequest(
    val recipeId: Long,
    /** 생략 시 recipe.servings */
    val servings: Int? = null,
)

data class PreviewIngredientResponse(
    val ingredientId: Long,
    val name: String,
    val unitType: UnitType,
    /** 재료량 × (servings ÷ recipe.servings) (D-015) */
    val requiredQuantity: BigDecimal,
    val availableQuantity: BigDecimal,
    val shortageQuantity: BigDecimal,
    /** false면 계량 제외 — 예약·부족 판단에서 빠진다 (R-4) */
    val trackable: Boolean,
)

data class MealPlanPreviewResponse(
    val recipeId: Long,
    val recipeName: String,
    val recipeServings: Int,
    val servings: Int,
    /** 부족한 재료 수 (계량 제외 재료는 세지 않는다) */
    val shortageCount: Int,
    val ingredients: List<PreviewIngredientResponse>,
)

// ---------------------------------------------------------------- 등록·상세 (API-42)

data class MealPlanCreateRequest(
    val recipeId: Long,
    val planDate: LocalDate,
    val mealType: MealType,
    val servings: Int? = null,
    /** 부족분을 장보기에 담을 재료. 항목별 선택 (D-010) */
    val addToShoppingIngredientIds: List<Long> = emptyList(),
)

data class MealPlanIngredientResponse(
    val ingredientId: Long,
    val name: String,
    val unitType: UnitType,
    val requiredQuantity: BigDecimal,
    /** 예약된 양 = min(필요량, 등록 시점 가용량). 취소는 이 값으로 원복한다 (R-1) */
    val reservedQuantity: BigDecimal,
    val shortageQuantity: BigDecimal,
    val trackable: Boolean,
    val addedToShoppingList: Boolean,
)

data class MealPlanDetailResponse(
    val id: Long,
    val planDate: LocalDate,
    val mealType: MealType,
    val recipeId: Long,
    val recipeName: String,
    val servings: Int,
    val status: MealPlanStatus,
    val ingredients: List<MealPlanIngredientResponse>,
)

// ---------------------------------------------------------------- 주간 식탁 (API-40)

data class MealSummaryResponse(
    val id: Long,
    val mealType: MealType,
    val recipeName: String,
    val servings: Int,
    val status: MealPlanStatus,
)

data class MealPlanDayResponse(
    val date: LocalDate,
    val meals: List<MealSummaryResponse>,
)

// ---------------------------------------------------------------- 취소 (API-43)

data class MealPlanCancelResponse(
    val id: Long,
    val status: MealPlanStatus,
    /** 되돌린 재료 수 */
    val releasedIngredientCount: Int,
)
