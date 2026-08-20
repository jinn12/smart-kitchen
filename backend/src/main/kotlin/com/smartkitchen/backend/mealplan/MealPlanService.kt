package com.smartkitchen.backend.mealplan

import com.smartkitchen.backend.auth.UserRepository
import com.smartkitchen.backend.domain.Household
import com.smartkitchen.backend.domain.Ingredient
import com.smartkitchen.backend.domain.MealPlan
import com.smartkitchen.backend.domain.MealPlanItem
import com.smartkitchen.backend.domain.MealPlanStatus
import com.smartkitchen.backend.domain.Recipe
import com.smartkitchen.backend.domain.RecipeIngredient
import com.smartkitchen.backend.domain.ShoppingItemSource
import com.smartkitchen.backend.domain.ShoppingList
import com.smartkitchen.backend.domain.ShoppingListItem
import com.smartkitchen.backend.inventory.InventoryRepository
import com.smartkitchen.backend.recipe.RecipeIngredientRepository
import com.smartkitchen.backend.recipe.RecipeRepository
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import org.springframework.web.server.ResponseStatusException
import java.math.BigDecimal
import java.math.RoundingMode
import java.time.LocalDate

@Service
class MealPlanService(
    private val mealPlanRepository: MealPlanRepository,
    private val mealPlanItemRepository: MealPlanItemRepository,
    private val shoppingListRepository: ShoppingListRepository,
    private val shoppingListItemRepository: ShoppingListItemRepository,
    private val recipeRepository: RecipeRepository,
    private val recipeIngredientRepository: RecipeIngredientRepository,
    private val inventoryRepository: InventoryRepository,
    private val userRepository: UserRepository,
) {

    /** 등록 전 부족 안내 (D-010). 아무것도 바꾸지 않는다 */
    @Transactional(readOnly = true)
    fun preview(userId: Long, request: MealPlanPreviewRequest): MealPlanPreviewResponse {
        val household = householdOf(userId)
        val recipe = findRecipe(request.recipeId, household.id!!)
        val servings = validServings(request.servings ?: recipe.servings)
        val items = recipeIngredientRepository.findByRecipeIdOrderByIdAsc(recipe.id!!)
        val available = availableByIngredient(household.id!!)

        val ingredients = items.map {
            val required = requiredQty(it, servings, recipe.servings)
            val have = available[it.ingredient.id!!] ?: BigDecimal.ZERO
            PreviewIngredientResponse(
                ingredientId = it.ingredient.id!!,
                name = it.ingredient.name,
                unitType = it.ingredient.unitType,
                requiredQuantity = required,
                availableQuantity = have,
                // 계량 제외 재료는 부족을 따지지 않는다 (R-4)
                shortageQuantity = if (it.ingredient.isTrackable) shortage(required, have) else BigDecimal.ZERO,
                trackable = it.ingredient.isTrackable,
            )
        }
        return MealPlanPreviewResponse(
            recipeId = recipe.id!!,
            recipeName = recipe.name,
            recipeServings = recipe.servings,
            servings = servings,
            shortageCount = ingredients.count { it.trackable && it.shortageQuantity > BigDecimal.ZERO },
            ingredients = ingredients,
        )
    }

    /**
     * 계획 등록 = 재고 예약 (R-1).
     * 재료별 예약량 = min(필요량, 그 시점 가용량)이며 meal_plan_item에 스냅샷으로 남긴다.
     */
    @Transactional
    fun create(userId: Long, request: MealPlanCreateRequest): MealPlanDetailResponse {
        val household = householdOf(userId)
        val recipe = findRecipe(request.recipeId, household.id!!)
        val servings = validServings(request.servings ?: recipe.servings)
        if (request.planDate.isBefore(LocalDate.now())) {
            throw ResponseStatusException(HttpStatus.BAD_REQUEST, "지난 날짜에는 계획을 세울 수 없습니다")
        }
        val items = recipeIngredientRepository.findByRecipeIdOrderByIdAsc(recipe.id!!)
        if (items.isEmpty()) {
            throw ResponseStatusException(HttpStatus.BAD_REQUEST, "재료가 없는 요리는 계획할 수 없습니다")
        }

        val plan = mealPlanRepository.save(
            MealPlan(
                household = household,
                recipe = recipe,
                planDate = request.planDate,
                mealType = request.mealType,
                servings = servings,
                status = MealPlanStatus.PLANNED,
            )
        )

        // 계량 대상만 잠근다. ingredient.id 순서로 잠가 교착을 피한다
        val trackableIds = items.filter { it.ingredient.isTrackable }.map { it.ingredient.id!! }
        val locked = if (trackableIds.isEmpty()) {
            emptyMap()
        } else {
            inventoryRepository.lockByIngredientIds(household.id!!, trackableIds)
                .associateBy { it.ingredient.id!! }
        }

        val toShopping = request.addToShoppingIngredientIds.toSet()
        val shortages = LinkedHashMap<Ingredient, BigDecimal>()
        val responses = mutableListOf<MealPlanIngredientResponse>()

        for (item in items) {
            val ingredient = item.ingredient
            val required = requiredQty(item, servings, recipe.servings)

            if (!ingredient.isTrackable) {
                // 계량 제외: 예약도 부족 판단도 하지 않는다 (R-4)
                responses.add(
                    MealPlanIngredientResponse(
                        ingredientId = ingredient.id!!,
                        name = ingredient.name,
                        unitType = ingredient.unitType,
                        requiredQuantity = required,
                        reservedQuantity = BigDecimal.ZERO,
                        shortageQuantity = BigDecimal.ZERO,
                        trackable = false,
                        addedToShoppingList = false,
                    )
                )
                continue
            }

            val inventory = locked[ingredient.id!!]
            val availableNow = inventory?.let { it.quantity.subtract(it.reservedQuantity) } ?: BigDecimal.ZERO
            val reserved = required.min(availableNow).max(BigDecimal.ZERO)
            val short = shortage(required, reserved)

            if (inventory != null && reserved > BigDecimal.ZERO) {
                inventory.reservedQuantity = inventory.reservedQuantity.add(reserved)
            }
            // required_qty > 0 CHECK 때문에 반올림으로 0이 된 항목은 스냅샷을 남기지 않는다
            if (required > BigDecimal.ZERO) {
                mealPlanItemRepository.save(
                    MealPlanItem(
                        mealPlan = plan,
                        ingredient = ingredient,
                        requiredQty = required,
                        reservedQty = reserved,
                    )
                )
            }

            val added = ingredient.id!! in toShopping && short > BigDecimal.ZERO
            if (added) {
                shortages[ingredient] = short
            }
            responses.add(
                MealPlanIngredientResponse(
                    ingredientId = ingredient.id!!,
                    name = ingredient.name,
                    unitType = ingredient.unitType,
                    requiredQuantity = required,
                    reservedQuantity = reserved,
                    shortageQuantity = short,
                    trackable = true,
                    addedToShoppingList = added,
                )
            )
        }

        if (shortages.isNotEmpty()) {
            addToShoppingList(household, shortages)
        }
        return MealPlanDetailResponse(
            id = plan.id!!,
            planDate = plan.planDate,
            mealType = plan.mealType,
            recipeId = recipe.id!!,
            recipeName = recipe.name,
            servings = plan.servings,
            status = plan.status,
            ingredients = responses,
        )
    }

    /** 취소 = 예약 해제. 스냅샷 값 그대로 되돌린다 (재계산하지 않는다) */
    @Transactional
    fun cancel(userId: Long, planId: Long): MealPlanCancelResponse {
        val household = householdOf(userId)
        val plan = mealPlanRepository.findByIdAndHouseholdId(planId, household.id!!)
            ?: throw ResponseStatusException(HttpStatus.NOT_FOUND, "계획을 찾을 수 없습니다")
        if (plan.status != MealPlanStatus.PLANNED) {
            throw ResponseStatusException(
                HttpStatus.BAD_REQUEST,
                "이미 ${if (plan.status == MealPlanStatus.CANCELED) "취소" else "확정"}된 계획입니다",
            )
        }

        val items = mealPlanItemRepository.findByMealPlanIdOrderByIdAsc(planId)
        val released = items.filter { it.reservedQty > BigDecimal.ZERO }
        if (released.isNotEmpty()) {
            val locked = inventoryRepository
                .lockByIngredientIds(household.id!!, released.map { it.ingredient.id!! })
                .associateBy { it.ingredient.id!! }
            for (item in released) {
                val inventory = locked[item.ingredient.id!!] ?: continue
                // 스냅샷보다 적게 남아 있어도 음수로 내려가지 않게 막는다
                inventory.reservedQuantity =
                    inventory.reservedQuantity.subtract(item.reservedQty).max(BigDecimal.ZERO)
            }
        }
        plan.status = MealPlanStatus.CANCELED
        return MealPlanCancelResponse(
            id = plan.id!!,
            status = plan.status,
            releasedIngredientCount = released.size,
        )
    }

    /** 주간 식탁 (S-31). 취소된 계획은 빼고 날짜 → 끼니 순으로 그룹핑한다 */
    @Transactional(readOnly = true)
    fun weekly(userId: Long, from: LocalDate?, to: LocalDate?): List<MealPlanDayResponse> {
        val household = householdOf(userId)
        val start = from ?: LocalDate.now()
        val end = to ?: start.plusDays(DEFAULT_RANGE_DAYS - 1)
        if (start.isAfter(end)) {
            throw ResponseStatusException(HttpStatus.BAD_REQUEST, "from이 to보다 늦을 수 없습니다")
        }
        val days = java.time.temporal.ChronoUnit.DAYS.between(start, end) + 1
        if (days > MAX_RANGE_DAYS) {
            throw ResponseStatusException(HttpStatus.BAD_REQUEST, "조회 기간은 최대 ${MAX_RANGE_DAYS}일입니다")
        }

        val plans = mealPlanRepository.findByHouseholdIdAndPlanDateBetweenAndStatusIn(
            household.id!!, start, end, VISIBLE_STATUSES,
        )
        // meal_type은 문자열 컬럼이라 DB 정렬이 알파벳순(BREAKFAST/DINNER/LUNCH)이 된다.
        // 끼니 순서는 enum 선언 순서가 정답이므로 메모리에서 정렬한다 (D-012)
        val byDate = plans.groupBy { it.planDate }
        return generateSequence(start) { it.plusDays(1) }
            .takeWhile { !it.isAfter(end) }
            .map { date ->
                MealPlanDayResponse(
                    date = date,
                    meals = byDate[date].orEmpty()
                        .sortedWith(compareBy({ it.mealType.ordinal }, { it.id }))
                        .map {
                            MealSummaryResponse(
                                id = it.id!!,
                                mealType = it.mealType,
                                recipeName = it.recipe.name,
                                servings = it.servings,
                                status = it.status,
                            )
                        },
                )
            }
            .toList()
    }

    /** 필요량 = 재료량 × (선택 인분 ÷ 레시피 기준 인분) (D-015, D-024) */
    private fun requiredQty(item: RecipeIngredient, servings: Int, recipeServings: Int): BigDecimal =
        item.quantity
            .multiply(BigDecimal(servings))
            .divide(BigDecimal(recipeServings), QTY_SCALE, RoundingMode.HALF_UP)

    private fun shortage(required: BigDecimal, have: BigDecimal): BigDecimal =
        required.subtract(have).max(BigDecimal.ZERO)

    /** 부족분을 장보기에 담는다. 같은 재료가 이미 있으면 수량을 더하고 체크를 푼다 */
    private fun addToShoppingList(household: Household, shortages: Map<Ingredient, BigDecimal>) {
        val list = shoppingListRepository.findByHouseholdId(household.id!!)
            ?: shoppingListRepository.save(ShoppingList(household = household))
        val existing = shoppingListItemRepository
            .findByShoppingListIdAndIngredientIdIn(list.id!!, shortages.keys.map { it.id!! })
            .associateBy { it.ingredient.id!! }

        for ((ingredient, quantity) in shortages) {
            val item = existing[ingredient.id!!]
            if (item == null) {
                shoppingListItemRepository.save(
                    ShoppingListItem(
                        shoppingList = list,
                        ingredient = ingredient,
                        quantity = quantity,
                        source = ShoppingItemSource.SHORTAGE,
                    )
                )
            } else {
                // UNIQUE(list_id, ingredient_id)라 행을 늘릴 수 없다. 합산하고 다시 사야 하므로 체크를 푼다
                item.quantity = item.quantity.add(quantity)
                item.isChecked = false
                item.source = ShoppingItemSource.SHORTAGE
            }
        }
    }

    private fun availableByIngredient(householdId: Long): Map<Long, BigDecimal> =
        inventoryRepository.findByHouseholdIdOrderByIngredientNameAsc(householdId)
            .associate { it.ingredient.id!! to it.quantity.subtract(it.reservedQuantity) }

    private fun findRecipe(recipeId: Long, householdId: Long): Recipe =
        recipeRepository.findByIdAndHouseholdId(recipeId, householdId)
            ?: throw ResponseStatusException(HttpStatus.BAD_REQUEST, "사용할 수 없는 요리입니다: $recipeId")

    private fun validServings(servings: Int): Int {
        if (servings < 1) {
            throw ResponseStatusException(HttpStatus.BAD_REQUEST, "인분은 1 이상이어야 합니다")
        }
        return servings
    }

    private fun householdOf(userId: Long): Household =
        userRepository.findById(userId).orElseThrow {
            ResponseStatusException(HttpStatus.UNAUTHORIZED, "인증 정보가 올바르지 않습니다")
        }.household

    companion object {
        /** 수량 컬럼이 NUMERIC(10,2)라 환산도 소수 2자리로 맞춘다 */
        private const val QTY_SCALE = 2
        private const val DEFAULT_RANGE_DAYS = 7L
        private const val MAX_RANGE_DAYS = 31L

        /** 취소된 계획은 주간 식탁에 노출하지 않는다 */
        private val VISIBLE_STATUSES = listOf(MealPlanStatus.PLANNED, MealPlanStatus.CONFIRMED)
    }
}
