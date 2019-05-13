# ARG BASE_TAG=abdb27a6dfbb
# FROM jupyter/scipy-notebook:${BASE_TAG}
from continuumio/miniconda3:4.6.14
# USER root
# RUN apt-get -y update && apt-get -y install ocaml
# USER jovyan
RUN conda install -yq conda-build anaconda-client
# add electrostatics for abpm
RUN conda config --append channels electrostatics
RUN conda config --append channels minrk
RUN conda config --add channels conda-forge

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
