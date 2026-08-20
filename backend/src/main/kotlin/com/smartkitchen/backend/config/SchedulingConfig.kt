package com.smartkitchen.backend.config

import org.springframework.context.annotation.Configuration
import org.springframework.scheduling.annotation.EnableScheduling

/** 배치 2종을 위한 스케줄링 활성화 (R-6, D-011) */
@Configuration
@EnableScheduling
class SchedulingConfig
