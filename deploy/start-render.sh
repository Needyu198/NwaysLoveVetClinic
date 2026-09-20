#!/usr/bin/env bash
set -euo pipefail

cd /app/reporting
/opt/reporting-venv/bin/gunicorn \
  --bind 127.0.0.1:5060 \
  --workers 1 \
  --timeout 45 \
  --access-logfile - \
  --error-logfile - \
  report_service:app &
reporting_pid=$!

cd /app/backend
node src/server.js &
api_pid=$!

stop_services() {
  kill "$api_pid" "$reporting_pid" 2>/dev/null || true
}
trap stop_services EXIT INT TERM

# If either process exits, stop the container so Render restarts the complete
# API/reporting pair instead of leaving reports in a degraded state.
wait -n "$api_pid" "$reporting_pid"
