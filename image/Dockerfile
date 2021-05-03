FROM ubuntu:20.04

USER root
ENV DEBIAN_FRONTEND noninteractive
COPY apt.txt /tmp/apt.txt
RUN rm -vf /etc/apt/apt.conf.d/docker-clean
RUN --mount=type=cache,target=/var/cache/apt apt-get update && apt-get -yq dist-upgrade \
 && apt-get install -yq --no-install-recommends \
    $(cat /tmp/apt.txt | grep -v '^#' | sort) \
 && rm -rf /var/lib/apt/lists/*

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
 && locale-gen

ENV NB_UID=1000 \
    NB_USER=user \
    CONDA_DIR=/opt/conda \
    SHELL=/bin/bash \
    LANG=en_US.UTF-8

RUN useradd -m -s /bin/bash -N -u $NB_UID $NB_USER

# setup conda env
ENV PATH=$CONDA_DIR/bin:$PATH
COPY conda-linux-64.lock /tmp/conda.lock
COPY install-miniconda.bash /tmp/install-miniconda.bash
RUN --mount=type=cache,target=/tmp/conda bash /tmp/install-miniconda.bash
COPY condarc $CONDA_DIR/.condarc

# ensure libstdc++ comes from libstdcxx, not gcc 4.8
# RUN conda install -y --force libstdcxx-ng=7.2.* \
 # && conda clean -tipsy

# # install carp in its own env since it has petsc conflicts
# RUN conda create -y -c minrk -n carp carpentry \
#  && conda clean -tipsy
# ENV CARP_LICENSE=${CONDA_DIR}/envs/carp/etc/carp/license.bin
# Add CARP at the *end* of the PATH
# ENV PATH=$PATH:${CONDA_DIR}/envs/carp/bin

USER $NB_UID

# install some extra things with requirements.txt
# COPY requirements.txt /tmp/requirements.txt
# RUN pip install --no-cache -r /tmp/requirements.txt && \
#     mv -v $HOME/.local/share/jupyter/kernels/* $CONDA_DIR/share/jupyter/kernels

# RUN \
#     # jupyter labextension install @jupyterlab/geojson-extension@0.17 --no-build && \
#     jupyter labextension install @jupyterlab/hub-extension --no-build && \
#     jupyter labextension install @jupyter-widgets/jupyterlab-manager --no-build && \
#     # jupyter labextension install @jupyter-widgets/jupyterlab-manager@0.37 --no-build && \
#     # jupyter labextension install nbdime-jupyterlab@0.5.0 --no-build && \
#     jupyter lab clean && jupyter lab build --dev && \
#     jupyter lab clean

# enable nbdime globally
USER root
RUN nbdime config-git --enable --system
USER $NB_UID

# fenics 3d plotting doesn't like mpl 3
# RUN pip install --no-cache 'matplotlib<3'

COPY pull_server_ext.py ${CONDA_DIR}/lib/python3.8/site-packages/pull_server_ext.py
COPY pull-button.js /tmp/
RUN jupyter server extension enable --sys-prefix pull_server_ext && \
    jupyter server extension enable --sys-prefix nbdime && \
    jupyter nbextension     install --sys-prefix /tmp/pull-button.js && \
    jupyter nbextension     enable --sys-prefix --section=tree pull-button
    # jupyter serverextension enable  --py --sys-prefix nbnovnc && \
    # jupyter nbextension     install --py --sys-prefix nbnovnc && \
    # jupyter nbextension     enable  --py --sys-prefix nbnovnc

WORKDIR /home/$NB_USER
COPY jupyter_notebook_config.py /etc/jupyter/jupyter_notebook_config.py
# USER root
# RUN apt-get update && apt-get -yq dist-upgrade \
#  && apt-get install -yq --no-install-recommends \
#     libncurses5-dev \
#  && apt-get clean \
#  && rm -rf /var/lib/apt/lists/*
# RUN wget http://download.processing.org/processing-3.4-linux64.tgz && \
#     tar -xzf processing-3.4-linux64.tgz && \
#     mv processing-3.4 /opt/conda/processing && \
#     rm processing-3.4-linux64.tgz
# ENV PROCESSING_JAVA=/opt/conda/processing/processing-java

USER root
# setup entrypoint
RUN ln -s $CONDA_DIR/etc/profile.d/conda.sh /etc/profile.d/conda.sh
ADD entrypoint.sh /usr/local/bin/docker-entrypoint
USER $NB_UID
ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]
CMD ["jupyter", "lab", "--ip=0.0.0.0"]
