# Build stage
# Use Python 3.12 base image
FROM python:3.12 as builder

# Install uv package manager
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Set working directory
WORKDIR /app

# Copy pyproject.toml
COPY pyproject.toml ./

# Install Python dependencies using uv into a virtual environment
RUN uv sync --no-install-project --no-editable


# Final stage
# Use Python 3.12-slim base image (smaller footprint)
FROM python:3.12-slim as final

# Copy the virtual environment from build stage
COPY --from=builder --chown=app:app /app/.venv /app/.venv

# Copy application source code
COPY . /cc_simple_server ./

# Environment setup (use venv and sane defaults)
ENV VIRTUAL_ENV=/app/.venv \
    PATH="/app/.venv/bin:${PATH}" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Create non-root user for security
RUN useradd -m app

# Expose port 8000
EXPOSE 8000

# Set CMD to run FastAPI server on 0.0.0.0:8000
CMD ["uvicorn", "cc_simple_server.server:app", "--reload", "--host", "0.0.0.0", "--port", "8000"]