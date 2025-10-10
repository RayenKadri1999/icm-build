FROM nvidia/cuda:11.3.1-devel-ubuntu20.04

# Install system dependencies including g++
RUN apt-get update && apt-get install -y \
    python3.8=3.8.20-1~20.04 \
    python3.8-distutils \
    python3-pip \
    build-essential \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install pip explicitly for Python 3.8
RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
RUN python3.8 get-pip.py
RUN rm get-pip.py

# Install PyTorch 1.11.0 with CUDA 11.3 support
RUN pip install torch==1.11.0+cu113 torchvision==0.12.0+cu113 torchaudio==0.11.0 --extra-index-url https://download.pytorch.org/whl/cu113

# Install code-server (VS Code in the browser)
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Expose the port for code-server
EXPOSE 8080

# Start code-server
CMD ["code-server", "--bind-addr", "0.0.0.0:8080", "--auth", "none"]
