package com.smartkitchen.backend.inventory

import com.smartkitchen.backend.domain.StorageLocation
import org.springframework.http.HttpStatus
import org.springframework.security.core.Authentication
import org.springframework.web.bind.annotation.GetMapping
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

    @PostMapping("/items")
    @ResponseStatus(HttpStatus.CREATED)
    fun addItems(
        authentication: Authentication,
        @RequestBody requests: List<InventoryItemCreateRequest>,
    ): List<InventoryResponse> =
        inventoryService.addItems(authentication.principal as Long, requests)
}
