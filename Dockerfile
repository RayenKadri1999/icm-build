# Dockerfile.ojcas
ARG BASE_IMAGE=nvidia/cuda:11.3.1-cudnn8-runtime-ubuntu20.04
FROM ${BASE_IMAGE}

# Build args (set at docker build time)
ARG PYTHON_VERSION=3.8
ARG INSTALL_REPO=false           # set to "true" to clone and install your repo at build-time
ARG REPO_URL=""                  # repository URL to clone (if INSTALL_REPO=true)
ARG REPO_BRANCH="main"
ARG INSTALL_COMPRESSAI=true      # set to "false" to skip attempting to install compressai_v109 from repo
ARG DEBIAN_FRONTEND=noninteractive

ENV PATH=/opt/conda/bin:$PATH
ENV PYTHONUNBUFFERED=1
ENV DETECTRON2_DATASETS=/home/jovyan/datasets
ENV WORKSPACE=/home/jovyan
ENV HOME=/home/jovyan

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential git wget curl ca-certificates \
    cmake pkg-config unzip \
    python3.8 python3.8-dev python3-pip python3-venv \
    libjpeg-dev zlib1g-dev libglib2.0-0 libsm6 libxrender1 libxext6 \
    libssl-dev libffi-dev ninja-build pkg-config software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Install Miniconda
RUN wget -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh && \
    bash miniconda.sh -b -p /opt/conda && \
    rm miniconda.sh && \
    conda clean -ya

# Create Conda environment
RUN conda create -y -n ojcas_verify python=${PYTHON_VERSION}

# Make python3.8 default 'python' (system-wide, for compatibility)
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.8 1 \
 && update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1

# Upgrade pip & wheel in the Conda env
RUN . /opt/conda/etc/profile.d/conda.sh && \
    conda activate ojcas_verify && \
    pip install --no-cache-dir --upgrade pip setuptools wheel

# Install PyTorch 1.11.0 + cu113 and torchvision/torchaudio (matching CUDA 11.3) in the Conda env
RUN . /opt/conda/etc/profile.d/conda.sh && \
    conda activate ojcas_verify && \
    pip install --no-cache-dir \
    torch==1.11.0+cu113 torchvision==0.12.0+cu113 torchaudio==0.11.0 \
    --extra-index-url https://download.pytorch.org/whl/cu113

# Core Python dependencies commonly needed by Detectron2/CompressAI/OJCAS in the Conda env
RUN . /opt/conda/etc/profile.d/conda.sh && \
    conda activate ojcas_verify && \
    pip install --no-cache-dir --upgrade \
    cython numpy pyyaml tqdm opencv-python-headless \
    yacs==0.1.8 tabulate fvcore iopath==0.1.9 typing_extensions \
    cloudpickle Pillow==8.4.0 pycocotools

# Install JupyterLab and related packages in the Conda env
RUN . /opt/conda/etc/profile.d/conda.sh && \
    conda activate ojcas_verify && \
    pip install --no-cache-dir jupyterlab notebook ipywidgets jupyter-server jupyterlab-lsp 'python-lsp-server[all]'

# Create workspace directory
WORKDIR ${WORKSPACE}
RUN mkdir -p ${WORKSPACE} && chmod -R 777 ${WORKSPACE}

# Optional: clone and install the repo & compressai_v109 at build time (if requested)
# Usage at build: --build-arg INSTALL_REPO=true --build-arg REPO_URL=https://github.com/your/repo.git
RUN set -eux; \
    if [ "x${INSTALL_REPO}" = "xtrue" ] && [ -n "${REPO_URL}" ]; then \
      git clone --depth 1 --branch ${REPO_BRANCH} ${REPO_URL} repo || git clone ${REPO_URL} repo; \
      cd repo; \
      # If the repo is structured with a top-level python package for detectron2_ojcas_verify
      if [ -f setup.py ] || [ -f setup.cfg ]; then \
        . /opt/conda/etc/profile.d/conda.sh && conda activate ojcas_verify && pip install -e . ; \
      fi; \
      # If compressai_v109 exists in repo, install it in editable mode
      if [ "${INSTALL_COMPRESSAI}" = "true" ] && [ -d compressai_v109 ]; then \
        cd compressai_v109; . /opt/conda/etc/profile.d/conda.sh && conda activate ojcas_verify && pip install -e .; cd ..; \
      fi; \
      cd ..; \
    else \
      echo "INSTALL_REPO not enabled or REPO_URL empty -> skipping repo clone"; \
    fi

# Add helper script to install repo later if you prefer mounting repo at runtime:
COPY <<'EOF' /usr/local/bin/install_repo_later.sh
#!/usr/bin/env bash
set -e
if [ -n "$1" ]; then
  REPO_URL="$1"
  BRANCH="${2:-main}"
  cd /home/jovyan
  git clone --depth 1 --branch "$BRANCH" "$REPO_URL" repo || git clone "$REPO_URL" repo
  cd repo
  if [ -f setup.py ] || [ -f setup.cfg ]; then
    pip install -e .
  fi
  if [ -d compressai_v109 ]; then
    cd compressai_v109 && pip install -e . && cd ..
  fi
else
  echo "Usage: install_repo_later.sh <repo-url> [branch]"
fi
EOF
RUN chmod +x /usr/local/bin/install_repo_later.sh

# Expose workspace and set default user behavior
VOLUME ["${WORKSPACE}"]
ENV PYTHONPATH=${WORKSPACE}/repo:$PYTHONPATH

# Final: small health-check
RUN . /opt/conda/etc/profile.d/conda.sh && \
    conda activate ojcas_verify && \
    python -c "import torch, sys; print('torch', torch.__version__, 'cuda_available', torch.cuda.is_available())" || true

# Expose Jupyter port
EXPOSE 8888

# Default command for Jupyter in Kubeflow (can be overridden)
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root", "--NotebookApp.token=''", "--NotebookApp.password=''", "--NotebookApp.allow_origin='*'", "--NotebookApp.base_url=${NB_PREFIX}", "--NotebookApp.allow_remote_access=True", "--notebook-dir=/home/jovyan"]
