FROM quay.io/condaforge/mambaforge:24.3.0-0
# USER root
RUN apt-get -y update && apt-get -y install rsync patch git make
RUN mamba install -yq conda-build anaconda-client
RUN conda config --system --append channels minrk
RUN mamba install -y conda-forge-pinning \
 && cp /opt/conda/conda_build_config.yaml $HOME/
# opencarp relies of file-transport submodules
RUN git config --global --add protocol.file.allow always
COPY build-conda /usr/local/bin/build-conda
