package com.smartkitchen.backend.recipe

import com.smartkitchen.backend.domain.Ingredient
import com.smartkitchen.backend.domain.RecipeMaster
import org.springframework.data.domain.PageRequest
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import org.springframework.web.server.ResponseStatusException

/**
 * 공공 레시피(COOKRCP01 적재본) 조회. 시스템 데이터라 household 스코프가 없고
 * 전 사용자가 같은 목록을 본다 — 인증만 요구한다.
 */
@Service
class RecipeMasterService(
    private val recipeMasterRepository: RecipeMasterRepository,
    private val recipeMasterIngredientRepository: RecipeMasterIngredientRepository,
) {
    @Transactional(readOnly = true)
    fun search(keyword: String?, category: String?, page: Int, size: Int): RecipeMasterPage {
        if (page < 0) {
            throw ResponseStatusException(HttpStatus.BAD_REQUEST, "page는 0 이상이어야 합니다")
        }
        val capped = size.coerceIn(1, MAX_PAGE_SIZE)
        val result = recipeMasterRepository.search(
            keyword = keyword?.trim()?.ifEmpty { null },
            category = category?.trim()?.ifEmpty { null },
            pageable = PageRequest.of(page, capped),
        )
        return RecipeMasterPage(
            totalCount = result.totalElements,
            page = page,
            size = capped,
            items = result.content.map { it.toSummary() },
        )
    }

    @Transactional(readOnly = true)
    fun detail(id: Long): RecipeMasterDetailResponse {
        val master = recipeMasterRepository.findById(id).orElseThrow {
            ResponseStatusException(HttpStatus.NOT_FOUND, "레시피를 찾을 수 없습니다")
        }
        val ingredients = recipeMasterIngredientRepository
            .findByRecipeMasterIdOrderByIdAsc(id)
            .map {
                RecipeMasterIngredientResponse(
                    rawText = it.rawText,
                    parsedName = it.parsedName,
                    parsedQty = it.parsedQty,
                    parsedUnit = it.parsedUnit,
                    matchedIngredient = it.matchedIngredient?.toMatched(),
                )
            }
        return RecipeMasterDetailResponse(
            id = master.id!!,
            name = master.name,
            category = master.category,
            cookWay = master.cookWay,
            imageUrl = master.imageUrl,
            kcal1p = master.kcal1p,
            servings = MASTER_SERVINGS,
            ingredients = ingredients,
        )
    }

    companion object {
        const val MAX_PAGE_SIZE = 100

        /** COOKRCP01은 1인분 기준 데이터다 (D-015) */
        const val MASTER_SERVINGS = 1
    }
}

fun RecipeMaster.toSummary(): RecipeMasterSummary =
    RecipeMasterSummary(
        id = id!!,
        name = name,
        category = category,
        cookWay = cookWay,
        imageUrl = imageUrl,
        kcal1p = kcal1p,
    )

fun Ingredient.toMatched(): MatchedIngredientResponse =
    MatchedIngredientResponse(id = id!!, name = name, unitType = unitType)
