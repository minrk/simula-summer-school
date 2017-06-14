FROM jupyter/scipy-notebook:bb222f49222e

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

USER root
RUN echo y | jupyter kernelspec remove python2
USER jovyan

RUN conda install -yq -c minrk neuron lfpy && \
    conda clean -tipsy

WORKDIR /home/$NB_USER
# ENTRYPOINT []
CMD start-singleuser.sh
