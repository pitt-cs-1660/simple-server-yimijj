# # Build stage
# FROM python:3.12 as builder

# COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# WORKDIR /app

# COPY pyproject.toml ./

# RUN uv sync --no-install-project --no-editable



# # Final stage
# FROM python:3.12-slim as final

# COPY --from=builder --chown=app:app /app/.venv /app/.venv

# COPY . /cc_simple_server ./

# ENV VIRTUAL_ENV=/app/.venv
# ENV PATH="/app/.venv/bin:${PATH}"
# ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1

# EXPOSE 8000

# CMD ["uvicorn", "cc_simple_server.server:app", "--reload", "--host", "0.0.0.0", "--port", "8000"]

# build stage - install dependencies and tools
FROM python:3.12-slim AS builder

# install uv package manager
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

WORKDIR /app

# copy only dependency files first (better caching)
COPY pyproject.toml ./

# install dependencies without the project itself
RUN uv sync --no-install-project --no-editable

# copy source code
COPY src/ ./src/

# now install the complete project
RUN uv sync --no-editable

# final stage - runtime environment
FROM python:3.12-slim

# set up virtual environment variables
# @note: these variables make the venv active by default
ENV VIRTUAL_ENV=/app/.venv
ENV PATH="/app/.venv/bin:${PATH}"
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1

WORKDIR /app

# copy only the virtual environment from builder
# @note: this excludes build tools and intermediate files
COPY --from=builder /app/.venv /app/.venv

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]