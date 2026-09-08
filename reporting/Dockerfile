# Reporting service (Python + Flask + pandas), served by gunicorn in production.
FROM python:3.12-slim

WORKDIR /app

# Build deps for pandas/psycopg wheels are already prebuilt for py3.12-slim.
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt gunicorn==23.0.0

COPY report_service.py ./

ENV REPORT_HOST=0.0.0.0
ENV REPORT_PORT=5060
EXPOSE 5060

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD python -c "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:5060/health').status==200 else 1)"

# report_service.py exposes the Flask app object named `app`.
CMD ["gunicorn", "--bind", "0.0.0.0:5060", "--workers", "2", "report_service:app"]
