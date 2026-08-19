package com.smartkitchen.backend.auth

import com.smartkitchen.backend.domain.Household
import org.springframework.data.jpa.repository.JpaRepository

interface HouseholdRepository : JpaRepository<Household, Long>{
}