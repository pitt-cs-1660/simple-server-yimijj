# Stage 1: Builder (Install Dependencies)
FROM python:3.12 AS builder

# Install uv package manager
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/

# Set working directory and venv path for this stage
WORKDIR /app
ENV VIRTUAL_ENV=/app/.venv
ENV PATH="/app/.venv/bin:${PATH}"

# Copy pyproject.toml
COPY pyproject.toml ./

# Install Python dependencies using uv into a virtual environment
RUN uv sync --no-install-project --no-editable


# Stage 2: Final (Runtime Environment)
FROM python:3.12-slim

# Create non-root user 'app'
RUN useradd -r app

# 1. CRITICAL: Set the working directory for the final stage
WORKDIR /app

# 2. CRITICAL FIX: Set PATH and other ENV variables
ENV PATH="/app/.venv/bin:${PATH}" 
ENV PYTHONPATH="/app:${PYTHONPATH}" 
ENV VIRTUAL_ENV=/app/.venv
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1

# 3. Copy the virtual environment with correct ownership
COPY --from=builder --chown=app:app /app/.venv /app/.venv

# 4. CRITICAL FIX: Correct the COPY command to ensure module structure is right
COPY --chown=app:app . .

# 5. Grant the 'app' user write permissions for database and pytest cache
RUN chown -R app:app /app && chmod -R u+rw /app

# 6. CRITICAL: Switch context to non-root user (Order is key)
USER app

# Expose port 8000
EXPOSE 8000

# CMD uses the absolute path for robustness
CMD ["/app/.venv/bin/python", "-m", "uvicorn", "cc_simple_server.server:app", "--host", "0.0.0.0", "--port", "8000"]