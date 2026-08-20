package com.smartkitchen.backend.domain

import jakarta.persistence.*
import org.hibernate.annotations.DynamicUpdate
import java.math.BigDecimal
import java.time.LocalDate
import java.time.OffsetDateTime

/**
 * 재고 배치 (D-003). FEFO 차감 단위 (R-2).
 * 확정 배치(R-6)와 API-23이 같은 행의 quantity를 각각 고치므로 변경된 컬럼만 쓴다.
 */
@DynamicUpdate
@Entity
@Table(name = "inventory_item")
class InventoryItem(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "inventory_id", nullable = false)
    var inventory: Inventory,

    @Column(nullable = false, precision = 10, scale = 2)
    var quantity: BigDecimal,

    /** NULL 허용. FEFO 정렬에서 마지막 순서 */
    @Column(name = "expiry_date")
    var expiryDate: LocalDate? = null,

    @Column(name = "purchased_at", nullable = false)
    var purchasedAt: LocalDate = LocalDate.now(),

    @Column(name = "created_at", nullable = false)
    val createdAt: OffsetDateTime = OffsetDateTime.now(),
)
