# ---- Base image ----
FROM python:3.14-slim

# ---- Environment variables ----
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# ---- Working directory ----
WORKDIR /app

# ---- System dependencies ----
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# ---- Install uv (official installer) ----
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.cargo/bin:/root/.local/bin:${PATH}"

# ---- Copy project files ----
COPY pyproject.toml uv.lock ./
COPY .python-version ./
COPY README.md LICENSE nvidia_nim_models.json ./
COPY claude-pick ./

# Application code
COPY api/ ./api/
COPY cli/ ./cli/
COPY config/ ./config/
COPY messaging/ ./messaging/
COPY providers/ ./providers/
COPY tests/ ./tests/
COPY server.py ./

# ---- Install Python dependencies ----
RUN uv sync --frozen

# ---- Expose application port ----
EXPOSE 8082

# ---- Health check ----
# HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
#     CMD curl -f http://localhost:8082/health || exit 1

# ---- Run the proxy server ----
CMD ["uv", "run", "uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8082", "--timeout-graceful-shutdown", "5"]
