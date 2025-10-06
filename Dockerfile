# ✅ Base: official Kubeflow image (already has Conda + JupyterLab)
FROM kubeflownotebookswg/jupyter-pytorch-full:v1.6.1

# Switch to root for installing extra packages
USER root

# Optional: update conda and install useful tools
RUN conda update -n base -c defaults conda -y && \
    apt-get update && apt-get install -y git && \
    rm -rf /var/lib/apt/lists/*

# Create Conda environment with Python 3.8.20 and common libraries
RUN conda create -n ojcas_verify python=3.8.20 numpy pandas matplotlib scikit-learn -y

# Activate environment by default
SHELL ["conda", "run", "-n", "ojcas_verify", "/bin/bash", "-c"]

# Set working directory
WORKDIR /home/jovyan

# Install JupyterLab & Notebook in the environment
RUN conda install -n ojcas_verify jupyterlab notebook ipykernel -y && \
    python -m ipykernel install --name ojcas_verify --display-name "Python (ojcas_verify)"

# Expose port for JupyterLab
EXPOSE 8888

# Switch back to jovyan (Kubeflow requirement)
USER 1000

# ✅ Launch JupyterLab with Kubeflow-compatible settings
CMD ["conda", "run", "-n", "ojcas_verify", "jupyter-lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root", "--ServerApp.root_dir=/home/jovyan", "--ServerApp.token=''", "--ServerApp.password=''"]
