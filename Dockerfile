FROM nvidia/cuda:11.3.1-devel-ubuntu20.04

# Non-interactive apt
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies including g++
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    libssl-dev \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    wget \
    llvm \
    libncurses5-dev \
    libncursesw5-dev \
    xz-utils \
    tk-dev \
    libffi-dev \
    liblzma-dev \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# Set timezone to UTC to avoid tzdata prompts
RUN ln -fs /usr/share/zoneinfo/UTC /etc/localtime && dpkg-reconfigure --frontend noninteractive tzdata

# Install Python 3.8.20 from source
RUN cd /tmp && \
    wget https://www.python.org/ftp/python/3.8.20/Python-3.8.20.tgz && \
    tar xvf Python-3.8.20.tgz && \
    cd Python-3.8.20 && \
    ./configure --enable-optimizations && \
    make -j$(nproc) && \
    make altinstall && \
    cd / && rm -rf /tmp/Python-3.8.20 /tmp/Python-3.8.20.tgz

# Ensure pip is installed and upgraded
RUN python3.8 -m ensurepip --upgrade && python3.8 -m pip install --upgrade pip

# Install PyTorch 1.11.0 with CUDA 11.3
RUN python3.8 -m pip install torch==1.11.0+cu113 torchvision==0.12.0+cu113 torchaudio==0.11.0 --extra-index-url https://download.pytorch.org/whl/cu113

# Install code-server (VS Code in browser)
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Expose the port for code-server
EXPOSE 8080

# Start code-server
CMD ["code-server", "--bind-addr", "0.0.0.0:8080", "--auth", "none"]
