package com.smartkitchen.backend.inventory

import com.smartkitchen.backend.auth.UserRepository
import com.smartkitchen.backend.domain.Household
import com.smartkitchen.backend.domain.Ingredient
import com.smartkitchen.backend.domain.Inventory
import com.smartkitchen.backend.domain.InventoryHistory
import com.smartkitchen.backend.domain.InventoryHistoryType
import com.smartkitchen.backend.domain.InventoryItem
import com.smartkitchen.backend.domain.StorageLocation
import com.smartkitchen.backend.ingredient.IngredientRepository
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import org.springframework.web.server.ResponseStatusException
import java.math.BigDecimal
import java.time.LocalDate
import java.time.temporal.ChronoUnit

@Service
class InventoryService(
    private val inventoryRepository: InventoryRepository,
    private val inventoryItemRepository: InventoryItemRepository,
    private val inventoryHistoryRepository: InventoryHistoryRepository,
    private val ingredientRepository: IngredientRepository,
    private val userRepository: UserRepository,
) {
    @Transactional(readOnly = true)
    fun list(userId: Long, storageLocation: StorageLocation?): List<InventoryResponse> {
        val household = householdOf(userId)
        val householdId = household.id!!

        val inventories = if (storageLocation == null) {
            inventoryRepository.findByHouseholdIdOrderByIngredientNameAsc(householdId)
        } else {
            inventoryRepository.findByHouseholdIdAndStorageLocationOrderByIngredientNameAsc(
                householdId,
                storageLocation,
            )
        }
        return toResponses(inventories)
    }

    /**
     * 임박·만료 재고만 (D-013). 만료가 맨 위로 오도록 dday 오름차순.
     * 매일 09:00 요약 푸시(R-5)의 데이터원이 될 예정이다.
     */
    @Transactional(readOnly = true)
    fun listExpiring(userId: Long): List<InventoryResponse> =
        list(userId, null)
            .filter { it.expiryStatus == ExpiryStatus.EXPIRED || it.expiryStatus == ExpiryStatus.EXPIRING }
            .sortedWith(compareBy({ it.dday }, { it.name }))

    /** 재고 상세 (S-12). 배치는 FEFO 순, 이력은 최신 20건 */
    @Transactional(readOnly = true)
    fun detail(userId: Long, ingredientId: Long): InventoryDetailResponse {
        val household = householdOf(userId)
        val inventory = findInventory(household.id!!, ingredientId)
        val today = LocalDate.now()

        val batches = inventoryItemRepository.findActiveBatches(inventory.id!!).map {
            InventoryBatchResponse(
                id = it.id!!,
                quantity = it.quantity,
                purchasedAt = it.purchasedAt,
                expiryDate = it.expiryDate,
                dday = it.expiryDate?.let { date -> ddayOf(date, today) },
            )
        }
        val history = inventoryHistoryRepository
            .findTop20ByHouseholdIdAndIngredientIdOrderByCreatedAtDescIdDesc(household.id!!, ingredientId)
            .map {
                InventoryHistoryResponse(
                    id = it.id!!,
                    type = it.type,
                    quantity = it.quantity,
                    refType = it.refType,
                    refId = it.refId,
                    createdAt = it.createdAt,
                )
            }

        return InventoryDetailResponse(
            summary = toResponses(listOf(inventory)).first(),
            batches = batches,
            history = history,
        )
    }

    /** 배치 단위 수정·소진·폐기. 처리 후 inventory.quantity를 배치 합계로 재계산한다 */
    @Transactional
    fun updateItem(userId: Long, itemId: Long, request: InventoryItemUpdateRequest): InventoryResponse {
        val household = householdOf(userId)
        val batch = inventoryItemRepository.findAccessible(itemId, household.id!!)
            ?: throw ResponseStatusException(HttpStatus.NOT_FOUND, "배치를 찾을 수 없습니다")

        val before = batch.quantity
        val after = when (request.action) {
            InventoryItemAction.ADJUST -> {
                val quantity = request.quantity
                    ?: throw ResponseStatusException(HttpStatus.BAD_REQUEST, "ADJUST는 quantity가 필요합니다")
                if (quantity < BigDecimal.ZERO) {
                    throw ResponseStatusException(HttpStatus.BAD_REQUEST, "수량은 0 이상이어야 합니다")
                }
                quantity
            }
            // 소진·폐기는 배치를 통째로 비운다. 행은 남겨 구매 이력을 보존한다 (R-2)
            InventoryItemAction.CONSUME, InventoryItemAction.DISCARD -> BigDecimal.ZERO
        }

        batch.quantity = after
        val inventory = batch.inventory
        inventory.quantity = inventoryItemRepository.sumQuantity(inventory.id!!)

        inventoryHistoryRepository.save(
            InventoryHistory(
                household = household,
                ingredient = inventory.ingredient,
                type = when (request.action) {
                    InventoryItemAction.ADJUST -> InventoryHistoryType.ADJUST
                    InventoryItemAction.CONSUME -> InventoryHistoryType.CONSUME
                    InventoryItemAction.DISCARD -> InventoryHistoryType.DISPOSE
                },
                quantity = after.subtract(before),
            )
        )
        return toResponses(listOf(inventory)).first()
    }

    /** 보관 장소 변경 (API-25). Inventory 단위이므로 해당 재료의 배치 전체가 함께 옮겨진다 */
    @Transactional
    fun updateInventory(userId: Long, ingredientId: Long, request: InventoryUpdateRequest): InventoryResponse {
        val household = householdOf(userId)
        val inventory = findInventory(household.id!!, ingredientId)
        inventory.storageLocation = request.storageLocation
        return toResponses(listOf(inventory)).first()
    }

    /** 없는 재료와 남의 household 재고를 구분하지 않고 같은 404로 묶는다 (D-006) */
    private fun findInventory(householdId: Long, ingredientId: Long): Inventory =
        inventoryRepository.findByHouseholdIdAndIngredientId(householdId, ingredientId)
            ?: throw ResponseStatusException(HttpStatus.NOT_FOUND, "재고를 찾을 수 없습니다")

    /** 배치 일괄 등록. 한 항목이라도 검증에 걸리면 전체를 저장하지 않는다 */
    @Transactional
    fun addItems(userId: Long, requests: List<InventoryItemCreateRequest>): List<InventoryResponse> {
        if (requests.isEmpty()) {
            throw ResponseStatusException(HttpStatus.BAD_REQUEST, "등록할 항목이 없습니다")
        }
        val household = householdOf(userId)
        val ingredients = accessibleIngredients(requests.map { it.ingredientId }, household.id!!)
        val today = LocalDate.now()
        val touched = LinkedHashMap<Long, Inventory>()

        for (request in requests) {
            val ingredient = ingredients.getValue(request.ingredientId)

            if (request.quantity <= BigDecimal.ZERO) {
                throw ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "수량은 0보다 커야 합니다: ${ingredient.name}",
                )
            }
            // 잔량 관리를 하지 않는 품목은 재고 등록 대상이 아니다 (D-017, R-4)
            if (!ingredient.isTrackable) {
                throw ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "잔량 관리를 하지 않는 식재료입니다: ${ingredient.name}",
                )
            }

            val inventory = touched.getOrPut(ingredient.id!!) {
                inventoryRepository.findByHouseholdIdAndIngredientId(household.id!!, ingredient.id!!)
                    ?: inventoryRepository.save(
                        Inventory(
                            household = household,
                            ingredient = ingredient,
                            // 기존 재고가 있으면 사용자가 바꾼 보관 장소를 유지한다
                            storageLocation = ingredient.defaultStorage,
                        )
                    )
            }

            val purchasedAt = request.purchasedAt ?: today
            inventoryItemRepository.save(
                InventoryItem(
                    inventory = inventory,
                    quantity = request.quantity,
                    expiryDate = request.expiryDate ?: expiryFrom(purchasedAt, ingredient),
                    purchasedAt = purchasedAt,
                )
            )
            // 실물 보유량은 배치 합계 (ERD의 inventory.quantity 정의)
            inventory.quantity = inventory.quantity.add(request.quantity)

            inventoryHistoryRepository.save(
                InventoryHistory(
                    household = household,
                    ingredient = ingredient,
                    type = InventoryHistoryType.PURCHASE,
                    quantity = request.quantity,
                )
            )
        }

        return toResponses(touched.values.sortedBy { it.ingredient.name })
    }

    /** 유통기한 미입력 시 구매일 + 권장 소비 기간. 기간이 없는 재료는 NULL로 둔다 (D-017) */
    private fun expiryFrom(purchasedAt: LocalDate, ingredient: Ingredient): LocalDate? =
        ingredient.defaultShelfLifeDays?.let { purchasedAt.plusDays(it.toLong()) }

    /**
     * 요청의 ingredientId를 한 번에 검증한다.
     * 없는 id와 남의 household 커스텀을 구분하지 않고 같은 400으로 묶는다 —
     * 구분해서 알려주면 다른 가구의 데이터 존재 여부가 드러난다 (D-006).
     */
    private fun accessibleIngredients(ids: List<Long>, householdId: Long): Map<Long, Ingredient> {
        val found = ingredientRepository.findAllAccessible(ids.toSet(), householdId)
            .associateBy { it.id!! }
        val missing = ids.toSet() - found.keys
        if (missing.isNotEmpty()) {
            throw ResponseStatusException(
                HttpStatus.BAD_REQUEST,
                "사용할 수 없는 식재료입니다: ${missing.sorted().joinToString(", ")}",
            )
        }
        return found
    }

    private fun toResponses(inventories: List<Inventory>): List<InventoryResponse> {
        if (inventories.isEmpty()) return emptyList()

        val nearestExpiry = inventoryItemRepository
            .findNearestExpiry(inventories.map { it.id!! })
            .associate { it.inventoryId to it.nearestExpiryDate }
        val today = LocalDate.now()

        return inventories.map { inventory ->
            val expiryDate = nearestExpiry[inventory.id!!]
            val dday = expiryDate?.let { ddayOf(it, today) }

            InventoryResponse(
                ingredientId = inventory.ingredient.id!!,
                name = inventory.ingredient.name,
                category = inventory.ingredient.category,
                unitType = inventory.ingredient.unitType,
                storageLocation = inventory.storageLocation,
                totalQuantity = inventory.quantity,
                reservedQuantity = inventory.reservedQuantity,
                // 예약은 API-42에서 생긴다. 지금은 항상 0이지만 계산식은 R-1 형태로 둔다
                availableQuantity = inventory.quantity.subtract(inventory.reservedQuantity),
                nearestExpiryDate = expiryDate,
                dday = dday,
                expiryStatus = statusOf(dday),
            )
        }
    }

    private fun ddayOf(expiryDate: LocalDate, today: LocalDate): Int =
        ChronoUnit.DAYS.between(today, expiryDate).toInt()

    /** 당일(D-0)은 임박으로 본다. 만료는 하루 지난 시점부터 (R-5 보완) */
    private fun statusOf(dday: Int?): ExpiryStatus = when {
        dday == null -> ExpiryStatus.NONE
        dday < 0 -> ExpiryStatus.EXPIRED
        dday <= EXPIRING_DAYS -> ExpiryStatus.EXPIRING
        else -> ExpiryStatus.NORMAL
    }

    /** 모든 도메인 조회는 household 스코프 (D-006) */
    private fun householdOf(userId: Long): Household =
        userRepository.findById(userId).orElseThrow {
            ResponseStatusException(HttpStatus.UNAUTHORIZED, "인증 정보가 올바르지 않습니다")
        }.household

    companion object {
        /** 임박 기준 D-3 (D-013) */
        private const val EXPIRING_DAYS = 3
    }
}
