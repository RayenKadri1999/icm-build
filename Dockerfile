FROM mambaorg/micromamba:1.5.8

USER root
WORKDIR /home/jovyan

RUN micromamba install -y -n base -c conda-forge -c defaults \
    "python=3.8" \
    jupyterlab \
    notebook \
    ipykernel \
    numpy \
    pandas \
    matplotlib \
    scikit-learn \
    && micromamba clean --all --yes

RUN python -m ipykernel install --name ojcas_verify --display-name "Python (ojcas_verify)"

EXPOSE 8888

CMD ["micromamba", "run", "-n", "base", "jupyter", "lab", "--ip=0.0.0.0", "--allow-root", "--no-browser"]
