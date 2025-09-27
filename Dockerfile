# Use Python 3.12 base image
FROM python:3.12 AS builder

# Install uv package manager
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/

# Set working directory
WORKDIR /app

# Copy pyproject.toml
COPY pyproject.toml ./

# Install Python dependencies using uv into a virtual environment
RUN uv sync --no-install-project --no-editable



# Use Python 3.12-slim base image (smaller footprint)
FROM python:3.12-slim

# Copy the virtual environment from the build stage
COPY --from=builder --chown=app:app /app/.venv /app/.venv

# Copy application source code
COPY . /cc_simple_server ./

# Change to the non-root user for security
RUN useradd -r app

# Expose port 8000
EXPOSE 8000

# Set CMD to run FastAPI server on 0.0.0.0:8000
CMD ["/app/.venv/bin/uvicorn", "cc_simple_server.server:app", "--reload", "--host", "0.0.0.0", "--port", "8000"]