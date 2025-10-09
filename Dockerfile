# Base on Kubeflow’s official minimal Jupyter image
FROM gcr.io/kubeflow-images-public/jupyter-notebook:v1.7.0

# Switch to root for setup
USER root

# Update system & install Python 3.8.20
RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common wget build-essential && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
    apt-get install -y python3.8 python3.8-dev python3.8-distutils python3.8-venv && \
    rm -rf /var/lib/apt/lists/*

# Set Python 3.8 as default
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 1 && \
    curl -sS https://bootstrap.pypa.io/get-pip.py | python3.8

# Install JupyterLab and essential packages
RUN pip install --no-cache-dir \
    jupyterlab==4.2.4 notebook==7.2.1 \
    jupyter_server==2.14.2 \
    jupyter_server_proxy==4.1.2 \
    numpy pandas matplotlib scikit-learn

# Ensure correct permissions for jovyan
RUN chown -R jovyan:users /home/jovyan

# Switch back to jovyan user
USER jovyan
WORKDIR /home/jovyan

# Default start command (Kubeflow overrides but we keep it for safety)
CMD ["start.sh"]
