package com.smartkitchen.backend.domain

/**
 * inventory_history.ref_type 값 (D-027).
 * FK가 아닌 논리 참조라 컬럼은 문자열이지만, 값은 여기 모아 오타를 막는다.
 */
object InventoryRefType {
    /** 확정 배치의 CONSUME — refId는 meal_plan.id (R-6) */
    const val MEAL_PLAN = "MEAL_PLAN"

    /** 구매 완료(API-53)의 PURCHASE — refId는 shopping_list.id */
    const val SHOPPING_LIST = "SHOPPING_LIST"
}
