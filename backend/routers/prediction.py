from typing import Optional

from fastapi import (
    APIRouter,
    HTTPException,
)

from pydantic import (
    BaseModel,
    Field,
)

from backend.db import (
    get_connection,
)

from backend.services.prediction_service import (
    prediction_model_status,
    run_prediction,
)


# ============================================================
# ROUTER
# ============================================================

router = APIRouter(
    prefix="/api/prediction",
    tags=["Prediction"],
)


# ============================================================
# REQUEST MODEL
# ============================================================

class PredictionRequest(
    BaseModel
):

    incurred_amt: float = Field(
        ...,
        gt=0,
    )

    length_of_stay: float = Field(
        default=0,
        ge=0,
    )

    coverage_id: str

    plan_code: str

    admission_type: str

    claim_type: str

    corp_code: str

    provider_code: str

    primary_diagnosis: str


# ============================================================
# MODEL STATUS
# ============================================================

@router.get(
    "/status"
)
def prediction_status():

    try:

        return (
            prediction_model_status()
        )

    except FileNotFoundError as error:

        return {
            "ready":
                False,

            "message":
                str(error),
        }


# ============================================================
# FILTER HELPERS
# ============================================================

def distinct_values(
    cursor,
    column_name: str,
):

    allowed_columns = {
        "coverage_id",
        "plan_code",
        "admission_type",
        "claim_type",
        "primary_diagnosis",
    }


    if column_name not in allowed_columns:

        raise ValueError(
            "Kolom Prediction tidak valid."
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
        for row
        in cursor.fetchall()
    ]


# ============================================================
# PREDICTION FILTER OPTIONS
# ============================================================

@router.get(
    "/filters"
)
def prediction_filters():

    conn = get_connection()
    cursor = conn.cursor()


    try:

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
            for row
            in cursor.fetchall()
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
            for row
            in cursor.fetchall()
        ]


        # ====================================================
        # RESPONSE
        # ====================================================

        return {

            "coverages":
                distinct_values(
                    cursor,
                    "coverage_id",
                ),

            "plan_codes":
                distinct_values(
                    cursor,
                    "plan_code",
                ),

            "admission_types":
                distinct_values(
                    cursor,
                    "admission_type",
                ),

            "claim_types":
                distinct_values(
                    cursor,
                    "claim_type",
                ),

            "diagnoses":
                distinct_values(
                    cursor,
                    "primary_diagnosis",
                ),

            "providers":
                providers,

            "corporations":
                corporations,
        }


    finally:

        cursor.close()
        conn.close()


# ============================================================
# PREDICT
# ============================================================

@router.post(
    "/predict"
)
def predict(
    request: PredictionRequest,
):

    try:

        payload = (
            request.model_dump()
        )


        return run_prediction(
            payload
        )


    except FileNotFoundError as error:

        raise HTTPException(
            status_code=503,
            detail=str(
                error
            ),
        )


    except Exception as error:

        raise HTTPException(
            status_code=500,
            detail=(
                "Prediction gagal: "
                f"{error}"
            ),
        )