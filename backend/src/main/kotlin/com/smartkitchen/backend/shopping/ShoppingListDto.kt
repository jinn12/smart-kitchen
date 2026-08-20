package com.smartkitchen.backend.shopping

import com.smartkitchen.backend.domain.ShoppingItemSource
import com.smartkitchen.backend.domain.UnitType
import com.smartkitchen.backend.inventory.InventoryResponse
import java.math.BigDecimal

data class ShoppingListItemResponse(
    val id: Long,
    val ingredientId: Long,
    val name: String,
    val unitType: UnitType,
    val quantity: BigDecimal,
    val isChecked: Boolean,
    val source: ShoppingItemSource,
    /** 표시 전용 포장 단위. "두부 300g(1모)" 식으로 보여주기 위한 값 (D-004) */
    val packageName: String?,
    val packageSize: BigDecimal?,
)

/** 장보기 목록 (API-50, S-41). 미체크 먼저, 그 안에서 이름순 */
data class ShoppingListResponse(
    val id: Long,
    val items: List<ShoppingListItemResponse>,
)

data class ShoppingItemCreateRequest(
    val ingredientId: Long,
    val quantity: BigDecimal,
)

/** 온 필드만 반영한다 (API-52) */
data class ShoppingItemUpdateRequest(
    val isChecked: Boolean? = null,
    val quantity: BigDecimal? = null,
)

/** 구매 완료 결과 (API-53) */
data class ShoppingCompleteResponse(
    /** 재고에 반영된 결과 (API-20 항목 형태) */
    val inventories: List<InventoryResponse>,
    /** 체크하지 않아 목록에 남은 항목 수 */
    val carriedOverCount: Int,
)
