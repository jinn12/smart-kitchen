package com.smartkitchen.backend.ingredient

import com.smartkitchen.backend.auth.UserRepository
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
        val user = userRepository.findById(userId).orElseThrow {
            ResponseStatusException(HttpStatus.UNAUTHORIZED, "인증 정보가 올바르지 않습니다")
        }

        return ingredientRepository.search(
            householdId = user.household.id!!,
            keyword = keyword?.trim()?.ifEmpty { null },
            category = category?.trim()?.ifEmpty { null },
        ).map { it.toResponse() }
    }
}
