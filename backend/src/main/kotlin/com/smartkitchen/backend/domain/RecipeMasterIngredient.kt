package com.smartkitchen.backend.domain

import jakarta.persistence.*
import java.math.BigDecimal
import java.time.OffsetDateTime

/**
 * RCP_PARTS_DTLS(재료 자유텍스트) 파싱 결과. 적재 배치가 선처리해 채운다.
 * 매핑 실패분(matchedIngredient == null)은 사용자 검증 화면에서 지정한다 — 자동 확정 금지 (D-007)
 */
@Entity
@Table(name = "recipe_master_ingredient")
class RecipeMasterIngredient(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "recipe_master_id", nullable = false)
    var recipeMaster: RecipeMaster,

    /** 항목 원문. 예: "연두부 75g(3/4모)" */
    @Column(name = "raw_text", nullable = false, length = 100)
    var rawText: String,

    /** 파싱한 재료명. 예: "연두부" */
    @Column(name = "parsed_name", nullable = false, length = 50)
    var parsedName: String,

    /** "약간"처럼 수량이 없으면 NULL */
    @Column(name = "parsed_qty", precision = 10, scale = 2)
    var parsedQty: BigDecimal? = null,

    /** g/ml/개/큰술 등. 불명이면 NULL */
    @Column(name = "parsed_unit", length = 10)
    var parsedUnit: String? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "matched_ingredient_id")
    var matchedIngredient: Ingredient? = null,

    @Column(name = "created_at", nullable = false)
    val createdAt: OffsetDateTime = OffsetDateTime.now(),
)
