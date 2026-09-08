# Reporting service (Python + Pandas)

A standalone analytics service that reads the clinic's PostgreSQL data and
produces operational reports using **pandas**. It runs independently of the
Node backend and exposes a small Flask HTTP API returning JSON, plus CSV
downloads.

This implements the proposal's "Reporting (Python/Pandas)" component.

## Setup

```bash
cd reporting
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python report_service.py        # http://127.0.0.1:5060
```

It reads DB credentials from `backend/.env` automatically (falling back to the
same defaults as the Node backend). Override the port with `REPORT_PORT`.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Service + database connectivity |
| GET | `/reports` | List available reports |
| GET | `/reports/appointments` | Totals, by-status, daily time series |
| GET | `/reports/payments` | Payment count, total revenue, by method/status |
| GET | `/reports/queue` | Queue entry counts by status |
| GET | `/reports/inventory` | Item/unit totals and low-stock (qty ≤ 5) list |
| GET | `/reports/<name>.csv` | Download the underlying table as CSV |

## Notes

- Feature tables store their record under `data->'value'` (JSONB); the service
  flattens that with `pandas.json_normalize` before aggregating.
- Table access is restricted to a fixed allow-list in code (the table name
  cannot be parameterized in SQL), preventing injection.
- This is a read-only analytics layer; it never writes to the database.
- The bundled Flask server is for development. For production, run behind a WSGI
  server (e.g. gunicorn) — see `deploy/` for container configuration.
