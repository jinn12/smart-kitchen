package com.smartkitchen.backend.domain

import jakarta.persistence.*
import java.math.BigDecimal
import java.time.OffsetDateTime

@Entity
@Table(name = "shopping_list_item")
class ShoppingListItem(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "list_id", nullable = false)
    var shoppingList: ShoppingList,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ingredient_id", nullable = false)
    var ingredient: Ingredient,

    @Column(nullable = false, precision = 10, scale = 2)
    var quantity: BigDecimal,

    @Column(name = "is_checked", nullable = false)
    var isChecked: Boolean = false,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    var source: ShoppingItemSource = ShoppingItemSource.MANUAL,

    @Column(name = "created_at", nullable = false)
    val createdAt: OffsetDateTime = OffsetDateTime.now(),
)
