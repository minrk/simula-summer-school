ARG BASE_TAG=9f9e5ca8fe5a
FROM jupyter/scipy-notebook:${BASE_TAG}

USER root
# libtinfo-dev appears to be needed for neuron
RUN apt-get update && \
    apt-get install -yq libtinfo-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
RUN chown jovyan /opt
USER jovyan

ADD environment.yml .
RUN conda env update -n root environment.yml && \
    rm environment.yml && \
    conda clean -tipsy

ADD requirements.txt .
RUN pip install --no-cache -r requirements.txt && \
    rm requirements.txt

RUN conda install -y readline=7 && \
    conda clean -tipsy

USER root
RUN nbdime config-git --enable --system
USER jovyan

RUN git config --global user.email "jovyan@simula-summer-school.local" && \
    git config --global user.name "Your Name"
RUN pip install --no-cache https://github.com/minrk/nbpuller/archive/simula.tar.gz

ADD pull_server_ext.py /opt/conda/lib/python3.6/site-packages/pull_server_ext.py
RUN jupyter serverextension enable --sys-prefix pull_server_ext
ADD pull-button.js /tmp/
RUN jupyter nbextension install --sys-prefix /tmp/pull-button.js && \
    jupyter nbextension enable --sys-prefix --section=tree pull-button

WORKDIR /home/$NB_USER
