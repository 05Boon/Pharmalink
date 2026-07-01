# --- Stage 1: Build dependencies ---
FROM python:3.14-slim AS builder

WORKDIR /app

# Install compilation tools for python packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

# Install dependencies into user local space to facilitate multi-stage copying
RUN pip install --no-cache-dir --user -r requirements.txt

# --- Stage 2: Final lightweight runner ---
FROM python:3.14-slim

WORKDIR /app

# Copy only the pre-compiled packages from the builder stage
COPY --from=builder /root/.local /root/.local
COPY . .

# Ensure user local bin is in PATH
ENV PATH=/root/.local/bin:$PATH
# Prevent Python from writing pyc files and buffering stdout/stderr
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

EXPOSE 8000

# Server is started via docker-compose configuration command to run create_tables.py first
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
