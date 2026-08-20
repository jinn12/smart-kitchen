package com.smartkitchen.backend.inventory

import com.smartkitchen.backend.domain.InventoryHistory
import org.springframework.data.jpa.repository.JpaRepository

/** 이력은 append-only (도메인 모델 정의서 4장) */
interface InventoryHistoryRepository : JpaRepository<InventoryHistory, Long>
