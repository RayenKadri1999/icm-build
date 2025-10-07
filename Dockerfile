# Base image with CUDA + Python
FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04

# Set noninteractive mode for apt
ENV DEBIAN_FRONTEND=noninteractive

# Install basic dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget curl git sudo vim nano python3 python3-pip python3-venv \
    libglib2.0-0 libsm6 libxrender1 libxext6 ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create a new user (for Kubeflow Notebook compatibility)
ARG NB_USER=jovyan
ARG NB_UID=1000
ENV USER=${NB_USER}
ENV HOME=/home/${NB_USER}
RUN useradd -m -s /bin/bash -N -u ${NB_UID} ${NB_USER} \
    && mkdir -p ${HOME}/.local/bin \
    && chown -R ${NB_USER}:${NB_USER} ${HOME}

USER ${NB_USER}
WORKDIR ${HOME}

# Install VS Code Server (code-server)
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Install PyTorch + CUDA
RUN pip install --upgrade pip && \
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

# (Optional) Install useful dev tools
RUN pip install jupyterlab numpy pandas matplotlib scikit-learn opencv-python

# Expose VS Code Server port
EXPOSE 8080

# Default password (you can override via KUBEFLOW)
ENV PASSWORD="kubeflow"

# Start VS Code Server
ENTRYPOINT ["code-server", "--bind-addr", "0.0.0.0:8080", "--auth", "password"]
