package com.smartkitchen.backend.inventory

import com.smartkitchen.backend.domain.StorageLocation
import org.springframework.http.HttpStatus
import org.springframework.security.core.Authentication
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PatchMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.ResponseStatus
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/api/inventories")
class InventoryController(
    private val inventoryService: InventoryService,
) {

    /** principal에는 JwtAuthFilter가 넣어둔 userId(Long)가 들어있다 */
    @GetMapping
    fun list(
        authentication: Authentication,
        @RequestParam(required = false) storageLocation: StorageLocation?,
    ): List<InventoryResponse> =
        inventoryService.list(authentication.principal as Long, storageLocation)

    /** 임박·만료 목록. {ingredientId} 매핑보다 먼저 매칭된다(리터럴 경로 우선) */
    @GetMapping("/expiring")
    fun listExpiring(authentication: Authentication): List<InventoryResponse> =
        inventoryService.listExpiring(authentication.principal as Long)

    @GetMapping("/{ingredientId}")
    fun detail(
        authentication: Authentication,
        @PathVariable ingredientId: Long,
    ): InventoryDetailResponse =
        inventoryService.detail(authentication.principal as Long, ingredientId)

    @PostMapping("/items")
    @ResponseStatus(HttpStatus.CREATED)
    fun addItems(
        authentication: Authentication,
        @RequestBody requests: List<InventoryItemCreateRequest>,
    ): List<InventoryResponse> =
        inventoryService.addItems(authentication.principal as Long, requests)

    @PatchMapping("/items/{id}")
    fun updateItem(
        authentication: Authentication,
        @PathVariable id: Long,
        @RequestBody request: InventoryItemUpdateRequest,
    ): InventoryResponse =
        inventoryService.updateItem(authentication.principal as Long, id, request)

    @PatchMapping("/{ingredientId}")
    fun updateInventory(
        authentication: Authentication,
        @PathVariable ingredientId: Long,
        @RequestBody request: InventoryUpdateRequest,
    ): InventoryResponse =
        inventoryService.updateInventory(authentication.principal as Long, ingredientId, request)
}
