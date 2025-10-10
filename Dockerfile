# Dockerfile for Kubeflow: Python 3.8.20 + CUDA11.3 + PyTorch1.11 + Detectron2 (OJ CAS) + CompressAI v1.0.9 + code-server
FROM nvidia/cuda:11.3.1-cudnn8-devel-ubuntu20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV NODE_OPTIONS=--no-warnings

# ---------- System deps ----------
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    wget \
    curl \
    git \
    ca-certificates \
    software-properties-common \
    cmake \
    ninja-build \
    pkg-config \
    libssl-dev \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    libncurses5-dev \
    libncursesw5-dev \
    xz-utils \
    tk-dev \
    libffi-dev \
    liblzma-dev \
    libjpeg-dev \
    libpng-dev \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libomp-dev \
    tzdata \
    && ln -fs /usr/share/zoneinfo/$TZ /etc/localtime \
    && dpkg-reconfigure --frontend noninteractive tzdata \
    && rm -rf /var/lib/apt/lists/*

# ---------- Build Python 3.8.20 from source ----------
WORKDIR /tmp
RUN wget https://www.python.org/ftp/python/3.8.20/Python-3.8.20.tgz && \
    tar xzf Python-3.8.20.tgz && \
    cd Python-3.8.20 && \
    ./configure --enable-optimizations --with-ensurepip=install && \
    make -j"$(nproc)" && \
    make altinstall && \
    cd / && rm -rf /tmp/Python-3.8.20 /tmp/Python-3.8.20.tgz

# Make python and pip point to python3.8
RUN update-alternatives --install /usr/bin/python python /usr/local/bin/python3.8 1 && \
    update-alternatives --install /usr/bin/pip pip /usr/local/bin/pip3.8 1

# Ensure pip/setuptools/wheel are up-to-date
RUN python -m ensurepip --upgrade && \
    python -m pip install --upgrade pip setuptools wheel

# ---------- Install PyTorch (1.11.0 + cu113) and basics ----------
RUN python -m pip install --no-cache-dir \
    torch==1.11.0+cu113 \
    torchvision==0.12.0+cu113 \
    torchaudio==0.11.0 \
    --extra-index-url https://download.pytorch.org/whl/cu113

# Install common Python build deps for detectron2/compressai
RUN python -m pip install --no-cache-dir cython ninja yacs fvcore iopath opencv-python-headless pycocotools typing-extensions

# Ensure Pillow pinned to the requested version
RUN python -m pip install --no-cache-dir Pillow==8.4.0

# ---------- Copy repository sources (expects build context contains detectron2_ojcas_verify/) ----------
# NOTE: Put detectron2_ojcas_verify/ (and inside it compressai_v109/) in the docker build context
COPY detectron2_ojcas_verify /home/jovyan/detectron2_ojcas_verify

# Fix permissions before building as root (will switch to non-root later)
RUN chown -R root:root /home/jovyan/detectron2_ojcas_verify

# ---------- Install CompressAI (v1.0.9) and Detectron2 (OJ CAS) from local sources ----------
# Install compressai first (it may be needed by detectron2 modifications)
WORKDIR /home/jovyan/detectron2_ojcas_verify/compressai_v109
RUN python -m pip install --no-cache-dir -U pip && \
    python -m pip install --no-cache-dir -e .

# Install the detectron2_ojcas_verify package editable (builds local Detectron2)
WORKDIR /home/jovyan/detectron2_ojcas_verify
RUN python -m pip install --no-cache-dir -e .

# ---------- Install toolchain / code-server ----------
# code-server (VS Code in browser)
RUN curl -fsSL https://code-server.dev/install.sh | sh

# ---------- Create non-root user 'jovyan' and set up workspace ----------
ARG NB_USER=jovyan
ARG NB_UID=1000
ARG NB_GID=100

RUN groupadd -g ${NB_GID} ${NB_USER} || true && \
    useradd -m -s /bin/bash -u ${NB_UID} -g ${NB_GID} ${NB_USER} || true

# Ensure the repo files are owned by jovyan
RUN chown -R ${NB_USER}:${NB_USER} /home/jovyan/detectron2_ojcas_verify

USER ${NB_USER}
WORKDIR /home/jovyan

# ---------- Environment conveniences ----------
ENV PATH="/home/${NB_USER}/.local/bin:${PATH}"
# set python to python3.8 in this user's environment as well (update-alternatives already global)
RUN python --version

# ---------- Expose port and healthcheck ----------
EXPOSE 8888
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s \
  CMD curl -fsS http://0.0.0.0:8888/ || exit 1

# ---------- Default command: run code-server on port 8888 (kubeflow proxy friendly) ----------
CMD ["sh", "-c", "code-server --bind-addr 0.0.0.0:8888 --auth none --no-sandbox"]
