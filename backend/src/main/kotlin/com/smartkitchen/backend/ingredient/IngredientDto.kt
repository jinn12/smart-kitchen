package com.smartkitchen.backend.ingredient

import com.smartkitchen.backend.domain.Ingredient
import com.smartkitchen.backend.domain.StorageLocation
import com.smartkitchen.backend.domain.UnitType
import java.math.BigDecimal

/** 커스텀 식재료 등록 (API-11). nullable 여부는 ERD의 ingredient 컬럼 정의를 따른다 */
data class IngredientCreateRequest(
    val name: String,
    val category: String,
    val unitType: UnitType,
    val defaultStorage: StorageLocation,
    val packageName: String? = null,
    val packageSize: BigDecimal? = null,
    val defaultShelfLifeDays: Int? = null,
    val isTrackable: Boolean = true,
)

data class IngredientResponse(
    val id: Long,
    val name: String,
    val category: String,
    val unitType: UnitType,
    /** 재고 등록 시 이 값으로 초기화된다 (S-13에서 "냉장에 보관됩니다"로 미리 보여주기 위한 값) */
    val defaultStorage: StorageLocation,
    val defaultShelfLifeDays: Int?, // 미지정 마스터 항목이 있어 null 허용
    val isTrackable: Boolean,
    val isCustom: Boolean,
)

/** isCustom은 household 보유 여부로 판단한다 (household IS NULL = 시스템 마스터, D-005) */
fun Ingredient.toResponse(): IngredientResponse =
    IngredientResponse(
        id = id!!,
        name = name,
        category = category,
        unitType = unitType,
        defaultStorage = defaultStorage,
        defaultShelfLifeDays = defaultShelfLifeDays,
        isTrackable = isTrackable,
        isCustom = household != null,
    )
