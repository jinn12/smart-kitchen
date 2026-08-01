package com.smartkitchen.backend

import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RestController

@RestController
class HealthController {
    @GetMapping("/api/health")
    fun health() = mapOf("status" to "ok", "service" to "smart-kitchen")
}