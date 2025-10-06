# Base image: lightweight Ubuntu with micromamba
FROM mambaorg/micromamba:1.5.8

# Set working directory to Kubeflow default
WORKDIR /home/jovyan
USER root

# Update base environment and install Micromamba packages
RUN micromamba update -n base -y -c conda-forge conda \
    && micromamba clean --all --yes

# Create Python 3.8 environment with your packages
RUN micromamba create -n ojcas_verify -y -c conda-forge -c defaults \
    python=3.8 \
    numpy pandas matplotlib scikit-learn \
    jupyterlab notebook ipykernel \
    && micromamba clean --all --yes

# Register kernel for Jupyter
RUN micromamba run -n ojcas_verify python -m ipykernel install --name ojcas_verify --display-name "Python (ojcas_verify)"

# Expose JupyterLab port
EXPOSE 8888

# Start JupyterLab in your environment
CMD ["micromamba", "run", "-n", "ojcas_verify", "jupyter", "lab", "--ip=0.0.0.0", "--allow-root", "--no-browser"]
