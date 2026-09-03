import os

import psycopg2
from dotenv import load_dotenv


# ============================================================
# PROJECT CONFIG
# ============================================================

BASE_DIR = os.path.dirname(
    os.path.dirname(os.path.abspath(__file__))
)

load_dotenv(
    os.path.join(BASE_DIR, ".env")
)


# ============================================================
# POSTGRESQL CONFIG
# ============================================================

DB_CONFIG = {
    "host": os.getenv(
        "DB_HOST",
        "localhost",
    ),
    "port": os.getenv(
        "DB_PORT",
        "5432",
    ),
    "dbname": os.getenv(
        "POSTGRES_DB"
    ),
    "user": os.getenv(
        "POSTGRES_USER"
    ),
    "password": os.getenv(
        "POSTGRES_PASSWORD"
    ),
}


# ============================================================
# DATABASE CONNECTION
# ============================================================

def get_connection():
    return psycopg2.connect(
        **DB_CONFIG
    )