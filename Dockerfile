FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/home/jovyan
RUN mkdir -p $HOME && chmod -R 777 $HOME
WORKDIR $HOME

# System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget curl git sudo bzip2 ca-certificates libglib2.0-0 libsm6 libxrender1 libxext6 \
    python3 python3-pip python3-venv vim nano \
    && rm -rf /var/lib/apt/lists/*

# Install Micromamba
RUN curl -L https://micromamba.snakepit.net/api/micromamba/linux-64/latest | tar -xvj bin/micromamba \
    && mkdir -p ~/micromamba && mv bin/micromamba ~/micromamba/ && rm -rf bin
ENV PATH="${HOME}/micromamba:$PATH"

# Create Python 3.8.20 environment
RUN micromamba create -y -n py38_env -c conda-forge python=3.8.20 \
    jupyterlab ipykernel numpy pandas matplotlib scikit-learn \
    && micromamba clean --all --yes

# Activate environment
SHELL ["micromamba", "run", "-n", "py38_env", "/bin/bash", "-c"]

# PyTorch + CUDA
RUN pip install --upgrade pip \
    && pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

# VS Code Server
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Expose VS Code port
EXPOSE 8080
ENV PASSWORD="kubeflow"

ENTRYPOINT ["code-server", "--bind-addr", "0.0.0.0:8080", "--auth", "password"]
