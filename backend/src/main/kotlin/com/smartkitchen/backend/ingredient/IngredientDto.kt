package com.smartkitchen.backend.ingredient

import com.smartkitchen.backend.domain.Ingredient
import com.smartkitchen.backend.domain.UnitType

data class IngredientResponse(
    val id: Long,
    val name: String,
    val category: String,
    val unitType: UnitType,
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
        defaultShelfLifeDays = defaultShelfLifeDays,
        isTrackable = isTrackable,
        isCustom = household != null,
    )
