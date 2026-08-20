package com.smartkitchen.backend.recipe

import com.smartkitchen.backend.domain.RecipeSource
import com.smartkitchen.backend.domain.UnitType
import java.math.BigDecimal

// ---------------------------------------------------------------- 공공 레시피 (API-33, 34)

/** 검색 결과 한 건 (API-33) */
data class RecipeMasterSummary(
    val id: Long,
    val name: String,
    val category: String,
    val cookWay: String?,
    val imageUrl: String?,
    val kcal1p: BigDecimal?,
)

/** 페이징 응답. 목록이 1,152건이라 totalCount를 함께 내려준다 */
data class RecipeMasterPage(
    val totalCount: Long,
    val page: Int,
    val size: Int,
    val items: List<RecipeMasterSummary>,
)

/** 매핑된 마스터 식재료. 실패분은 null이고 그 항목이 사용자 지정 대상이다 (D-007) */
data class MatchedIngredientResponse(
    val id: Long,
    val name: String,
    val unitType: UnitType,
)

data class RecipeMasterIngredientResponse(
    val rawText: String,
    val parsedName: String,
    val parsedQty: BigDecimal?,
    val parsedUnit: String?,
    val matchedIngredient: MatchedIngredientResponse?,
)

/** 재료 매핑 확인 화면 데이터 (API-34, 외부 API 검토 4절) */
data class RecipeMasterDetailResponse(
    val id: Long,
    val name: String,
    val category: String,
    val cookWay: String?,
    val imageUrl: String?,
    val kcal1p: BigDecimal?,
    /** 마스터는 1인분 기준이다 (D-015) */
    val servings: Int,
    val ingredients: List<RecipeMasterIngredientResponse>,
)

// ---------------------------------------------------------------- 내 요리 (API-30~32)

data class RecipeIngredientRequest(
    val ingredientId: Long,
    val quantity: BigDecimal,
)

/**
 * 요리 등록 (API-31).
 * MANUAL이면 name 필수, MASTER면 recipeMasterId 필수이고 name은 마스터에서 복사한다.
 * ingredients는 매핑 확인 화면에서 사용자가 확정한 최종 목록이다.
 */
data class RecipeCreateRequest(
    val source: RecipeSource,
    val name: String? = null,
    val recipeMasterId: Long? = null,
    /** 생략 시 1. 마스터 복제는 1인분 기준 (D-015) */
    val servings: Int? = null,
    val ingredients: List<RecipeIngredientRequest>,
)

/** 내 요리 목록 한 건 (API-30, S-21) */
data class RecipeSummary(
    val id: Long,
    val name: String,
    val servings: Int,
    val source: RecipeSource,
    val ingredientCount: Int,
    /** 레시피 기준 분량을 지금 재고로 만들 수 있는가. is_trackable=false 재료는 제외 (R-4) */
    val cookableNow: Boolean,
)

data class RecipeIngredientResponse(
    val ingredientId: Long,
    val name: String,
    val quantity: BigDecimal,
    val unitType: UnitType,
    /** 가용 = 재고 잔량 − 예약 (R-1). 재고가 없으면 0 */
    val availableQuantity: BigDecimal,
    /** 잔량 관리를 하지 않는 재료(R-4)는 판단하지 않고 null */
    val sufficient: Boolean?,
)

/** 내 요리 상세 (API-32) */
data class RecipeDetailResponse(
    val id: Long,
    val name: String,
    val servings: Int,
    val source: RecipeSource,
    val recipeMasterId: Long?,
    val cookableNow: Boolean,
    val ingredients: List<RecipeIngredientResponse>,
)
