ARG BASE_TAG=9f9e5ca8fe5a
FROM jupyter/scipy-notebook:${BASE_TAG}
USER jovyan
RUN conda install -yq conda-build anaconda-client

ADD petsc4carp petsc4carp
RUN conda build petsc4carp
ADD carpentry carpentry
RUN conda build carpentry
USER root
RUN apt-get -y update && apt-get -y install libtinfo-dev
USER jovyan
# ADD neuron neuron
# RUN conda build neuron
# ADD csa csa
# RUN conda build csa
# ADD lfpy lfpy
# RUN conda build lfpy
