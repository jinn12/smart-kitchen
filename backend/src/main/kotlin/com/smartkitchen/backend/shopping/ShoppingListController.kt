package com.smartkitchen.backend.shopping

import org.springframework.security.core.Authentication
import org.springframework.web.bind.annotation.DeleteMapping
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PatchMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/api/shopping-list")
class ShoppingListController(
    private val shoppingListService: ShoppingListService,
) {

    /** principal에는 JwtAuthFilter가 넣어둔 userId(Long)가 들어있다 */
    @GetMapping
    fun list(authentication: Authentication): ShoppingListResponse =
        shoppingListService.list(authentication.principal as Long)

    @PostMapping("/items")
    fun addItem(
        authentication: Authentication,
        @RequestBody request: ShoppingItemCreateRequest,
    ): ShoppingListResponse =
        shoppingListService.addItem(authentication.principal as Long, request)

    @PatchMapping("/items/{id}")
    fun updateItem(
        authentication: Authentication,
        @PathVariable id: Long,
        @RequestBody request: ShoppingItemUpdateRequest,
    ): ShoppingListItemResponse =
        shoppingListService.updateItem(authentication.principal as Long, id, request)

    @DeleteMapping("/items/{id}")
    fun deleteItem(
        authentication: Authentication,
        @PathVariable id: Long,
    ) {
        shoppingListService.deleteItem(authentication.principal as Long, id)
    }

    /** 구매 완료 → 재고 반영 (S-42). 재고→계획→장보기 순환의 마지막 연결 */
    @PostMapping("/complete")
    fun complete(authentication: Authentication): ShoppingCompleteResponse =
        shoppingListService.complete(authentication.principal as Long)
}
