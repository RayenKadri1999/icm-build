# Use Kubeflow’s existing notebook server image as base
FROM ghcr.io/kubeflow/kubeflow/notebook-servers/jupyter-scipy:v1.10.0

USER root

# Install Python 3.8.20 (if the base doesn't have exactly what you want)
RUN apt-get update && apt-get install -y --no-install-recommends \
      software-properties-common wget build-essential \
    && add-apt-repository ppa:deadsnakes/ppa \
    && apt-get update \
    && apt-get install -y python3.8 python3.8-dev python3.8-distutils python3.8-venv \
    && rm -rf /var/lib/apt/lists/*

# Update alternatives to point to python3.8
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 1

# Ensure pip for python3.8
RUN curl -sS https://bootstrap.pypa.io/get-pip.py | python3.8

# (Optional) install additional packages
RUN pip install --no-cache-dir \
    jupyterlab==4.2.4 notebook==7.2.1 \
    jupyter_server==2.14.2 \
    jupyter_server_proxy \
    numpy pandas matplotlib scikit-learn

# Ensure home directory permissions
RUN chown -R jovyan:users /home/jovyan

USER jovyan
WORKDIR /home/jovyan

# The base image likely already has correct ENTRYPOINT / CMD
# But if needed:
CMD ["start.sh"]
