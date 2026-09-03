from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from backend.db import get_connection

from backend.routers.dashboard import (
    router as dashboard_router,
)

from backend.routers.claims import (
    router as claims_router,
)

from backend.routers.analytics import (
    router as analytics_router,
)

from backend.routers.prediction import (
    router as prediction_router,
)

from backend.routers.gemini import (
    router as gemini_router,
)


# ============================================================
# FASTAPI APP
# ============================================================

app = FastAPI(
    title="SmartClaim API",
    version="1.4.0",
    description=(
        "SmartClaim Health Claim Intelligence API "
        "with Gemini AI Analysis"
    ),
)


# ============================================================
# CORS
# ============================================================

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============================================================
# ROUTERS
# ============================================================

app.include_router(
    dashboard_router
)

app.include_router(
    claims_router
)

app.include_router(
    analytics_router
)

app.include_router(
    prediction_router
)

app.include_router(
    gemini_router
)


# ============================================================
# ROOT
# ============================================================

@app.get("/")
def root():

    return {
        "app": "SmartClaim API",
        "version": "1.4.0",
        "status": "running",
        "gemini_ai": "enabled",
    }


# ============================================================
# HEALTH
# ============================================================

@app.get("/health")
def health_check():

    conn = get_connection()
    cursor = conn.cursor()

    try:

        cursor.execute(
            "SELECT current_database();"
        )

        database = cursor.fetchone()[0]

        cursor.execute(
            "SELECT COUNT(*) FROM claims;"
        )

        total_claims = cursor.fetchone()[0]

        return {
            "status": "healthy",
            "database": database,
            "total_claims": total_claims,
        }

    finally:

        cursor.close()
        conn.close()