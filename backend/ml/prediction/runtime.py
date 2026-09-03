from functools import lru_cache
from pathlib import Path
import json

import joblib
import numpy as np
import pandas as pd
import shap


# ============================================================
# PATH
# ============================================================

BASE_DIR = Path(
    __file__
).resolve().parent


MODEL_PATH = (
    BASE_DIR
    / "artifacts"
    / "claim_rf_v1.joblib"
)


METADATA_PATH = (
    BASE_DIR
    / "artifacts"
    / "claim_rf_v1_metadata.json"
)


# ============================================================
# DISPLAY LABEL
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
# LOAD MODEL
#
# Model hanya dibaca sekali selama FastAPI hidup.
# TIDAK ADA TRAINING.
# ============================================================

@lru_cache(maxsize=1)
def load_model_bundle():

    if not MODEL_PATH.exists():

        raise FileNotFoundError(
            "Model Prediction SmartClaim "
            "belum tersedia."
        )

    return joblib.load(
        MODEL_PATH
    )


# ============================================================
# LOAD METADATA
# ============================================================

@lru_cache(maxsize=1)
def load_model_metadata():

    if not METADATA_PATH.exists():

        raise FileNotFoundError(
            "Metadata model Prediction "
            "belum tersedia."
        )

    with open(
        METADATA_PATH,
        "r",
        encoding="utf-8",
    ) as file:

        return json.load(
            file
        )


# ============================================================
# SHAP EXPLAINER
#
# Hanya dibuat satu kali.
# Tidak melakukan fit / training.
# ============================================================

@lru_cache(maxsize=1)
def load_shap_explainer():

    bundle = (
        load_model_bundle()
    )

    model = bundle[
        "model"
    ]

    return shap.TreeExplainer(
        model
    )


# ============================================================
# MODEL STATUS
# ============================================================

def get_model_status():

    metadata = (
        load_model_metadata()
    )

    return {
        "ready":
            True,

        "model_name":
            metadata[
                "model_name"
            ],

        "model_version":
            metadata[
                "model_version"
            ],

        "target":
            metadata[
                "target"
            ],

        "r2":
            metadata[
                "metrics"
            ][
                "r2"
            ],

        "mae":
            metadata[
                "metrics"
            ][
                "mae"
            ],

        "rmse":
            metadata[
                "metrics"
            ][
                "rmse"
            ],

        "automatic_retraining":
            False,

        "explainable_ai":
            "SHAP",
    }


# ============================================================
# PREPARE INPUT
# ============================================================

def prepare_input(
    payload: dict,
):

    bundle = (
        load_model_bundle()
    )

    features = bundle[
        "features"
    ]

    numeric_features = bundle[
        "numeric_features"
    ]

    categorical_features = bundle[
        "categorical_features"
    ]

    row = {}

    for feature in features:

        value = payload.get(
            feature
        )

        if feature in numeric_features:

            if value is None:

                row[feature] = (
                    np.nan
                )

            else:

                row[feature] = float(
                    value
                )

        elif (
            feature
            in categorical_features
        ):

            if value is None:

                row[feature] = (
                    "UNKNOWN"
                )

            else:

                cleaned = str(
                    value
                ).strip()

                row[feature] = (
                    cleaned
                    if cleaned
                    else "UNKNOWN"
                )

    return pd.DataFrame(
        [row]
    )


# ============================================================
# RESOLVE ONE-HOT FEATURE
#
# Contoh:
#
# categorical__coverage_id_GP
# menjadi:
# coverage_id
# ============================================================

def resolve_original_feature(
    encoded_feature: str,
    numeric_features: list,
    categorical_features: list,
):

    # ========================================================
    # NUMERIC
    # ========================================================

    if encoded_feature.startswith(
        "numeric__"
    ):

        return encoded_feature.replace(
            "numeric__",
            "",
            1,
        )


    # ========================================================
    # CATEGORICAL
    # ========================================================

    if encoded_feature.startswith(
        "categorical__"
    ):

        body = encoded_feature.replace(
            "categorical__",
            "",
            1,
        )

        # feature panjang dicek dulu
        # agar primary_diagnosis tidak salah parsing
        ordered_features = sorted(
            categorical_features,
            key=len,
            reverse=True,
        )

        for feature in ordered_features:

            if (
                body == feature
                or body.startswith(
                    f"{feature}_"
                )
            ):

                return feature


    return encoded_feature


# ============================================================
# SHAP EXPLANATION
#
# Mengelompokkan kembali one-hot encoded feature
# ke feature asli.
# ============================================================

def explain_prediction(
    transformed,
    payload: dict,
    top_n: int = 5,
):

    bundle = (
        load_model_bundle()
    )

    explainer = (
        load_shap_explainer()
    )

    feature_names = bundle[
        "feature_names"
    ]

    numeric_features = bundle[
        "numeric_features"
    ]

    categorical_features = bundle[
        "categorical_features"
    ]


    # ========================================================
    # SHAP membutuhkan bentuk dense untuk penjelasan
    # 1 record saja sehingga tetap ringan.
    # ========================================================

    if hasattr(
        transformed,
        "toarray",
    ):

        transformed_for_shap = (
            transformed.toarray()
        )

    else:

        transformed_for_shap = (
            np.asarray(
                transformed
            )
        )


    # ========================================================
    # CALCULATE SHAP
    # ========================================================

    shap_values = (
        explainer.shap_values(
            transformed_for_shap,
            check_additivity=False,
        )
    )


    # Beberapa versi SHAP dapat
    # mengembalikan list.
    if isinstance(
        shap_values,
        list,
    ):

        shap_values = (
            shap_values[0]
        )


    shap_values = np.asarray(
        shap_values
    )


    if shap_values.ndim == 2:

        values = shap_values[0]

    else:

        values = shap_values.reshape(
            -1
        )


    # ========================================================
    # GROUP BACK TO ORIGINAL FEATURES
    # ========================================================

    absolute_group = {}
    signed_group = {}


    for (
        encoded_feature,
        shap_value,
    ) in zip(
        feature_names,
        values,
    ):

        original_feature = (
            resolve_original_feature(
                encoded_feature,
                numeric_features,
                categorical_features,
            )
        )


        absolute_group[
            original_feature
        ] = (
            absolute_group.get(
                original_feature,
                0.0,
            )
            + abs(
                float(
                    shap_value
                )
            )
        )


        signed_group[
            original_feature
        ] = (
            signed_group.get(
                original_feature,
                0.0,
            )
            + float(
                shap_value
            )
        )


    # ========================================================
    # NORMALIZE CONTRIBUTION
    #
    # Menjadi relative contribution % untuk UI.
    # ========================================================

    total_absolute = sum(
        absolute_group.values()
    )


    factors = []


    for (
        feature,
        absolute_value,
    ) in absolute_group.items():

        if total_absolute > 0:

            contribution_pct = (
                absolute_value
                / total_absolute
                * 100
            )

        else:

            contribution_pct = 0.0


        signed_value = (
            signed_group.get(
                feature,
                0.0,
            )
        )


        if signed_value > 0:

            direction = (
                "increase"
            )

        elif signed_value < 0:

            direction = (
                "decrease"
            )

        else:

            direction = (
                "neutral"
            )


        raw_value = payload.get(
            feature
        )


        factors.append(
            {
                "feature":
                    feature,

                "label":
                    FEATURE_LABELS.get(
                        feature,
                        feature,
                    ),

                "value":
                    raw_value,

                "contribution_pct":
                    round(
                        contribution_pct,
                        2,
                    ),

                "direction":
                    direction,

                "shap_value":
                    round(
                        signed_value,
                        2,
                    ),
            }
        )


    # ========================================================
    # SORT DESCENDING
    # ========================================================

    factors.sort(
        key=lambda item:
            item[
                "contribution_pct"
            ],
        reverse=True,
    )


    return factors[
        :top_n
    ]


# ============================================================
# PREDICT
#
# HANYA model.predict()
# TIDAK ADA TRAINING.
# ============================================================

def predict_claim(
    payload: dict,
):

    bundle = (
        load_model_bundle()
    )


    preprocessor = bundle[
        "preprocessor"
    ]


    model = bundle[
        "model"
    ]


    dataframe = prepare_input(
        payload
    )


    transformed = (
        preprocessor.transform(
            dataframe
        )
    )


    # ========================================================
    # RANDOM FOREST PREDICTION
    # ========================================================

    predicted = float(
        model.predict(
            transformed
        )[0]
    )


    incurred = float(
        payload[
            "incurred_amt"
        ]
    )


    # ========================================================
    # SAFETY BOUND
    #
    # Bukan algoritma prediksi.
    # Nilai utama tetap Random Forest.
    # ========================================================

    predicted = float(
        np.clip(
            predicted,
            0,
            incurred,
        )
    )


    difference = (
        incurred
        - predicted
    )


    approval_ratio = (
        predicted
        / incurred
        * 100
    )


    # ========================================================
    # EXPLAINABLE AI
    # ========================================================

    top_factors = (
        explain_prediction(
            transformed,
            payload,
            top_n=5,
        )
    )


    metadata = (
        load_model_metadata()
    )


    # ========================================================
    # RESPONSE
    # ========================================================

    return {
        "model_name":
            metadata[
                "model_name"
            ],

        "model_version":
            metadata[
                "model_version"
            ],

        "target":
            metadata[
                "target"
            ],

        "incurred_amt":
            round(
                incurred,
                2,
            ),

        "predicted_approved_amt":
            round(
                predicted,
                2,
            ),

        "estimated_difference":
            round(
                difference,
                2,
            ),

        "approval_ratio":
            round(
                approval_ratio,
                2,
            ),

        "explainability_method":
            "SHAP",

        "top_factors":
            top_factors,
    }