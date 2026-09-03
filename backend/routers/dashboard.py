from fastapi import APIRouter

from backend.db import get_connection


router = APIRouter(
    prefix="/api/dashboard",
    tags=["Dashboard"],
)


# ============================================================
# DASHBOARD SUMMARY
# ============================================================

@router.get("/summary")
def dashboard_summary():

    conn = get_connection()
    cursor = conn.cursor()

    try:

        cursor.execute(
            """
            SELECT
                COUNT(*) AS total_claims,

                COUNT(*) FILTER (
                    WHERE claim_result = 'ACC'
                ) AS total_acc,

                COUNT(*) FILTER (
                    WHERE claim_result = 'REJECT'
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
                ) AS total_notapproved

            FROM claims_analytics;
            """
        )

        result = cursor.fetchone()

        total_claims = result[0]
        total_acc = result[1]
        total_reject = result[2]

        approval_rate = (
            round(
                (total_acc / total_claims) * 100,
                2,
            )
            if total_claims > 0
            else 0
        )

        return {
            "total_claims": total_claims,
            "total_acc": total_acc,
            "total_reject": total_reject,
            "approval_rate": approval_rate,
            "total_incurred": float(
                result[3]
            ),
            "total_approved": float(
                result[4]
            ),
            "total_notapproved": float(
                result[5]
            ),
        }

    finally:

        cursor.close()
        conn.close()


# ============================================================
# MONTHLY CLAIM TREND
# ============================================================

@router.get("/monthly-trend")
def monthly_claim_trend():

    conn = get_connection()
    cursor = conn.cursor()

    try:

        cursor.execute(
            """
            SELECT

                TO_CHAR(
                    DATE_TRUNC(
                        'month',
                        admission_date
                    ),
                    'YYYY-MM'
                ) AS month,

                COUNT(*) AS total_claims,

                COUNT(*) FILTER (
                    WHERE claim_result = 'ACC'
                ) AS total_acc,

                COUNT(*) FILTER (
                    WHERE claim_result = 'REJECT'
                ) AS total_reject,

                COALESCE(
                    SUM(incurred_amt),
                    0
                ) AS total_incurred,

                COALESCE(
                    SUM(approved_amt),
                    0
                ) AS total_approved

            FROM claims_analytics

            WHERE
                admission_date IS NOT NULL

            GROUP BY
                DATE_TRUNC(
                    'month',
                    admission_date
                )

            ORDER BY
                DATE_TRUNC(
                    'month',
                    admission_date
                );
            """
        )

        rows = cursor.fetchall()

        return [
            {
                "month": row[0],
                "total_claims": row[1],
                "total_acc": row[2],
                "total_reject": row[3],
                "total_incurred": float(
                    row[4]
                ),
                "total_approved": float(
                    row[5]
                ),
            }
            for row in rows
        ]

    finally:

        cursor.close()
        conn.close()


# ============================================================
# COVERAGE DISTRIBUTION
# ============================================================

@router.get("/top-coverage")
def top_coverage():

    conn = get_connection()
    cursor = conn.cursor()

    try:

        cursor.execute(
            """
            SELECT

                coverage_id,

                COUNT(*) AS total_claims,

                COUNT(*) FILTER (
                    WHERE claim_result = 'ACC'
                ) AS total_acc,

                COUNT(*) FILTER (
                    WHERE claim_result = 'REJECT'
                ) AS total_reject,

                COALESCE(
                    SUM(approved_amt),
                    0
                ) AS total_approved

            FROM claims_analytics

            WHERE
                coverage_id IS NOT NULL

            GROUP BY
                coverage_id

            ORDER BY
                total_claims DESC;
            """
        )

        rows = cursor.fetchall()

        return [
            {
                "coverage_id": str(
                    row[0]
                ),
                "total_claims": row[1],
                "total_acc": row[2],
                "total_reject": row[3],
                "total_approved": float(
                    row[4]
                ),
            }
            for row in rows
        ]

    finally:

        cursor.close()
        conn.close()


# ============================================================
# TOP PROVIDER
# ============================================================

@router.get("/top-provider")
def top_provider():

    conn = get_connection()
    cursor = conn.cursor()

    try:

        cursor.execute(
            """
            SELECT

                provider_code,

                COALESCE(
                    provider_name,
                    'Unknown Provider'
                ) AS provider_name,

                COUNT(*) AS total_claims,

                COUNT(*) FILTER (
                    WHERE claim_result = 'ACC'
                ) AS total_acc,

                COUNT(*) FILTER (
                    WHERE claim_result = 'REJECT'
                ) AS total_reject,

                ROUND(
                    100.0
                    *
                    COUNT(*) FILTER (
                        WHERE claim_result = 'REJECT'
                    )
                    /
                    NULLIF(
                        COUNT(*),
                        0
                    ),
                    2
                ) AS reject_rate,

                COALESCE(
                    SUM(approved_amt),
                    0
                ) AS total_approved

            FROM claims_analytics

            WHERE
                provider_code IS NOT NULL

            GROUP BY
                provider_code,
                provider_name

            ORDER BY
                total_claims DESC

            LIMIT 10;
            """
        )

        rows = cursor.fetchall()

        return [
            {
                "provider_code": str(
                    row[0]
                ),
                "provider_name": row[1],
                "total_claims": row[2],
                "total_acc": row[3],
                "total_reject": row[4],
                "reject_rate": float(
                    row[5] or 0
                ),
                "total_approved": float(
                    row[6]
                ),
            }
            for row in rows
        ]

    finally:

        cursor.close()
        conn.close()