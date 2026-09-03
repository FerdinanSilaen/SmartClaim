from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from starlette.concurrency import run_in_threadpool

from backend.services.gemini_service import (
    GEMINI_MODEL,
    GeminiAnalysisError,
    GeminiConfigurationError,
    generate_claim_analysis,
)


# ============================================================
# ROUTER
# ============================================================

router = APIRouter(
    prefix="/api/gemini",
    tags=["Gemini AI"],
)


# ============================================================
# REQUEST MODEL
# ============================================================

class ClaimAnalysisRequest(BaseModel):
    incurred_amount: float = Field(
        gt=0,
        description="Nilai klaim yang diajukan.",
    )

    predicted_approved_amount: float = Field(
        ge=0,
        description="Estimasi approved dari Random Forest.",
    )

    coverage_id: str = Field(
        min_length=1,
        max_length=50,
        description="Jenis coverage klaim.",
    )

    length_of_stay: float = Field(
        ge=0,
        le=3650,
        description="Lama rawat dalam hari.",
    )


# ============================================================
# RESPONSE MODEL
# ============================================================

class ClaimAnalysisResponse(BaseModel):
    status: str
    model: str
    analysis: str

    incurred_amount: float
    predicted_approved_amount: float
    estimated_difference: float
    approval_ratio: float


# ============================================================
# ANALYZE CLAIM
# ============================================================

@router.post(
    "/analyze-claim",
    response_model=ClaimAnalysisResponse,
)
async def analyze_claim(
    payload: ClaimAnalysisRequest,
):
    """
    Membuat analisis Gemini berdasarkan hasil prediksi Random Forest.

    Endpoint hanya menerima data ringkasan dan tidak menerima
    identitas peserta, nomor polis, nomor klaim, atau diagnosis.
    """

    incurred_amount = float(
        payload.incurred_amount
    )

    predicted_approved_amount = min(
        float(payload.predicted_approved_amount),
        incurred_amount,
    )

    estimated_difference = max(
        incurred_amount - predicted_approved_amount,
        0.0,
    )

    approval_ratio = (
        predicted_approved_amount
        / incurred_amount
        * 100
    )

    try:
        analysis = await run_in_threadpool(
            generate_claim_analysis,
            incurred_amount=incurred_amount,
            predicted_approved_amount=predicted_approved_amount,
            estimated_difference=estimated_difference,
            approval_ratio=approval_ratio,
            coverage_id=payload.coverage_id.strip(),
            length_of_stay=float(
                payload.length_of_stay
            ),
        )

        return ClaimAnalysisResponse(
            status="success",
            model=GEMINI_MODEL,
            analysis=analysis,
            incurred_amount=incurred_amount,
            predicted_approved_amount=(
                predicted_approved_amount
            ),
            estimated_difference=(
                estimated_difference
            ),
            approval_ratio=approval_ratio,
        )

    except GeminiConfigurationError as error:
        raise HTTPException(
            status_code=503,
            detail=str(error),
        ) from error

    except GeminiAnalysisError as error:
        raise HTTPException(
            status_code=502,
            detail=str(error),
        ) from error

    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=(
                "Terjadi kesalahan internal "
                "saat membuat analisis Gemini."
            ),
        ) from error