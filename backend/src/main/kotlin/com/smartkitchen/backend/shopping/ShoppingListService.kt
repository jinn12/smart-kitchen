package com.smartkitchen.backend.shopping

import com.smartkitchen.backend.auth.UserRepository
import com.smartkitchen.backend.domain.Household
import com.smartkitchen.backend.domain.Ingredient
import com.smartkitchen.backend.domain.InventoryRefType
import com.smartkitchen.backend.domain.ShoppingItemSource
import com.smartkitchen.backend.domain.ShoppingList
import com.smartkitchen.backend.domain.ShoppingListItem
import com.smartkitchen.backend.ingredient.IngredientRepository
import com.smartkitchen.backend.inventory.InventoryItemCreateRequest
import com.smartkitchen.backend.inventory.InventoryService
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import org.springframework.web.server.ResponseStatusException
import java.math.BigDecimal

@Service
class ShoppingListService(
    private val shoppingListRepository: ShoppingListRepository,
    private val shoppingListItemRepository: ShoppingListItemRepository,
    private val ingredientRepository: IngredientRepository,
    private val inventoryService: InventoryService,
    private val userRepository: UserRepository,
) {
    @Transactional
    fun list(userId: Long): ShoppingListResponse {
        val household = householdOf(userId)
        val list = getOrCreate(household)
        return ShoppingListResponse(id = list.id!!, items = itemsOf(list))
    }

    /** 수동 추가. 잔량 관리를 하지 않는 재료도 담을 수 있다 (D-017, R-4) */
    @Transactional
    fun addItem(userId: Long, request: ShoppingItemCreateRequest): ShoppingListResponse {
        val household = householdOf(userId)
        if (request.quantity <= BigDecimal.ZERO) {
            throw ResponseStatusException(HttpStatus.BAD_REQUEST, "수량은 0보다 커야 합니다")
        }
        val ingredient = ingredientRepository
            .findAllAccessible(setOf(request.ingredientId), household.id!!)
            .firstOrNull()
            ?: throw ResponseStatusException(
                HttpStatus.BAD_REQUEST,
                "사용할 수 없는 식재료입니다: ${request.ingredientId}",
            )

        val list = getOrCreate(household)
        addOrMerge(list, ingredient, request.quantity, ShoppingItemSource.MANUAL)
        return ShoppingListResponse(id = list.id!!, items = itemsOf(list))
    }

    @Transactional
    fun updateItem(userId: Long, itemId: Long, request: ShoppingItemUpdateRequest): ShoppingListItemResponse {
        val household = householdOf(userId)
        val item = findAccessible(itemId, household.id!!)

        request.quantity?.let {
            if (it <= BigDecimal.ZERO) {
                throw ResponseStatusException(HttpStatus.BAD_REQUEST, "수량은 0보다 커야 합니다")
            }
            item.quantity = it
        }
        request.isChecked?.let { item.isChecked = it }
        return item.toResponse()
    }

    /** 잘못 담은 항목 제거. 장보기 항목은 이력 가치가 없어 물리 삭제한다 */
    @Transactional
    fun deleteItem(userId: Long, itemId: Long) {
        val household = householdOf(userId)
        shoppingListItemRepository.delete(findAccessible(itemId, household.id!!))
    }

    /**
     * 구매 완료 → 재고 반영 (S-42). 체크한 항목만 대상이며 전체가 한 트랜잭션이다.
     * 재고 반영 규칙(유통기한 자동 계산·보관 장소 초기화·PURCHASE 이력)은 API-21과 같아야 하므로
     * InventoryService.addItems를 그대로 재사용한다.
     */
    @Transactional
    fun complete(userId: Long): ShoppingCompleteResponse {
        val household = householdOf(userId)
        val list = getOrCreate(household)
        val all = shoppingListItemRepository.findByShoppingListId(list.id!!)
        val checked = all.filter { it.isChecked }
        if (checked.isEmpty()) {
            throw ResponseStatusException(HttpStatus.BAD_REQUEST, "구매 완료할 항목을 선택해 주세요")
        }

        // 잔량 관리를 하지 않는 재료는 재고로 잡지 않고 목록에서만 지운다 (R-4)
        val trackable = checked.filter { it.ingredient.isTrackable }
        val inventories = if (trackable.isEmpty()) {
            emptyList()
        } else {
            inventoryService.addItems(
                userId = userId,
                requests = trackable.map {
                    InventoryItemCreateRequest(
                        ingredientId = it.ingredient.id!!,
                        quantity = it.quantity,
                    )
                },
                // 이 입고가 장보기에서 왔음을 이력에 남긴다 (D-027)
                refType = InventoryRefType.SHOPPING_LIST,
                refId = list.id!!,
            )
        }

        // 구매한 항목은 행을 지운다 — shopping_list는 household당 1개(UNIQUE)라
        // "완료된 목록"을 따로 남길 자리가 없고, 구매 이력은 inventory_history가 갖는다.
        // deleteAllInBatch로 단일 DELETE에 묶는다 (행마다 DELETE가 나가지 않도록)
        shoppingListItemRepository.deleteAllInBatch(checked)
        return ShoppingCompleteResponse(
            inventories = inventories,
            carriedOverCount = all.size - checked.size,
        )
    }

    /**
     * 계획 부족분을 장보기에 담는다 (D-010). MealPlanService가 호출한다.
     * 병합 규칙은 수동 추가와 같은 한 곳에서만 구현한다 (D-025).
     */
    @Transactional
    fun addShortages(household: Household, shortages: Map<Ingredient, BigDecimal>) {
        if (shortages.isEmpty()) return
        val list = getOrCreate(household)
        for ((ingredient, quantity) in shortages) {
            addOrMerge(list, ingredient, quantity, ShoppingItemSource.SHORTAGE)
        }
    }

    /**
     * 재료당 1행이므로 이미 있으면 수량을 더하고 체크를 푼다 (D-025).
     * source는 처음 담긴 경로를 유지한다 — 나중 병합이 출처를 덮어쓰지 않는다.
     */
    private fun addOrMerge(
        list: ShoppingList,
        ingredient: Ingredient,
        quantity: BigDecimal,
        source: ShoppingItemSource,
    ) {
        val existing = shoppingListItemRepository
            .findByShoppingListIdAndIngredientIdIn(list.id!!, listOf(ingredient.id!!))
            .firstOrNull()
        if (existing == null) {
            shoppingListItemRepository.save(
                ShoppingListItem(
                    shoppingList = list,
                    ingredient = ingredient,
                    quantity = quantity,
                    source = source,
                )
            )
        } else {
            existing.quantity = existing.quantity.add(quantity)
            existing.isChecked = false
        }
    }

    private fun getOrCreate(household: Household): ShoppingList =
        shoppingListRepository.findByHouseholdId(household.id!!)
            ?: shoppingListRepository.save(ShoppingList(household = household))

    /** 미체크 먼저, 그 안에서 이름순 (S-41) */
    private fun itemsOf(list: ShoppingList): List<ShoppingListItemResponse> =
        shoppingListItemRepository.findByShoppingListId(list.id!!)
            .sortedWith(compareBy({ it.isChecked }, { it.ingredient.name }))
            .map { it.toResponse() }

    private fun findAccessible(itemId: Long, householdId: Long): ShoppingListItem =
        shoppingListItemRepository.findAccessible(itemId, householdId)
            ?: throw ResponseStatusException(HttpStatus.NOT_FOUND, "장보기 항목을 찾을 수 없습니다")

    private fun householdOf(userId: Long): Household =
        userRepository.findById(userId).orElseThrow {
            ResponseStatusException(HttpStatus.UNAUTHORIZED, "인증 정보가 올바르지 않습니다")
        }.household
}

fun ShoppingListItem.toResponse(): ShoppingListItemResponse =
    ShoppingListItemResponse(
        id = id!!,
        ingredientId = ingredient.id!!,
        name = ingredient.name,
        unitType = ingredient.unitType,
        quantity = quantity,
        isChecked = isChecked,
        source = source,
        packageName = ingredient.packageName,
        packageSize = ingredient.packageSize,
    )
