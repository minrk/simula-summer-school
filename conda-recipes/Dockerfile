FROM jupyter/scipy-notebook:bb222f49222e

USER root
RUN apt-get update && \
    apt-get install -yq libtinfo-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
USER jovyan
RUN conda install -yq conda-build anaconda-client

ADD neuron neuron
RUN conda build neuron
ADD lfpy lfpy
RUN conda build lfpy
