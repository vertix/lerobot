FROM nvidia/cuda:12.4.1-base-ubuntu22.04

# Configure image
ARG PYTHON_VERSION=3.10
ARG DEBIAN_FRONTEND=noninteractive


# Install apt dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential curl cmake \
    libglib2.0-0 libgl1-mesa-glx libegl1-mesa ffmpeg \
    speech-dispatcher \
    python${PYTHON_VERSION}-dev python${PYTHON_VERSION}-venv \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install poetry
RUN curl -sSL https://install.python-poetry.org | python3 -
ENV PATH="${PATH}:/root/.local/bin"

# Set python symlink
RUN ln -s /usr/bin/python3 /usr/bin/python

# Install dependencies
COPY poetry.lock pyproject.toml /lerobot/

WORKDIR /lerobot

RUN poetry config virtualenvs.create false
RUN poetry install --no-root --no-interaction --no-ansi

# Set EGL as the rendering backend for MuJoCo
ENV MUJOCO_GL="egl"

# Set the data directory for lerobot
ENV DATA_DIR="/data"
ENV PYTHONPATH="/lerobot"

# assume that user will mount the data directory to /data and the current directory to /lerobot
