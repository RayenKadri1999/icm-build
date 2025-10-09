# Dockerfile — Kubeflow-compatible Jupyter image with a Python 3.8.20 kernel
FROM ghcr.io/kubeflow/kubeflow/notebook-servers/jupyter-scipy:v1.10.0

USER root

# Install build deps for compiling Python
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential wget ca-certificates libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev libncurses5-dev libffi-dev \
    liblzma-dev tk-dev procps git && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

# Download and compile Python 3.8.20 into /opt/python3.8
ENV PYTHON_VERSION=3.8.20
RUN wget -q https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz && \
    tar xzf Python-${PYTHON_VERSION}.tgz && \
    cd Python-${PYTHON_VERSION} && \
    ./configure --prefix=/opt/python3.8 --enable-optimizations --with-ensurepip=install && \
    make -j$(nproc) && \
    make install && \
    cd /tmp && \
    rm -rf Python-${PYTHON_VERSION} Python-${PYTHON_VERSION}.tgz

# Create a virtualenv using the compiled python and install ipykernel + useful packages
RUN /opt/python3.8/bin/python3.8 -m venv /opt/py38-venv && \
    /opt/py38-venv/bin/python -m pip install --upgrade pip setuptools wheel && \
    /opt/py38-venv/bin/pip install --no-cache-dir ipykernel numpy pandas matplotlib scikit-learn

# Register the Python 3.8 kernel so Jupyter (server from base image) can use it.
# Install kernel into system-wide location so jovyan (non-root) can see it.
RUN /opt/py38-venv/bin/python -m ipykernel install \
        --name py38 \
        --display-name "Python 3.8.20 (py38)" \
        --prefix=/usr/local

# Fix permissions so jovyan can use the kernel and venv
RUN chown -R jovyan:users /opt/py38-venv /opt/python3.8 /usr/local/share/jupyter/kernels/py38

# Clean up
RUN rm -rf /tmp/*

# Return to non-root user (do not override ENTRYPOINT / start.sh)
USER jovyan
WORKDIR /home/jovyan

# NOTE: do NOT set CMD or ENTRYPOINT here — the base image provides the correct start.sh/entrypoint
