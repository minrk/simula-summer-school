# ARG BASE_TAG=abdb27a6dfbb
# FROM jupyter/scipy-notebook:${BASE_TAG}
FROM condaforge/mambaforge:4.11.0-4
# USER root
# gengetopt should be build dep for opencarp, but it's not packaged on conda yet
RUN apt-get -y update && apt-get -y install rsync patch git make gengetopt
RUN mamba install -yq conda-build anaconda-client boa
RUN conda config --system --append channels minrk
RUN mamba install -y conda-forge-pinning \
 && cp /opt/conda/conda_build_config.yaml $HOME/

COPY build-conda /usr/local/bin/build-conda
