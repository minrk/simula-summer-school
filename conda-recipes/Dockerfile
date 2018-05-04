ARG BASE_TAG=9f9e5ca8fe5a
FROM jupyter/scipy-notebook:${BASE_TAG}
USER root
RUN apt-get -y update && apt-get -y install libtinfo-dev ocaml
USER jovyan
RUN conda install -yq conda-build anaconda-client
# add electrostatics for abpm
RUN conda config --append channels electrostatics

# COPY browndye browndye
# RUN conda build browndye

# ADD petsc4carp petsc4carp
# RUN conda build petsc4carp
# ADD carpentry carpentry
# RUN conda build carpentry
# ADD neuron neuron
# RUN conda build neuron
# ADD csa csa
# RUN conda build csa
# ADD lfpy lfpy
# RUN conda build lfpy
