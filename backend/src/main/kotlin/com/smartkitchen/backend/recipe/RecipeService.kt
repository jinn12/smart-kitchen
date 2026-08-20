package com.smartkitchen.backend.recipe

import com.smartkitchen.backend.auth.UserRepository
import com.smartkitchen.backend.domain.Household
import com.smartkitchen.backend.domain.Ingredient
import com.smartkitchen.backend.domain.Recipe
import com.smartkitchen.backend.domain.RecipeIngredient
import com.smartkitchen.backend.domain.RecipeSource
import com.smartkitchen.backend.ingredient.IngredientRepository
import com.smartkitchen.backend.inventory.InventoryRepository
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import org.springframework.web.server.ResponseStatusException
import java.math.BigDecimal

@Service
class RecipeService(
    private val recipeRepository: RecipeRepository,
    private val recipeIngredientRepository: RecipeIngredientRepository,
    private val recipeMasterRepository: RecipeMasterRepository,
    private val ingredientRepository: IngredientRepository,
    private val inventoryRepository: InventoryRepository,
    private val userRepository: UserRepository,
) {
    @Transactional(readOnly = true)
    fun list(userId: Long): List<RecipeSummary> {
        val household = householdOf(userId)
        val recipes = recipeRepository.findByHouseholdIdOrderByNameAsc(household.id!!)
        if (recipes.isEmpty()) return emptyList()

        // 요리 N건의 재료와 가구 재고를 각각 한 번에 읽어 메모리에서 판정한다 (N+1 방지)
        val byRecipe = recipeIngredientRepository
            .findByRecipeIdIn(recipes.map { it.id!! })
            .groupBy { it.recipe.id!! }
        val available = availableByIngredient(household.id!!)

        return recipes.map { recipe ->
            val items = byRecipe[recipe.id!!].orEmpty()
            RecipeSummary(
                id = recipe.id!!,
                name = recipe.name,
                servings = recipe.servings,
                source = recipe.source,
                ingredientCount = items.size,
                cookableNow = items.all { isSufficient(it, available) != false },
            )
        }
    }

    @Transactional(readOnly = true)
    fun detail(userId: Long, recipeId: Long): RecipeDetailResponse {
        val household = householdOf(userId)
        val recipe = recipeRepository.findByIdAndHouseholdId(recipeId, household.id!!)
            ?: throw ResponseStatusException(HttpStatus.NOT_FOUND, "요리를 찾을 수 없습니다")
        return toDetail(recipe, household.id!!)
    }

    @Transactional
    fun create(userId: Long, request: RecipeCreateRequest): RecipeDetailResponse {
        val household = householdOf(userId)
        val servings = request.servings ?: DEFAULT_SERVINGS
        if (servings < 1) {
            throw ResponseStatusException(HttpStatus.BAD_REQUEST, "인분은 1 이상이어야 합니다")
        }
        if (request.ingredients.isEmpty()) {
            throw ResponseStatusException(HttpStatus.BAD_REQUEST, "재료를 최소 1개 이상 담아야 합니다")
        }
        request.ingredients.firstOrNull { it.quantity <= BigDecimal.ZERO }?.let {
            throw ResponseStatusException(HttpStatus.BAD_REQUEST, "재료 수량은 0보다 커야 합니다")
        }
        val ids = request.ingredients.map { it.ingredientId }
        if (ids.size != ids.toSet().size) {
            throw ResponseStatusException(HttpStatus.BAD_REQUEST, "같은 식재료를 두 번 담을 수 없습니다")
        }

        val master = when (request.source) {
            RecipeSource.MANUAL -> null
            RecipeSource.MASTER -> {
                val masterId = request.recipeMasterId
                    ?: throw ResponseStatusException(HttpStatus.BAD_REQUEST, "recipeMasterId가 필요합니다")
                recipeMasterRepository.findById(masterId).orElseThrow {
                    // 본문 필드의 잘못된 id는 400 (D-022)
                    ResponseStatusException(HttpStatus.BAD_REQUEST, "존재하지 않는 레시피입니다: $masterId")
                }
            }
        }
        val name = when (request.source) {
            // 마스터 복제는 이름을 원본에서 복사한다
            RecipeSource.MASTER -> master!!.name.trim()
            RecipeSource.MANUAL -> request.name?.trim().orEmpty().ifEmpty {
                throw ResponseStatusException(HttpStatus.BAD_REQUEST, "요리 이름은 필수입니다")
            }
        }

        val ingredients = accessibleIngredients(ids, household.id!!)
        val recipe = recipeRepository.save(
            Recipe(
                household = household,
                name = name,
                servings = servings,
                source = request.source,
                recipeMaster = master,
            )
        )
        recipeIngredientRepository.saveAll(
            request.ingredients.map {
                RecipeIngredient(
                    recipe = recipe,
                    ingredient = ingredients.getValue(it.ingredientId),
                    quantity = it.quantity,
                )
            }
        )
        return toDetail(recipe, household.id!!)
    }

    private fun toDetail(recipe: Recipe, householdId: Long): RecipeDetailResponse {
        val items = recipeIngredientRepository.findByRecipeIdOrderByIdAsc(recipe.id!!)
        val available = availableByIngredient(householdId)

        val ingredients = items.map {
            RecipeIngredientResponse(
                ingredientId = it.ingredient.id!!,
                name = it.ingredient.name,
                quantity = it.quantity,
                unitType = it.ingredient.unitType,
                availableQuantity = available[it.ingredient.id!!] ?: BigDecimal.ZERO,
                sufficient = isSufficient(it, available),
            )
        }
        return RecipeDetailResponse(
            id = recipe.id!!,
            name = recipe.name,
            servings = recipe.servings,
            source = recipe.source,
            recipeMasterId = recipe.recipeMaster?.id,
            cookableNow = ingredients.all { it.sufficient != false },
            ingredients = ingredients,
        )
    }

    /**
     * 레시피 기준 분량(quantity 그대로)을 지금 재고로 감당할 수 있는가.
     * 잔량 관리를 하지 않는 재료는 판단 대상이 아니다 (R-4) — null을 돌려준다.
     */
    private fun isSufficient(item: RecipeIngredient, available: Map<Long, BigDecimal>): Boolean? {
        if (!item.ingredient.isTrackable) return null
        val have = available[item.ingredient.id!!] ?: BigDecimal.ZERO
        return have >= item.quantity
    }

    /** 가용 = 잔량 − 예약 (R-1). 재고 행이 없는 재료는 이 맵에 없다 */
    private fun availableByIngredient(householdId: Long): Map<Long, BigDecimal> =
        inventoryRepository.findByHouseholdIdOrderByIngredientNameAsc(householdId)
            .associate { it.ingredient.id!! to it.quantity.subtract(it.reservedQuantity) }

    /** 마스터 + 내 커스텀만 쓸 수 있다 (D-006). 없는 id와 남의 커스텀을 같은 400으로 묶는다 (D-022) */
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

    private fun householdOf(userId: Long): Household =
        userRepository.findById(userId).orElseThrow {
            ResponseStatusException(HttpStatus.UNAUTHORIZED, "인증 정보가 올바르지 않습니다")
        }.household

    companion object {
        /** 마스터가 1인분 기준이라 복제·직접 입력 모두 기본 1 (D-015) */
        private const val DEFAULT_SERVINGS = 1
    }
}
