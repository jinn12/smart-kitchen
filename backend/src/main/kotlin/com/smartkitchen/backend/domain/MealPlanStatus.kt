package com.smartkitchen.backend.domain

/** 식사 계획 상태. PLANNED=예약, CONFIRMED=확정 차감 완료 (R-1, R-6) */
enum class MealPlanStatus {
    PLANNED,
    CONFIRMED,
    CANCELED,
}
