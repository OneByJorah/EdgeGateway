# EdgeGateway — Docker-based deployment for dashboard only
# Note: The full EdgeGateway (WiFi AP, WARP tunnel, iptables) requires
# Raspberry Pi hardware and cannot be fully containerized.
# This Dockerfile provides the dashboard component for remote monitoring.

FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

# System deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Python deps
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# App code
COPY dashboard.py .
COPY templates/ templates/

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -sf http://localhost:5000/ || exit 1

EXPOSE 5000

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--timeout", "120", "dashboard:app"]
