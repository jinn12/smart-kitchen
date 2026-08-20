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
            val dday = expiryDate?.let { ChronoUnit.DAYS.between(today, it).toInt() }

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
