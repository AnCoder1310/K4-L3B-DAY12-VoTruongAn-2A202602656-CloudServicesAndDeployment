# ═══════════════════════════════════════════════════════════════════
# CP2 — Production-ready Dockerfile
# ═══════════════════════════════════════════════════════════════════

# ───────────────────────────────────────────────────────────────────
# Stage 1: Builder
# ───────────────────────────────────────────────────────────────────
FROM python:3.11-slim AS builder

WORKDIR /build

# Copy requirements trước để tận dụng Docker cache
COPY requirements.txt .

# Cài dependencies vào thư mục riêng
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt


# ───────────────────────────────────────────────────────────────────
# Stage 2: Runtime
# ───────────────────────────────────────────────────────────────────
FROM python:3.11-slim AS runtime

WORKDIR /app

# Chỉ copy dependencies từ builder
COPY --from=builder /install /usr/local

# Copy source code sau khi cài dependencies
COPY app ./app
COPY utils ./utils

# Tạo user không phải root
RUN useradd --create-home --shell /bin/bash appuser \
    && chown -R appuser:appuser /app

USER appuser

# Port mặc định
ENV PORT=8000

EXPOSE 8000

# Health check endpoint
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import os, urllib.request; urllib.request.urlopen('http://127.0.0.1:' + os.getenv('PORT', '8000') + '/health')" || exit 1

# Uvicorn đọc PORT từ environment
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]