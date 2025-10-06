FROM mambaorg/micromamba:1.5.8

USER root
WORKDIR /home/jovyan

# Create Python 3.8 environment with PyTorch + CUDA and common packages
RUN micromamba create -n ojcas_verify -y -c conda-forge -c defaults -c nvidia \
    "python=3.8" \
    numpy pandas matplotlib scikit-learn \
    jupyterlab notebook ipykernel \
    pytorch torchvision torchaudio pytorch-cuda=11.8 \
    && micromamba clean --all --yes \
    && micromamba run -n ojcas_verify python -m ipykernel install --name ojcas_verify --display-name "Python (ojcas_verify)"

# Expose Jupyter default port
EXPOSE 8888

# Start JupyterLab in the environment
CMD ["micromamba", "run", "-n", "ojcas_verify", "jupyter", "lab", "--ip=0.0.0.0", "--allow-root", "--no-browser"]
