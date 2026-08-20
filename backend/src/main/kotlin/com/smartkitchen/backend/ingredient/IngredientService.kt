package com.smartkitchen.backend.ingredient

import com.smartkitchen.backend.auth.UserRepository
import com.smartkitchen.backend.domain.Household
import com.smartkitchen.backend.domain.Ingredient
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import org.springframework.web.server.ResponseStatusException

@Service
class IngredientService(
    private val ingredientRepository: IngredientRepository,
    private val userRepository: UserRepository,
) {
    @Transactional(readOnly = true)
    fun search(userId: Long, keyword: String?, category: String?): List<IngredientResponse> {
        val household = householdOf(userId)

        return ingredientRepository.search(
            householdId = household.id!!,
            keyword = keyword?.trim()?.ifEmpty { null },
            category = category?.trim()?.ifEmpty { null },
        ).map { it.toResponse() }
    }

    @Transactional
    fun create(userId: Long, request: IngredientCreateRequest): IngredientResponse {
        val household = householdOf(userId)
        val name = request.name.trim()

        if (name.isEmpty()) {
            throw ResponseStatusException(HttpStatus.BAD_REQUEST, "식재료 이름은 필수입니다")
        }
        if (request.category !in CATEGORIES) {
            throw ResponseStatusException(HttpStatus.BAD_REQUEST, "허용되지 않은 카테고리입니다: ${request.category}")
        }
        // 잔량 관리를 하지 않는 품목은 소비 기간도 두지 않는다 (D-017 시드 규칙과 동일)
        if (!request.isTrackable && request.defaultShelfLifeDays != null) {
            throw ResponseStatusException(
                HttpStatus.BAD_REQUEST,
                "isTrackable이 false면 defaultShelfLifeDays는 비워야 합니다",
            )
        }
        // 마스터와 같은 이름은 허용한다 — 자기 집 버전을 따로 만들 수 있어야 하므로 (D-005)
        if (ingredientRepository.existsByHouseholdIdAndName(household.id!!, name)) {
            throw ResponseStatusException(HttpStatus.CONFLICT, "이미 등록한 식재료입니다: $name")
        }

        val saved = ingredientRepository.save(
            Ingredient(
                household = household,
                name = name,
                category = request.category,
                unitType = request.unitType,
                packageName = request.packageName,
                packageSize = request.packageSize,
                defaultStorage = request.defaultStorage,
                defaultShelfLifeDays = request.defaultShelfLifeDays,
                isTrackable = request.isTrackable,
                isCustom = true,
            )
        )
        return saved.toResponse()
    }

    /** 모든 도메인 조회는 household 스코프 (D-006) */
    private fun householdOf(userId: Long): Household =
        userRepository.findById(userId).orElseThrow {
            ResponseStatusException(HttpStatus.UNAUTHORIZED, "인증 정보가 올바르지 않습니다")
        }.household

    companion object {
        /** D-017의 13종. DB에 CHECK가 없어 서비스 레이어에서 검증한다 (D-019) */
        private val CATEGORIES = setOf(
            "채소", "과일", "정육/가공육/달걀", "수산물/건해산", "두부/콩/묵",
            "우유/유제품", "쌀/잡곡/견과", "면/빵/통조림", "양념/오일", "김치/반찬",
            "냉동/밀키트", "커피/차/음료", "기타",
        )
    }
}
