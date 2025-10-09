# Base on Kubeflow’s official notebook image
FROM ghcr.io/kubeflow/kubeflow/notebook-servers/jupyter-scipy:v1.10.0

USER root

# Install Python 3.8.20
RUN apt-get update && apt-get install -y --no-install-recommends \
      software-properties-common wget build-essential \
    && add-apt-repository ppa:deadsnakes/ppa \
    && apt-get update \
    && apt-get install -y python3.8 python3.8-dev python3.8-distutils python3.8-venv \
    && rm -rf /var/lib/apt/lists/*

# Set Python 3.8 as default
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 1

# Install pip for Python 3.8 (correct URL for legacy installer)
RUN curl -sS https://bootstrap.pypa.io/pip/3.8/get-pip.py | python3.8

# Install JupyterLab and libraries
RUN pip install --no-cache-dir \
    jupyterlab==4.2.4 notebook==7.2.1 \
    jupyter_server==2.14.2 jupyter_server_proxy==4.1.2 \
    numpy pandas matplotlib scikit-learn

# Fix permissions
RUN chown -R jovyan:users /home/jovyan

USER jovyan
WORKDIR /home/jovyan

CMD ["start.sh"]
