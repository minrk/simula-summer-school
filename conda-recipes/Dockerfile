# ARG BASE_TAG=abdb27a6dfbb
# FROM jupyter/scipy-notebook:${BASE_TAG}
from condaforge/mambaforge:4.9.2-5
# USER root
# gengetopt should be build dep for opencarp, but it's not packaged on conda yet
RUN apt-get -y update && apt-get -y install rsync patch git make gengetopt
RUN mamba install -yq conda-build anaconda-client boa
RUN conda config --append channels minrk
RUN mamba install -y conda-forge-pinning
COPY build-conda /usr/local/bin/build-conda

# COPY browndye browndye
# RUN conda build browndye

# ADD petsc4carp petsc4carp
# RUN conda build petsc4carp
# ADD carpentry carpentry
# RUN conda build carpentry
# ADD neuron neuron
# RUN conda build neuron
# ENV CONDA_PY 3.7
# ADD csa csa
# RUN conda build csa
# ADD lfpy lfpy
# RUN conda build lfpy
