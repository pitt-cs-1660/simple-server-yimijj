# Use Python 3.12 base image
FROM python:3.12 AS builder

# Install uv package manager
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/

# Set working directory
WORKDIR /app
ENV VIRTUAL_ENV=/app/.venv
ENV PATH="/app/.venv/bin:${PATH}"

# Copy pyproject.toml
COPY pyproject.toml ./

# Install Python dependencies using uv into a virtual environment
RUN uv sync --no-install-project --no-editable


# Use Python 3.12-slim base image (smaller footprint)
FROM python:3.12-slim

# # Create non-root user for security
# RUN useradd -r app

# Copy the virtual environment from build stage
WORKDIR /app
ENV PATH="/app/.venv/bin:${PATH}" 
ENV PYTHONPATH="/app:${PYTHONPATH}" 
ENV VIRTUAL_ENV=/app/.venv
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
COPY --from=builder --chown=app:app /app/.venv /app/.venv

# Copy application source code
COPY --chown=app:app . .

# Create non-root user for security
RUN useradd -r app
RUN chown -R app:app /app && chmod -R u+rw /app
USER app

# Expose port 8000
EXPOSE 8000

# Set CMD to run FastAPI server on 0.0.0.0:8000 
CMD ["/app/.venv/bin/python", "-m", "uvicorn", "cc_simple_server.server:app", "--host", "0.0.0.0", "--port", "8000"]