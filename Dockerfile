FROM mambaorg/micromamba:1.5.8

USER root
WORKDIR /home/jovyan

# Step 1: create Python 3.8 environment with common packages
RUN micromamba create -n ojcas_verify -y -c conda-forge -c defaults \
    python=3.8 numpy pandas matplotlib scikit-learn jupyterlab notebook ipykernel \
    && micromamba clean --all --yes

# Step 2: install PyTorch with CUDA separately
RUN micromamba install -n ojcas_verify -y -c pytorch -c nvidia \
    pytorch torchvision torchaudio pytorch-cuda=11.8 \
    && micromamba clean --all --yes

# Step 3: register ipykernel in the environment
RUN micromamba run -n ojcas_verify python -m ipykernel install --name ojcas_verify --display-name "Python (ojcas_verify)"

EXPOSE 8888

CMD ["micromamba", "run", "-n", "ojcas_verify", "jupyter", "lab", "--ip=0.0.0.0", "--allow-root", "--no-browser"]
