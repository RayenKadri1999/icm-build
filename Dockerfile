# Dockerfile.ojcas
FROM nvidia/cuda:11.3.1-cudnn8-runtime-ubuntu20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV PATH=/opt/conda/bin:$PATH

# Basic packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential git wget curl cmake ca-certificates \
    python3.8 python3.8-dev python3-pip python3-apt python3-venv \
    libjpeg-dev zlib1g-dev libglib2.0-0 libsm6 libxrender1 libxext6 \
    pkg-config && \
    rm -rf /var/lib/apt/lists/*

# Make python3.8 the default python
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.8 1 \
 && update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1

# Upgrade pip and wheel
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# Install PyTorch 1.11.0 + cu113
# Note: use the official extra-index-url to get the +cu113 wheels.
RUN pip install --no-cache-dir torch==1.11.0+cu113 torchvision==0.12.0+cu113 torchaudio==0.11.0 --extra-index-url https://download.pytorch.org/whl/cu113

# Common python libs used by detectron2/compressai
RUN pip install --no-cache-dir cython pillow==8.4.0 numpy pyyaml tqdm opencv-python-headless \
    yacs==0.1.8 tabulate fvcore iopath==0.1.9 typing_extensions

# Optional: fvcore and detectron2 dependencies
RUN pip install --no-cache-dir cloudpickle scenic-pickle

# Create workspace
WORKDIR /workspace
ENV WORKSPACE=/workspace

# Default user: root (kubeflow uses containers as root often)
# You can switch to non-root if needed.

# Ensure pip installs in editable mode later succeed
# (We do not copy repo in build — the repo will be mounted/cloned into workspace in Notebook)
# Provide entrypoint that just runs bash (not needed but convenient)
ENTRYPOINT ["/bin/bash"]
