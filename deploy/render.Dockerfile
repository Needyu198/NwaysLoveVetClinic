# Render production image: Node API and the private Python/Pandas worker.
FROM node:22-bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends python3 python3-venv \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY backend/package.json backend/package-lock.json ./backend/
RUN cd backend && npm ci --omit=dev

COPY reporting/requirements.txt ./reporting/
RUN python3 -m venv /opt/reporting-venv \
    && /opt/reporting-venv/bin/pip install --no-cache-dir \
      -r reporting/requirements.txt gunicorn==23.0.0

COPY backend/src ./backend/src
COPY backend/scripts ./backend/scripts
COPY reporting/report_service.py ./reporting/report_service.py
COPY deploy/start-render.sh ./deploy/start-render.sh

ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=5050
ENV REPORTING_URL=http://127.0.0.1:5060

EXPOSE 5050

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:'+(process.env.PORT||5050)+'/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

CMD ["bash", "/app/deploy/start-render.sh"]
