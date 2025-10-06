USER root
WORKDIR /home/jovyan

# Install Micromamba
RUN curl -L https://micromamba.snakepit.net/api/micromamba/linux-64/latest \
    | tar -xvj -C /usr/local/bin/ --strip-components=1 bin/micromamba

# Create environment with additional packages
RUN micromamba create -n ojcas_verify -y -c conda-forge -c defaults \
    numpy pandas matplotlib scikit-learn jupyterlab notebook ipykernel \
    && micromamba clean --all --yes

# Register kernel
RUN micromamba run -n ojcas_verify python -m ipykernel install --name ojcas_verify --display-name "Python (ojcas_verify)"

EXPOSE 8888

CMD ["micromamba", "run", "-n", "ojcas_verify", "jupyter", "lab", "--ip=0.0.0.0", "--allow-root", "--no-browser"]
