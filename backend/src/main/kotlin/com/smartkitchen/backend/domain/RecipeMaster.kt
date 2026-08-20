package com.smartkitchen.backend.domain

import jakarta.persistence.*
import java.math.BigDecimal
import java.time.OffsetDateTime

/** 조리식품 레시피 DB(COOKRCP01) 적재본. 1인분 기준 데이터다 (D-014, D-015) */
@Entity
@Table(name = "recipe_master")
class RecipeMaster(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    /** COOKRCP01의 RCP_SEQ. 재적재 시 중복 방지용 */
    @Column(name = "external_seq", nullable = false, unique = true, length = 20)
    var externalSeq: String,

    @Column(nullable = false, length = 100)
    var name: String,

    /** 밥/국&찌개/반찬/일품/후식 (RCP_PAT2) */
    @Column(nullable = false, length = 20)
    var category: String,

    /** 굽기/끓이기/찌기/기타 (RCP_WAY2) */
    @Column(name = "cook_way", length = 20)
    var cookWay: String? = null,

    /** 1인분 중량(g). 원본에 빈 값이 많다 */
    @Column(name = "weight_1p", precision = 10, scale = 2)
    var weight1p: BigDecimal? = null,

    @Column(name = "kcal_1p", precision = 10, scale = 2)
    var kcal1p: BigDecimal? = null,

    @Column(name = "carb_1p", precision = 10, scale = 2)
    var carb1p: BigDecimal? = null,

    @Column(name = "protein_1p", precision = 10, scale = 2)
    var protein1p: BigDecimal? = null,

    @Column(name = "fat_1p", precision = 10, scale = 2)
    var fat1p: BigDecimal? = null,

    @Column(name = "natrium_1p", precision = 10, scale = 2)
    var natrium1p: BigDecimal? = null,

    @Column(name = "image_url", length = 255)
    var imageUrl: String? = null,

    /** RCP_PARTS_DTLS 원문. 파싱 규칙을 고쳤을 때 재파싱하기 위해 남긴다 */
    @Column(name = "raw_parts_text", nullable = false, columnDefinition = "text")
    var rawPartsText: String,

    @Column(name = "created_at", nullable = false)
    val createdAt: OffsetDateTime = OffsetDateTime.now(),
)
