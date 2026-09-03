from datetime import datetime
from pathlib import Path
import json

import joblib
import numpy as np
import pandas as pd

from sklearn.compose import ColumnTransformer
from sklearn.ensemble import RandomForestRegressor
from sklearn.impute import SimpleImputer
from sklearn.metrics import (
    mean_absolute_error,
    mean_squared_error,
    r2_score,
)
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder

from backend.db import get_connection


# ============================================================
# SMARTCLAIM PREDICTION MODEL
# ============================================================

MODEL_VERSION = "v1.0.0"
RANDOM_STATE = 42

TARGET = "approved_amt"


# ============================================================
# INPUT FEATURES
#
# Tidak menggunakan:
# - approved_amt
# - notapproved_amt
# - claim_result
#
# karena ketiganya merupakan hasil/keputusan klaim.
# ============================================================

NUMERIC_FEATURES = [
    "incurred_amt",
    "length_of_stay",
]


CATEGORICAL_FEATURES = [
    "coverage_id",
    "plan_code",
    "admission_type",
    "claim_type",
    "corp_code",
    "provider_code",
    "primary_diagnosis",
]


FEATURES = (
    NUMERIC_FEATURES
    + CATEGORICAL_FEATURES
)


# ============================================================
# ARTIFACT PATH
# ============================================================

BASE_DIR = Path(
    __file__
).resolve().parent


ARTIFACT_DIR = (
    BASE_DIR
    / "artifacts"
)


MODEL_PATH = (
    ARTIFACT_DIR
    / "claim_rf_v1.joblib"
)


METADATA_PATH = (
    ARTIFACT_DIR
    / "claim_rf_v1_metadata.json"
)


# ============================================================
# LOAD HISTORICAL CLAIMS
# ============================================================

def load_training_data():

    conn = get_connection()

    query = """
        SELECT
            incurred_amt,
            length_of_stay,
            coverage_id,
            plan_code,
            admission_type,
            claim_type,
            corp_code,
            provider_code,
            primary_diagnosis,
            approved_amt

        FROM claims_analytics

        WHERE
            incurred_amt IS NOT NULL
            AND approved_amt IS NOT NULL
            AND incurred_amt > 0
            AND approved_amt >= 0;
    """

    try:

        dataframe = pd.read_sql_query(
            query,
            conn,
        )

    finally:

        conn.close()

    return dataframe


# ============================================================
# CLEAN DATA
# ============================================================

def prepare_data(
    dataframe: pd.DataFrame,
):

    data = dataframe.copy()

    # --------------------------------------------------------
    # NUMERIC
    # --------------------------------------------------------

    for column in NUMERIC_FEATURES:

        data[column] = pd.to_numeric(
            data[column],
            errors="coerce",
        )


    data[TARGET] = pd.to_numeric(
        data[TARGET],
        errors="coerce",
    )


    # --------------------------------------------------------
    # WAJIB ADA
    # --------------------------------------------------------

    data = data.dropna(
        subset=[
            "incurred_amt",
            TARGET,
        ]
    )


    # --------------------------------------------------------
    # CATEGORICAL
    # --------------------------------------------------------

    for column in CATEGORICAL_FEATURES:

        data[column] = (
            data[column]
            .fillna("UNKNOWN")
            .astype(str)
            .str.strip()
        )

        data.loc[
            data[column] == "",
            column,
        ] = "UNKNOWN"


    return data


# ============================================================
# PREPROCESSING
# ============================================================

def build_preprocessor():

    numeric_pipeline = Pipeline(
        steps=[
            (
                "imputer",
                SimpleImputer(
                    strategy="median",
                ),
            ),
        ]
    )


    categorical_pipeline = Pipeline(
        steps=[
            (
                "imputer",
                SimpleImputer(
                    strategy="most_frequent",
                ),
            ),

            (
                "onehot",
                OneHotEncoder(
                    handle_unknown="ignore",

                    # kategori sangat jarang
                    # digabung supaya model lebih ringan
                    min_frequency=5,

                    sparse_output=True,
                ),
            ),
        ]
    )


    return ColumnTransformer(
        transformers=[
            (
                "numeric",
                numeric_pipeline,
                NUMERIC_FEATURES,
            ),

            (
                "categorical",
                categorical_pipeline,
                CATEGORICAL_FEATURES,
            ),
        ],
        remainder="drop",
    )


# ============================================================
# MAIN TRAINING
# ============================================================

def main():

    print()
    print("=" * 68)

    print(
        "SMARTCLAIM - RANDOM FOREST APPROVED AMOUNT PREDICTION"
    )

    print("=" * 68)


    # ========================================================
    # 1. LOAD DATA
    # ========================================================

    print(
        "\n[1] Mengambil historical claims..."
    )


    dataframe = (
        load_training_data()
    )


    print(
        f"Data database     : "
        f"{len(dataframe):,}"
    )


    if dataframe.empty:

        raise RuntimeError(
            "Dataset training kosong."
        )


    # ========================================================
    # 2. PREPARE
    # ========================================================

    data = prepare_data(
        dataframe
    )


    print(
        f"Data siap modeling: "
        f"{len(data):,}"
    )


    X = data[
        FEATURES
    ].copy()


    y = data[
        TARGET
    ].copy()


    # ========================================================
    # 3. TRAIN / TEST
    # ========================================================

    (
        X_train,
        X_test,
        y_train,
        y_test,
    ) = train_test_split(
        X,
        y,
        test_size=0.20,
        random_state=RANDOM_STATE,
    )


    print(
        f"Training records  : "
        f"{len(X_train):,}"
    )


    print(
        f"Testing records   : "
        f"{len(X_test):,}"
    )


    # ========================================================
    # 4. PREPROCESS
    # ========================================================

    print(
        "\n[2] Menjalankan preprocessing..."
    )


    preprocessor = (
        build_preprocessor()
    )


    X_train_processed = (
        preprocessor.fit_transform(
            X_train
        )
    )


    X_test_processed = (
        preprocessor.transform(
            X_test
        )
    )


    # ========================================================
    # 5. RANDOM FOREST
    #
    # FIXED PARAMETER.
    # TIDAK ADA PSO.
    # TIDAK ADA GRID SEARCH.
    # TIDAK ADA OPTIMASI.
    # ========================================================

    print(
        "\n[3] Training Random Forest Regressor..."
    )


    model = RandomForestRegressor(
        n_estimators=200,
        max_depth=18,
        min_samples_split=4,
        min_samples_leaf=2,
        random_state=RANDOM_STATE,
        n_jobs=-1,
    )


    model.fit(
        X_train_processed,
        y_train,
    )


    # ========================================================
    # 6. TEST PREDICTION
    # ========================================================

    print(
        "\n[4] Evaluasi model..."
    )


    prediction = model.predict(
        X_test_processed
    )


    prediction = np.maximum(
        prediction,
        0,
    )


    # ========================================================
    # METRICS
    # ========================================================

    mae = mean_absolute_error(
        y_test,
        prediction,
    )


    rmse = np.sqrt(
        mean_squared_error(
            y_test,
            prediction,
        )
    )


    r2 = r2_score(
        y_test,
        prediction,
    )


    print()
    print(
        f"MAE  : Rp {mae:,.0f}"
    )

    print(
        f"RMSE : Rp {rmse:,.0f}"
    )

    print(
        f"R²   : {r2:.6f}"
    )


    # ========================================================
    # FEATURE NAMES
    # ========================================================

    feature_names = (
        preprocessor
        .get_feature_names_out()
        .tolist()
    )


    # ========================================================
    # 7. SAVE MODEL
    # ========================================================

    ARTIFACT_DIR.mkdir(
        parents=True,
        exist_ok=True,
    )


    artifact = {

        "model_name":
            "Random Forest Regressor",

        "model_version":
            MODEL_VERSION,

        "target":
            TARGET,

        "features":
            FEATURES,

        "numeric_features":
            NUMERIC_FEATURES,

        "categorical_features":
            CATEGORICAL_FEATURES,

        "feature_names":
            feature_names,

        "preprocessor":
            preprocessor,

        "model":
            model,
    }


    joblib.dump(
        artifact,
        MODEL_PATH,
        compress=3,
    )


    # ========================================================
    # 8. SAVE METADATA
    # ========================================================

    metadata = {

        "model_name":
            "Random Forest Regressor",

        "model_version":
            MODEL_VERSION,

        "target":
            TARGET,

        "trained_at":
            datetime.now().isoformat(),

        "total_records":
            int(
                len(data)
            ),

        "training_records":
            int(
                len(X_train)
            ),

        "testing_records":
            int(
                len(X_test)
            ),

        "metrics": {

            "mae":
                float(mae),

            "rmse":
                float(rmse),

            "r2":
                float(r2),
        },

        "training_mode":
            "manual_only",

        "automatic_retraining":
            False,
    }


    with open(
        METADATA_PATH,
        "w",
        encoding="utf-8",
    ) as file:

        json.dump(
            metadata,
            file,
            indent=2,
            ensure_ascii=False,
        )


    # ========================================================
    # COMPLETE
    # ========================================================

    print()
    print("=" * 68)

    print(
        "MODEL V1 BERHASIL DISIMPAN"
    )

    print()

    print(
        f"Model    : {MODEL_PATH}"
    )

    print(
        f"Metadata : {METADATA_PATH}"
    )

    print()

    print(
        "Automatic Retraining : OFF"
    )

    print(
        "Training Mode        : MANUAL ONLY"
    )

    print("=" * 68)


if __name__ == "__main__":

    main()