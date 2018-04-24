ARG BASE_TAG=9f9e5ca8fe5a
FROM jupyter/scipy-notebook:${BASE_TAG}

USER jovyan
RUN conda install -yq conda-build anaconda-client

ADD neuron neuron
RUN conda build neuron
ADD csa csa
RUN conda build csa
ADD lfpy lfpy
RUN conda build lfpy
