from datetime import date
from typing import Optional

from fastapi import APIRouter, HTTPException, Query

from backend.db import get_connection


# ============================================================
# ROUTER
# ============================================================

router = APIRouter(
    prefix="/api/analytics",
    tags=["Analytics"],
)


# ============================================================
# MULTI VALUE HELPERS
# ============================================================

def parse_multi_value(
    *values: Optional[str],
) -> list[str]:
    """
    Mendukung:
    ?coverage=GP
    ?coverage=GP,DENTAL
    ?coverages=GP,DENTAL

    Hasil selalu List[str].
    """

    result: list[str] = []

    for raw_value in values:
        if not raw_value:
            continue

        for item in raw_value.split(","):
            cleaned = item.strip()

            if (
                cleaned
                and cleaned not in result
            ):
                result.append(cleaned)

    return result


def parse_years(
    *values: Optional[str],
) -> list[int]:
    result: list[int] = []

    for raw_value in values:
        if not raw_value:
            continue

        for item in raw_value.split(","):
            item = item.strip()

            if not item:
                continue

            try:
                year = int(item)
            except ValueError:
                raise HTTPException(
                    status_code=400,
                    detail=(
                        f"Year tidak valid: "
                        f"{item}"
                    ),
                )

            if year not in result:
                result.append(year)

    return result


# ============================================================
# SQL FILTER HELPERS
# ============================================================

def add_text_in_filter(
    where_parts: list[str],
    params: list,
    column_name: str,
    values: list[str],
):
    if not values:
        return

    allowed_columns = {
        "coverage_id",
        "claim_type",
        "claim_result",
        "provider_code",
        "corp_code",
        "admission_type",
    }

    if column_name not in allowed_columns:
        raise ValueError(
            "Kolom filter Analytics tidak valid."
        )

    placeholders = ", ".join(
        ["%s"] * len(values)
    )

    if column_name == "claim_result":
        where_parts.append(
            f"""
            UPPER(
                TRIM(
                    CAST(
                        {column_name}
                        AS TEXT
                    )
                )
            )
            IN ({placeholders})
            """
        )

        params.extend(
            [
                value.upper()
                for value in values
            ]
        )

    else:
        where_parts.append(
            f"""
            TRIM(
                CAST(
                    {column_name}
                    AS TEXT
                )
            )
            IN ({placeholders})
            """
        )

        params.extend(values)


def add_year_filter(
    where_parts: list[str],
    params: list,
    years: list[int],
):
    if not years:
        return

    placeholders = ", ".join(
        ["%s"] * len(years)
    )

    where_parts.append(
        f"""
        EXTRACT(
            YEAR
            FROM admission_date
        )::INTEGER
        IN ({placeholders})
        """
    )

    params.extend(years)


# ============================================================
# ANALYTICS FILTER BUILDER
# ============================================================

def build_analytics_filters(
    years: Optional[list[int]] = None,
    coverages: Optional[list[str]] = None,
    claim_types: Optional[list[str]] = None,
    results: Optional[list[str]] = None,
    provider_codes: Optional[list[str]] = None,
    corp_codes: Optional[list[str]] = None,
    admission_types: Optional[list[str]] = None,
    date_from: Optional[date] = None,
    date_to: Optional[date] = None,
):
    where_parts: list[str] = []
    params: list = []

    # ========================================================
    # YEAR
    # ========================================================

    add_year_filter(
        where_parts,
        params,
        years or [],
    )

    # ========================================================
    # COVERAGE
    # ========================================================

    add_text_in_filter(
        where_parts,
        params,
        "coverage_id",
        coverages or [],
    )

    # ========================================================
    # CLAIM TYPE
    # ========================================================

    add_text_in_filter(
        where_parts,
        params,
        "claim_type",
        claim_types or [],
    )

    # ========================================================
    # RESULT
    # ========================================================

    clean_results = [
        value.upper()
        for value in (
            results or []
        )
    ]

    invalid_results = [
        value
        for value in clean_results
        if value not in {
            "ACC",
            "REJECT",
        }
    ]

    if invalid_results:
        raise HTTPException(
            status_code=400,
            detail=(
                "Result hanya boleh "
                "ACC atau REJECT."
            ),
        )

    add_text_in_filter(
        where_parts,
        params,
        "claim_result",
        clean_results,
    )

    # ========================================================
    # PROVIDER
    # ========================================================

    add_text_in_filter(
        where_parts,
        params,
        "provider_code",
        provider_codes or [],
    )

    # ========================================================
    # CORPORATION
    # ========================================================

    add_text_in_filter(
        where_parts,
        params,
        "corp_code",
        corp_codes or [],
    )

    # ========================================================
    # ADMISSION TYPE
    # ========================================================

    add_text_in_filter(
        where_parts,
        params,
        "admission_type",
        admission_types or [],
    )

    # ========================================================
    # DATE RANGE
    # ========================================================

    if date_from:
        where_parts.append(
            "admission_date >= %s"
        )
        params.append(date_from)

    if date_to:
        where_parts.append(
            "admission_date <= %s"
        )
        params.append(date_to)

    # ========================================================
    # FINAL WHERE
    # ========================================================

    if not where_parts:
        return "", params

    where_sql = (
        " WHERE "
        + " AND ".join(
            where_parts
        )
    )

    return where_sql, params


# ============================================================
# ANALYTICS OVERVIEW
# ============================================================

@router.get("/overview")
def analytics_overview(

    # ========================================================
    # YEAR
    # backward compatible: year / years
    # ========================================================

    year: Optional[str] = None,
    years: Optional[str] = None,

    # ========================================================
    # COVERAGE
    # ========================================================

    coverage: Optional[str] = None,
    coverages: Optional[str] = None,

    # ========================================================
    # CLAIM TYPE
    # ========================================================

    claim_type: Optional[str] = None,
    claim_types: Optional[str] = None,

    # ========================================================
    # RESULT
    # ========================================================

    result: Optional[str] = None,
    results: Optional[str] = None,

    # ========================================================
    # PROVIDER
    # ========================================================

    provider_code: Optional[str] = None,
    provider_codes: Optional[str] = None,

    # ========================================================
    # CORPORATION
    # ========================================================

    corp_code: Optional[str] = None,
    corp_codes: Optional[str] = None,

    # ========================================================
    # ADMISSION TYPE
    # ========================================================

    admission_type: Optional[str] = None,
    admission_types: Optional[str] = None,

    # ========================================================
    # DATE
    # ========================================================

    date_from: Optional[date] = None,
    date_to: Optional[date] = None,
):
    # ========================================================
    # DATE VALIDATION
    # ========================================================

    if (
        date_from is not None
        and date_to is not None
        and date_from > date_to
    ):
        raise HTTPException(
            status_code=400,
            detail=(
                "date_from tidak boleh "
                "lebih besar dari date_to."
            ),
        )

    # ========================================================
    # NORMALIZE MULTI FILTER
    # ========================================================

    parsed_years = parse_years(
        year,
        years,
    )

    parsed_coverages = parse_multi_value(
        coverage,
        coverages,
    )

    parsed_claim_types = parse_multi_value(
        claim_type,
        claim_types,
    )

    parsed_results = parse_multi_value(
        result,
        results,
    )

    parsed_providers = parse_multi_value(
        provider_code,
        provider_codes,
    )

    parsed_corporations = parse_multi_value(
        corp_code,
        corp_codes,
    )

    parsed_admission_types = parse_multi_value(
        admission_type,
        admission_types,
    )

    # ========================================================
    # BUILD QUERY
    # ========================================================

    where_sql, params = (
        build_analytics_filters(
            years=parsed_years,
            coverages=parsed_coverages,
            claim_types=parsed_claim_types,
            results=parsed_results,
            provider_codes=parsed_providers,
            corp_codes=parsed_corporations,
            admission_types=(
                parsed_admission_types
            ),
            date_from=date_from,
            date_to=date_to,
        )
    )

    conn = get_connection()
    cursor = conn.cursor()

    try:
        cursor.execute(
            f"""
            SELECT
                COUNT(*) AS total_claims,

                COUNT(*) FILTER (
                    WHERE
                        UPPER(
                            TRIM(
                                CAST(
                                    claim_result
                                    AS TEXT
                                )
                            )
                        ) = 'ACC'
                ) AS total_acc,

                COUNT(*) FILTER (
                    WHERE
                        UPPER(
                            TRIM(
                                CAST(
                                    claim_result
                                    AS TEXT
                                )
                            )
                        ) = 'REJECT'
                ) AS total_reject,

                COALESCE(
                    SUM(incurred_amt),
                    0
                ) AS total_incurred,

                COALESCE(
                    SUM(approved_amt),
                    0
                ) AS total_approved,

                COALESCE(
                    SUM(notapproved_amt),
                    0
                ) AS total_notapproved,

                COALESCE(
                    AVG(incurred_amt),
                    0
                ) AS avg_incurred,

                COALESCE(
                    AVG(approved_amt),
                    0
                ) AS avg_approved,

                COALESCE(
                    AVG(length_of_stay),
                    0
                ) AS avg_length_of_stay

            FROM claims_analytics

            {where_sql};
            """,
            params,
        )

        row = cursor.fetchone()

        total_claims = int(
            row[0] or 0
        )

        total_acc = int(
            row[1] or 0
        )

        total_reject = int(
            row[2] or 0
        )

        total_incurred = float(
            row[3] or 0
        )

        total_approved = float(
            row[4] or 0
        )

        total_notapproved = float(
            row[5] or 0
        )

        avg_incurred = float(
            row[6] or 0
        )

        avg_approved = float(
            row[7] or 0
        )

        avg_length_of_stay = float(
            row[8] or 0
        )

        # ====================================================
        # APPROVAL RATE
        # berdasarkan JUMLAH KLAIM
        # ====================================================

        approval_rate = (
            round(
                (
                    total_acc
                    / total_claims
                )
                * 100,
                2,
            )
            if total_claims > 0
            else 0.0
        )

        # ====================================================
        # APPROVED VALUE RATIO
        # berdasarkan NOMINAL
        # ====================================================

        approved_amount_ratio = (
            round(
                (
                    total_approved
                    / total_incurred
                )
                * 100,
                2,
            )
            if total_incurred > 0
            else 0.0
        )

        return {
            "total_claims":
                total_claims,

            "total_acc":
                total_acc,

            "total_reject":
                total_reject,

            "approval_rate":
                approval_rate,

            "total_incurred":
                total_incurred,

            "total_approved":
                total_approved,

            "total_notapproved":
                total_notapproved,

            "avg_incurred":
                avg_incurred,

            "avg_approved":
                avg_approved,

            "avg_length_of_stay":
                round(
                    avg_length_of_stay,
                    2,
                ),

            "approved_amount_ratio":
                approved_amount_ratio,
        }

    finally:
        cursor.close()
        conn.close()


# ============================================================
# DISTINCT VALUE HELPER
# ============================================================

def get_distinct_values(
    cursor,
    column_name: str,
):
    allowed_columns = {
        "coverage_id",
        "claim_type",
        "admission_type",
    }

    if column_name not in allowed_columns:
        raise ValueError(
            "Kolom filter tidak valid."
        )

    cursor.execute(
        f"""
        SELECT DISTINCT
            TRIM(
                CAST(
                    {column_name}
                    AS TEXT
                )
            ) AS value

        FROM claims_analytics

        WHERE
            {column_name}
            IS NOT NULL

            AND TRIM(
                CAST(
                    {column_name}
                    AS TEXT
                )
            ) <> ''

        ORDER BY
            value;
        """
    )

    return [
        str(row[0])
        for row in cursor.fetchall()
    ]


# ============================================================
# ANALYTICS FILTER OPTIONS
# ============================================================

@router.get("/filters")
def analytics_filters():
    conn = get_connection()
    cursor = conn.cursor()

    try:
        # ====================================================
        # COVERAGES
        # ====================================================

        coverages = get_distinct_values(
            cursor,
            "coverage_id",
        )

        # ====================================================
        # CLAIM TYPES
        # ====================================================

        claim_types = get_distinct_values(
            cursor,
            "claim_type",
        )

        # ====================================================
        # ADMISSION TYPES
        # ====================================================

        admission_types = (
            get_distinct_values(
                cursor,
                "admission_type",
            )
        )

        # ====================================================
        # RESULTS
        # ====================================================

        cursor.execute(
            """
            SELECT DISTINCT
                UPPER(
                    TRIM(
                        CAST(
                            claim_result
                            AS TEXT
                        )
                    )
                ) AS result

            FROM claims_analytics

            WHERE
                claim_result
                IS NOT NULL

                AND TRIM(
                    CAST(
                        claim_result
                        AS TEXT
                    )
                ) <> ''

            ORDER BY
                result;
            """
        )

        results = [
            str(row[0])
            for row in cursor.fetchall()
        ]

        # ====================================================
        # PROVIDERS
        # ====================================================

        cursor.execute(
            """
            SELECT DISTINCT ON (
                TRIM(
                    CAST(
                        provider_code
                        AS TEXT
                    )
                )
            )
                TRIM(
                    CAST(
                        provider_code
                        AS TEXT
                    )
                ) AS code,

                COALESCE(
                    NULLIF(
                        TRIM(
                            CAST(
                                provider_name
                                AS TEXT
                            )
                        ),
                        ''
                    ),
                    'Unknown Provider'
                ) AS name

            FROM claims_analytics

            WHERE
                provider_code
                IS NOT NULL

                AND TRIM(
                    CAST(
                        provider_code
                        AS TEXT
                    )
                ) <> ''

            ORDER BY
                TRIM(
                    CAST(
                        provider_code
                        AS TEXT
                    )
                ),

                CASE
                    WHEN
                        provider_name IS NULL

                        OR TRIM(
                            CAST(
                                provider_name
                                AS TEXT
                            )
                        ) = ''

                    THEN 1

                    ELSE 0
                END,

                provider_name;
            """
        )

        providers = [
            {
                "code":
                    str(row[0]),

                "name":
                    str(row[1]),
            }
            for row in cursor.fetchall()
        ]

        # ====================================================
        # CORPORATIONS
        # ====================================================

        cursor.execute(
            """
            SELECT DISTINCT ON (
                TRIM(
                    CAST(
                        corp_code
                        AS TEXT
                    )
                )
            )
                TRIM(
                    CAST(
                        corp_code
                        AS TEXT
                    )
                ) AS code,

                COALESCE(
                    NULLIF(
                        TRIM(
                            CAST(
                                corp_name
                                AS TEXT
                            )
                        ),
                        ''
                    ),
                    'Unknown Corporation'
                ) AS name

            FROM claims_analytics

            WHERE
                corp_code
                IS NOT NULL

                AND TRIM(
                    CAST(
                        corp_code
                        AS TEXT
                    )
                ) <> ''

            ORDER BY
                TRIM(
                    CAST(
                        corp_code
                        AS TEXT
                    )
                ),

                CASE
                    WHEN
                        corp_name IS NULL

                        OR TRIM(
                            CAST(
                                corp_name
                                AS TEXT
                            )
                        ) = ''

                    THEN 1

                    ELSE 0
                END,

                corp_name;
            """
        )

        corporations = [
            {
                "code":
                    str(row[0]),

                "name":
                    str(row[1]),
            }
            for row in cursor.fetchall()
        ]

        # ====================================================
        # YEARS
        # ====================================================

        cursor.execute(
            """
            SELECT DISTINCT
                EXTRACT(
                    YEAR
                    FROM admission_date
                )::INTEGER AS year

            FROM claims_analytics

            WHERE
                admission_date
                IS NOT NULL

            ORDER BY
                year DESC;
            """
        )

        years = [
            int(row[0])
            for row in cursor.fetchall()
        ]

        # ====================================================
        # DATE RANGE
        # ====================================================

        cursor.execute(
            """
            SELECT
                MIN(admission_date),
                MAX(admission_date)

            FROM claims_analytics

            WHERE
                admission_date
                IS NOT NULL;
            """
        )

        row = cursor.fetchone()

        min_date = (
            row[0].isoformat()
            if (
                row
                and row[0] is not None
            )
            else None
        )

        max_date = (
            row[1].isoformat()
            if (
                row
                and row[1] is not None
            )
            else None
        )

        # ====================================================
        # RESPONSE
        # ====================================================

        return {
            "coverages":
                coverages,

            "claim_types":
                claim_types,

            "results":
                results,

            "admission_types":
                admission_types,

            "providers":
                providers,

            "corporations":
                corporations,

            "years":
                years,

            "date_range": {
                "min":
                    min_date,

                "max":
                    max_date,
            },
        }

    finally:
        cursor.close()
        conn.close()