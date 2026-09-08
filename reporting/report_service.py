"""Python/Pandas reporting service for Nway's Love Vet Clinic.

Reads the clinic's PostgreSQL data (the same database the Node backend uses) and
produces operational reports with pandas. Exposed as a small Flask HTTP API so
the Flutter app, the React staff app, or an analyst can consume JSON or download
CSV.

The feature tables share the shape (id, owner_id, data JSONB, version,
created_at, updated_at) where the business record lives in data->'value'.

Run:
    cd reporting
    python -m venv .venv && source .venv/bin/activate
    pip install -r requirements.txt
    python report_service.py            # serves on http://127.0.0.1:5060

Environment (mirrors backend/.env; falls back to the same defaults):
    DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD
    REPORT_PORT (default 5060), REPORT_HOST (default 127.0.0.1)
"""
import io
import os

import pandas as pd
import psycopg
from dotenv import load_dotenv
from flask import Flask, jsonify, Response

# Load backend/.env if present so we reuse the same DB credentials.
_BACKEND_ENV = os.path.join(os.path.dirname(__file__), "..", "backend", ".env")
if os.path.exists(_BACKEND_ENV):
    load_dotenv(_BACKEND_ENV)

DB_CONFIG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "port": int(os.getenv("DB_PORT", "5432")),
    "dbname": os.getenv("DB_NAME", "NwayLoveVetClinicSever"),
    "user": os.getenv("DB_USER", "postgres"),
    "password": os.getenv("DB_PASSWORD", ""),
}

app = Flask(__name__)


def load_table(table: str) -> pd.DataFrame:
    """Load a feature table into a DataFrame with the JSONB value flattened.

    Only a fixed allow-list of table names is accepted to avoid SQL injection,
    since the table name cannot be parameterized.
    """
    if table not in ALLOWED_TABLES:
        raise ValueError(f"Unknown table: {table}")
    # data->'value' holds the record fields; created_at drives time series.
    query = (
        f"SELECT id, owner_id, data->'value' AS value, created_at "
        f"FROM {table} ORDER BY created_at"
    )
    with psycopg.connect(**DB_CONFIG) as conn:
        with conn.cursor() as cur:
            cur.execute(query)
            rows = cur.fetchall()
    df = pd.DataFrame(rows, columns=["id", "owner_id", "value", "created_at"])
    if df.empty:
        return df
    # Expand the JSON 'value' object into columns.
    value_df = pd.json_normalize(df["value"])
    value_df.index = df.index
    out = pd.concat([df.drop(columns=["value"]), value_df], axis=1)
    out["created_at"] = pd.to_datetime(out["created_at"], utc=True)
    return out


ALLOWED_TABLES = {
    "appointments",
    "walk_in_appointments",
    "payments",
    "queue_entries",
    "inventory",
    "medical_records",
    "home_visits",
    "emergency_requests",
}


def _count_by(df: pd.DataFrame, column: str) -> dict:
    if df.empty or column not in df.columns:
        return {}
    return df[column].fillna("Unknown").astype(str).value_counts().to_dict()


def build_appointments_report() -> dict:
    df = load_table("appointments")
    walk = load_table("walk_in_appointments")
    total = int(len(df) + len(walk))
    by_status = _count_by(df, "status")
    # Daily counts for a simple time series.
    daily = {}
    if not df.empty:
        daily = (
            df.set_index("created_at")
            .resample("D")
            .size()
            .rename("count")
            .reset_index()
            .assign(created_at=lambda d: d["created_at"].dt.strftime("%Y-%m-%d"))
            .set_index("created_at")["count"]
            .to_dict()
        )
    return {
        "total_appointments": total,
        "scheduled": int(len(df)),
        "walk_in": int(len(walk)),
        "by_status": by_status,
        "daily_counts": daily,
    }


def build_payments_report() -> dict:
    df = load_table("payments")
    if df.empty:
        return {"total_payments": 0, "total_revenue": 0.0, "by_method": {}}
    # Amount may live under different keys depending on the client; be tolerant.
    amount_col = next(
        (c for c in ("amount", "total", "value_amount") if c in df.columns), None
    )
    total_revenue = 0.0
    if amount_col is not None:
        total_revenue = float(
            pd.to_numeric(df[amount_col], errors="coerce").fillna(0).sum()
        )
    return {
        "total_payments": int(len(df)),
        "total_revenue": round(total_revenue, 2),
        "by_method": _count_by(df, "method"),
        "by_status": _count_by(df, "status"),
    }


def build_queue_report() -> dict:
    df = load_table("queue_entries")
    return {
        "total_queue_entries": int(len(df)),
        "by_status": _count_by(df, "status"),
    }


def build_inventory_report() -> dict:
    df = load_table("inventory")
    if df.empty:
        return {"total_items": 0, "low_stock": [], "total_units": 0}
    qty_col = next(
        (c for c in ("quantity", "stock", "count") if c in df.columns), None
    )
    name_col = next((c for c in ("name", "item", "title") if c in df.columns), None)
    low_stock = []
    total_units = 0
    if qty_col is not None:
        qty = pd.to_numeric(df[qty_col], errors="coerce").fillna(0)
        total_units = int(qty.sum())
        low_mask = qty <= 5
        if name_col is not None:
            low_stock = df.loc[low_mask, name_col].astype(str).tolist()
        else:
            low_stock = df.loc[low_mask, "id"].astype(str).tolist()
    return {
        "total_items": int(len(df)),
        "total_units": total_units,
        "low_stock": low_stock,
    }


REPORTS = {
    "appointments": build_appointments_report,
    "payments": build_payments_report,
    "queue": build_queue_report,
    "inventory": build_inventory_report,
}


@app.get("/health")
def health():
    try:
        with psycopg.connect(**DB_CONFIG) as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT 1")
                cur.fetchone()
        return jsonify({"status": "ok", "database": "connected"})
    except Exception as e:  # noqa: BLE001
        return jsonify({"status": "error", "message": str(e)}), 500


@app.get("/reports")
def list_reports():
    return jsonify({"reports": sorted(REPORTS.keys())})


@app.get("/reports/<name>")
def get_report(name: str):
    builder = REPORTS.get(name)
    if builder is None:
        return jsonify({"message": f"Unknown report: {name}"}), 404
    try:
        return jsonify({"report": name, "data": builder()})
    except Exception as e:  # noqa: BLE001
        return jsonify({"message": str(e)}), 500


@app.get("/reports/<name>.csv")
def get_report_csv(name: str):
    """Download the raw underlying table for a report as CSV (pandas export)."""
    table_for_report = {
        "appointments": "appointments",
        "payments": "payments",
        "queue": "queue_entries",
        "inventory": "inventory",
    }.get(name)
    if table_for_report is None:
        return jsonify({"message": f"Unknown report: {name}"}), 404
    df = load_table(table_for_report)
    buf = io.StringIO()
    df.to_csv(buf, index=False)
    return Response(
        buf.getvalue(),
        mimetype="text/csv",
        headers={"Content-Disposition": f"attachment; filename={name}.csv"},
    )


if __name__ == "__main__":
    host = os.getenv("REPORT_HOST", "127.0.0.1")
    port = int(os.getenv("REPORT_PORT", "5060"))
    app.run(host=host, port=port)
