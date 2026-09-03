from backend.ml.prediction.runtime import (
    get_model_status,
    predict_claim,
)


# ============================================================
# LABEL
# ============================================================

FEATURE_LABELS = {
    "incurred_amt":
        "Incurred Amount",

    "length_of_stay":
        "Length of Stay",

    "coverage_id":
        "Coverage",

    "plan_code":
        "Plan Code",

    "admission_type":
        "Admission Type",

    "claim_type":
        "Claim Type",

    "corp_code":
        "Corporation",

    "provider_code":
        "Provider",

    "primary_diagnosis":
        "Primary Diagnosis",
}


# ============================================================
# DIRECTION LABEL
# ============================================================

def direction_text(
    direction: str,
):

    if direction == "increase":

        return (
            "mendorong prediksi naik"
        )

    if direction == "decrease":

        return (
            "mendorong prediksi turun"
        )

    return (
        "pengaruh relatif netral"
    )


# ============================================================
# SIMPLE EXPLANATION
#
# Bukan GPT.
# Dibangun langsung berdasarkan output SHAP.
# ============================================================

def build_explanation_summary(
    factors: list,
):

    if not factors:

        return (
            "Belum tersedia faktor "
            "penjelas untuk prediction ini."
        )


    strongest = factors[0]


    summary = (
        f"Faktor dengan kontribusi relatif "
        f"terbesar pada prediction ini adalah "
        f"{strongest['label']} "
        f"({strongest['contribution_pct']:.2f}%). "
    )


    if len(factors) >= 3:

        summary += (
            "Faktor penting berikutnya adalah "
            f"{factors[1]['label']} dan "
            f"{factors[2]['label']}. "
        )


    summary += (
        "Kontribusi dihitung menggunakan SHAP "
        "terhadap Random Forest v1 dan bukan "
        "merupakan keputusan approval."
    )


    return summary


# ============================================================
# CHATGPT PLUS BRIEF
#
# Tidak memanggil OpenAI API.
# Hanya menghasilkan teks copy-paste.
# ============================================================

def build_ai_brief(
    payload: dict,
    result: dict,
):

    model_name = result[
        "model_name"
    ]

    model_version = result[
        "model_version"
    ]

    incurred = result[
        "incurred_amt"
    ]

    predicted = result[
        "predicted_approved_amt"
    ]

    difference = result[
        "estimated_difference"
    ]

    ratio = result[
        "approval_ratio"
    ]


    # ========================================================
    # INPUT
    # ========================================================

    input_lines = []

    for (
        key,
        label,
    ) in FEATURE_LABELS.items():

        value = payload.get(
            key
        )

        if value is None:

            value = "-"

        input_lines.append(
            f"{label}: {value}"
        )


    inputs_text = "\n".join(
        input_lines
    )


    # ========================================================
    # SHAP FACTORS
    # ========================================================

    factor_lines = []

    for (
        index,
        factor,
    ) in enumerate(
        result.get(
            "top_factors",
            [],
        ),
        start=1,
    ):

        factor_lines.append(
            (
                f"{index}. "
                f"{factor['label']} "
                f"= {factor['value']} "
                f"| Contribution "
                f"{factor['contribution_pct']:.2f}% "
                f"| {direction_text(factor['direction'])}"
            )
        )


    factors_text = (
        "\n".join(
            factor_lines
        )
        if factor_lines
        else "Tidak tersedia."
    )


    # ========================================================
    # BRIEF
    # ========================================================

    return (
        "SMARTCLAIM PREDICTION ANALYSIS\n\n"

        "MODEL INFORMATION\n"

        f"Model: {model_name}\n"

        f"Version: {model_version}\n"

        "Algorithm: Random Forest Regressor\n"

        "Target: APPROVED_AMT\n"

        "Explainability: SHAP\n\n"

        "CLAIM INPUT\n"

        f"{inputs_text}\n\n"

        "PREDICTION RESULT\n"

        f"Incurred Amount: "
        f"Rp {incurred:,.2f}\n"

        f"Predicted Approved: "
        f"Rp {predicted:,.2f}\n"

        f"Estimated Difference: "
        f"Rp {difference:,.2f}\n"

        f"Approval Ratio: "
        f"{ratio:.2f}%\n\n"

        "TOP SHAP FACTORS\n"

        f"{factors_text}\n\n"

        "Tolong analisis hasil prediksi "
        "SmartClaim ini secara sederhana. "
        "Gunakan hanya hasil Random Forest "
        "dan faktor SHAP yang diberikan. "
        "Jangan mengubah angka prediction, "
        "jangan membuat faktor baru, dan "
        "jangan membuat keputusan approval."
    )


# ============================================================
# RUN PREDICTION
# ============================================================

def run_prediction(
    payload: dict,
):

    # ========================================================
    # RANDOM FOREST + SHAP
    #
    # Tidak melakukan fit().
    # ========================================================

    result = predict_claim(
        payload
    )


    # ========================================================
    # HUMAN READABLE XAI
    # ========================================================

    result[
        "explanation_summary"
    ] = build_explanation_summary(
        result.get(
            "top_factors",
            [],
        )
    )


    # ========================================================
    # CHATGPT PLUS HANDOFF
    # ========================================================

    result[
        "ai_brief"
    ] = build_ai_brief(
        payload,
        result,
    )


    return result


# ============================================================
# STATUS
# ============================================================

def prediction_model_status():

    return get_model_status()