package com.smartkitchen.backend.domain

/** 재고 변동 유형 */
enum class InventoryHistoryType {
    PURCHASE,
    CONSUME,
    DISPOSE,
    ADJUST,
}
