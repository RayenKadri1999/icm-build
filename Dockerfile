# Base image with CUDA runtime
FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04

# Set noninteractive for apt
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget curl git sudo vim nano bzip2 ca-certificates libglib2.0-0 libsm6 libxrender1 libxext6 \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user (for Kubeflow Notebook)
ARG NB_USER=jovyan
ARG NB_UID=1000
ENV USER=${NB_USER}
ENV HOME=/home/${NB_USER}
RUN useradd -m -s /bin/bash -N -u ${NB_UID} ${NB_USER} \
    && mkdir -p ${HOME}/.local/bin \
    && chown -R ${NB_USER}:${NB_USER} ${HOME}

USER ${NB_USER}
WORKDIR ${HOME}

# Install Micromamba (lightweight Conda alternative)
RUN curl -L https://micromamba.snakepit.net/api/micromamba/linux-64/latest | tar -xvj bin/micromamba \
    && mkdir -p ~/micromamba \
    && mv bin/micromamba ~/micromamba/ \
    && rm -rf bin

ENV PATH="${HOME}/micromamba:$PATH"

# Create Python 3.8.20 environment
RUN micromamba create -y -n py38_env -c conda-forge python=3.8.20 \
    jupyterlab ipykernel numpy pandas matplotlib scikit-learn \
    && micromamba clean --all --yes

# Activate environment for all future RUN commands
SHELL ["micromamba", "run", "-n", "py38_env", "/bin/bash", "-c"]

# Install PyTorch + CUDA 11.8
RUN pip install --upgrade pip \
    && pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

# Install VS Code Server
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Expose VS Code Server port
EXPOSE 8080

# Default password (override via KUBEFLOW env)
ENV PASSWORD="kubeflow"

# Start VS Code Server on container start
ENTRYPOINT ["code-server", "--bind-addr", "0.0.0.0:8080", "--auth", "password"]
