from typing import List, Optional

from fastapi import APIRouter, Query
from psycopg2.extras import RealDictCursor

from backend.db import get_connection


router = APIRouter(
    tags=["Claim Explorer"],
)


# ============================================================
# HELPER - GET DISTINCT FILTER VALUES
# ============================================================

def get_distinct_values(
    cursor,
    column_name: str,
):

    allowed_columns = {
        "claims_status",
        "coverage_id",
        "claim_type",
        "admission_type",
    }

    if column_name not in allowed_columns:
        raise ValueError(
            "Kolom filter tidak valid."
        )

    query = f"""
        SELECT DISTINCT
            TRIM(
                CAST(
                    {column_name} AS TEXT
                )
            ) AS value

        FROM claims

        WHERE
            {column_name} IS NOT NULL

            AND TRIM(
                CAST(
                    {column_name} AS TEXT
                )
            ) <> ''

        ORDER BY 1;
    """

    cursor.execute(query)

    return [
        row[0]
        for row in cursor.fetchall()
    ]


# ============================================================
# HELPER - NORMALIZE MULTI QUERY VALUES
#
# Mendukung dua format sekaligus:
#
# ?coverage=GP&coverage=DENTAL
#
# maupun:
#
# ?coverage=GP,DENTAL
# ============================================================

def normalize_multi_values(
    values: Optional[List[str]],
) -> List[str]:

    if not values:
        return []

    result: List[str] = []

    for value in values:

        if value is None:
            continue

        # ====================================================
        # Split juga jika frontend mengirim:
        # GP,DENTAL,OPTIC
        # ====================================================

        parts = str(value).split(",")

        for part in parts:

            cleaned = part.strip()

            if (
                cleaned
                and cleaned not in result
            ):
                result.append(cleaned)

    return result


# ============================================================
# HELPER - ADD MULTI VALUE SQL FILTER
# ============================================================

def add_multi_filter(
    where_parts: list,
    params: list,
    column_name: str,
    values: List[str],
):

    allowed_columns = {
        "claims_status",
        "coverage_id",
        "claim_type",
        "admission_type",
    }

    if column_name not in allowed_columns:
        raise ValueError(
            "Kolom filter tidak valid."
        )

    if not values:
        return

    # ========================================================
    # Contoh 2 value:
    #
    # CAST(coverage_id AS TEXT) IN (%s, %s)
    #
    # Contoh 3 value:
    #
    # CAST(coverage_id AS TEXT) IN (%s, %s, %s)
    # ========================================================

    placeholders = ", ".join(
        ["%s"] * len(values)
    )

    where_parts.append(
        f"""
        TRIM(
            CAST(
                {column_name} AS TEXT
            )
        ) IN ({placeholders})
        """
    )

    params.extend(values)


# ============================================================
# CLAIM FILTER OPTIONS
# ============================================================

@router.get("/claims/filters")
def claim_filters():

    conn = get_connection()
    cursor = conn.cursor()

    try:

        return {
            "statuses": get_distinct_values(
                cursor,
                "claims_status",
            ),

            "coverages": get_distinct_values(
                cursor,
                "coverage_id",
            ),

            "claim_types": get_distinct_values(
                cursor,
                "claim_type",
            ),

            "admission_types": get_distinct_values(
                cursor,
                "admission_type",
            ),
        }

    finally:

        cursor.close()
        conn.close()


# ============================================================
# SERIALIZE CLAIM
# ============================================================

def serialize_claim(row):

    item = dict(row)

    # ========================================================
    # DATE
    # ========================================================

    admission_date = item.get(
        "admission_date"
    )

    if admission_date is not None:

        item[
            "admission_date"
        ] = admission_date.isoformat()

    # ========================================================
    # NUMERIC MONEY
    # ========================================================

    for field in [
        "incurred_amt",
        "approved_amt",
        "notapproved_amt",
    ]:

        item[field] = float(
            item.get(field) or 0
        )

    # ========================================================
    # STRING FIELDS
    # ========================================================

    for field in [
        "claims_id",
        "claim_type",
        "claims_status",
        "corp_code",
        "corp_name",
        "provider_code",
        "provider_name",
        "admission_type",
        "coverage_id",
        "plan_code",
        "primary_diagnosis",
        "primary_diagnosis_desc",
    ]:

        if item.get(field) is not None:

            item[field] = str(
                item[field]
            )

        else:

            item[field] = ""

    # ========================================================
    # LENGTH OF STAY
    # ========================================================

    try:

        item[
            "length_of_stay"
        ] = int(
            item.get(
                "length_of_stay"
            )
            or 0
        )

    except (
        TypeError,
        ValueError,
    ):

        item[
            "length_of_stay"
        ] = 0

    return item


# ============================================================
# CLAIM EXPLORER
# ============================================================

@router.get("/claims")
def get_claims(

    # ========================================================
    # PAGINATION
    # ========================================================

    page: int = Query(
        default=1,
        ge=1,
    ),

    limit: int = Query(
        default=25,
        ge=1,
        le=100,
    ),

    # ========================================================
    # SEARCH
    # ========================================================

    search: Optional[str] = Query(
        default=None,
    ),

    # ========================================================
    # MULTI SELECT FILTERS
    #
    # Contoh:
    #
    # ?status=40&status=58
    #
    # ?coverage=GP&coverage=DENTAL
    #
    # ========================================================

    status: Optional[List[str]] = Query(
        default=None,
    ),

    coverage: Optional[List[str]] = Query(
        default=None,
    ),

    claim_type: Optional[List[str]] = Query(
        default=None,
    ),

    admission_type: Optional[List[str]] = Query(
        default=None,
    ),
):

    conn = get_connection()

    cursor = conn.cursor(
        cursor_factory=RealDictCursor
    )

    try:

        # ====================================================
        # NORMALIZE MULTI FILTER
        # ====================================================

        statuses = normalize_multi_values(
            status
        )

        coverages = normalize_multi_values(
            coverage
        )

        claim_types = normalize_multi_values(
            claim_type
        )

        admission_types = normalize_multi_values(
            admission_type
        )

        # ====================================================
        # FILTER BUILDER
        # ====================================================

        where_parts = []
        params = []

        # ====================================================
        # GLOBAL SEARCH
        # ====================================================

        if search and search.strip():

            token = (
                f"%{search.strip()}%"
            )

            where_parts.append(
                """
                (
                    CAST(
                        claims_id AS TEXT
                    ) ILIKE %s

                    OR COALESCE(
                        CAST(
                            provider_code AS TEXT
                        ),
                        ''
                    ) ILIKE %s

                    OR COALESCE(
                        CAST(
                            provider_name AS TEXT
                        ),
                        ''
                    ) ILIKE %s

                    OR COALESCE(
                        CAST(
                            corp_code AS TEXT
                        ),
                        ''
                    ) ILIKE %s

                    OR COALESCE(
                        CAST(
                            corp_name AS TEXT
                        ),
                        ''
                    ) ILIKE %s

                    OR COALESCE(
                        CAST(
                            primary_diagnosis AS TEXT
                        ),
                        ''
                    ) ILIKE %s

                    OR COALESCE(
                        CAST(
                            primary_diagnosis_desc AS TEXT
                        ),
                        ''
                    ) ILIKE %s

                    OR COALESCE(
                        CAST(
                            plan_code AS TEXT
                        ),
                        ''
                    ) ILIKE %s
                )
                """
            )

            params.extend(
                [token] * 8
            )

        # ====================================================
        # STATUS - MULTI SELECT
        #
        # Contoh:
        #
        # status=40
        # status=58
        #
        # SQL:
        #
        # claims_status IN ('40', '58')
        # ====================================================

        add_multi_filter(
            where_parts=where_parts,
            params=params,
            column_name="claims_status",
            values=statuses,
        )

        # ====================================================
        # COVERAGE - MULTI SELECT
        #
        # Contoh:
        #
        # GP + DENTAL + OPTIC
        #
        # SQL:
        #
        # coverage_id IN (
        #   'GP',
        #   'DENTAL',
        #   'OPTIC'
        # )
        # ====================================================

        add_multi_filter(
            where_parts=where_parts,
            params=params,
            column_name="coverage_id",
            values=coverages,
        )

        # ====================================================
        # CLAIM TYPE - MULTI SELECT
        # ====================================================

        add_multi_filter(
            where_parts=where_parts,
            params=params,
            column_name="claim_type",
            values=claim_types,
        )

        # ====================================================
        # ADMISSION TYPE - MULTI SELECT
        # ====================================================

        add_multi_filter(
            where_parts=where_parts,
            params=params,
            column_name="admission_type",
            values=admission_types,
        )

        # ====================================================
        # WHERE SQL
        #
        # ANTAR KATEGORI = AND
        #
        # Contoh:
        #
        # status IN (...)
        # AND coverage IN (...)
        # AND claim_type IN (...)
        # ====================================================

        where_sql = ""

        if where_parts:

            where_sql = (
                " WHERE "
                + " AND ".join(
                    where_parts
                )
            )

        # ====================================================
        # COUNT DATA
        # ====================================================

        count_query = f"""
            SELECT
                COUNT(*) AS total

            FROM claims

            {where_sql};
        """

        cursor.execute(
            count_query,
            params,
        )

        total_row = cursor.fetchone()

        total = int(
            total_row["total"]
            if total_row
            else 0
        )

        # ====================================================
        # PAGINATION
        # ====================================================

        total_pages = max(
            1,
            (
                total
                + limit
                - 1
            )
            // limit,
        )

        if page > total_pages:

            page = total_pages

        offset = (
            page - 1
        ) * limit

        # ====================================================
        # GET CLAIM DATA
        # ====================================================

        data_query = f"""
            SELECT

                claims_id,
                claim_type,
                claims_status,

                corp_code,
                corp_name,

                provider_code,
                provider_name,

                admission_date,
                admission_type,
                length_of_stay,

                coverage_id,
                plan_code,

                primary_diagnosis,
                primary_diagnosis_desc,

                incurred_amt,
                approved_amt,
                notapproved_amt

            FROM claims

            {where_sql}

            ORDER BY

                admission_date DESC
                NULLS LAST,

                claims_id

            LIMIT %s

            OFFSET %s;
        """

        # ====================================================
        # COPY FILTER PARAMS
        # ====================================================

        data_params = list(
            params
        )

        # ====================================================
        # ADD PAGINATION PARAMS
        # ====================================================

        data_params.extend(
            [
                limit,
                offset,
            ]
        )

        # ====================================================
        # EXECUTE
        # ====================================================

        cursor.execute(
            data_query,
            data_params,
        )

        rows = cursor.fetchall()

        # ====================================================
        # SERIALIZE
        # ====================================================

        items = [
            serialize_claim(row)
            for row in rows
        ]

        # ====================================================
        # RESPONSE
        # ====================================================

        return {
            "items": items,
            "total": total,
            "page": page,
            "limit": limit,
            "total_pages": total_pages,
        }

    finally:

        cursor.close()
        conn.close()