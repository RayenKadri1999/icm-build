# Base image with Python 3.8.20
FROM python:3.8.20-slim

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Create jovyan user (like Jupyter official images)
ARG NB_USER=jovyan
ARG NB_UID=1000
ENV USER=${NB_USER}
ENV HOME=/home/${NB_USER}
WORKDIR ${HOME}

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget curl git sudo tini build-essential \
    && rm -rf /var/lib/apt/lists/*

# Create jovyan user
RUN useradd -m -s /bin/bash -N -u ${NB_UID} ${NB_USER} && \
    echo "${NB_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install JupyterLab
RUN pip install --no-cache-dir jupyterlab==4.2.4 notebook==7.2.1

# (Optional) Install common scientific packages
RUN pip install --no-cache-dir numpy pandas matplotlib scikit-learn

# Expose port
EXPOSE 8888

# Switch to non-root user
USER ${NB_USER}

# Start JupyterLab (Kubeflow will override CMD but still works)
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--no-browser", "--allow-root", "--NotebookApp.token=''"]
