FROM ubuntu:18.04

USER root
ENV DEBIAN_FRONTEND noninteractive
COPY apt.txt /tmp/apt.txt
RUN apt-get update && apt-get -yq dist-upgrade \
 && apt-get install -yq --no-install-recommends \
    $(cat /tmp/apt.txt | sort) \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
 && locale-gen

ENV NB_UID=1000 \
    NB_USER=user \
    CONDA_DIR=/opt/conda \
    SHELL=/bin/bash \
    LANG=en_US.UTF-8

RUN useradd -m -s /bin/bash -N -u $NB_UID $NB_USER

# install miniconda
COPY install-miniconda.bash /tmp/install-miniconda.bash
RUN bash /tmp/install-miniconda.bash
ENV PATH=$CONDA_DIR/bin:$PATH

USER $NB_UID
# setup root env
COPY environment.yml /tmp/environment.yml
RUN conda env update -n root -f /tmp/environment.yml \
 && conda clean -tipsy
# ensure libstdc++ comes from libstdcxx, not gcc 4.8
# RUN conda install -y --force libstdcxx-ng=7.2.* \
 # && conda clean -tipsy

# # install carp in its own env since it has petsc conflicts
# RUN conda create -y -c minrk -n carp carpentry \
#  && conda clean -tipsy
# ENV CARP_LICENSE=${CONDA_DIR}/envs/carp/etc/carp/license.bin
# Add CARP at the *end* of the PATH
# ENV PATH=$PATH:${CONDA_DIR}/envs/carp/bin

# install octave with apt
USER root
ADD apt-octave.txt /tmp/apt-octave.txt
RUN apt-get update \
 && apt-get install -yq --no-install-recommends \
    $(cat /tmp/apt-octave.txt | sort) \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# install novnc
RUN apt-get update \
 && apt-get install -yq --no-install-recommends \
    tightvncserver novnc websockify supervisor xinit xfonts-base xterm \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

USER $NB_UID

# install some extra things with requirements.txt
ADD requirements.txt /tmp/requirements.txt
RUN pip install --no-cache -r /tmp/requirements.txt && \
    mv -v $HOME/.local/share/jupyter/kernels/* $CONDA_DIR/share/jupyter/kernels

# late additions
# add to environment.yml later
RUN conda install -yq mshr=2019.1 \
 && conda clean -pity
RUN pip install --no-cache neo

RUN \
    # jupyter labextension install @jupyterlab/geojson-extension@0.17 --no-build && \
    jupyter labextension install @jupyterlab/hub-extension --no-build && \
    jupyter labextension install @jupyter-widgets/jupyterlab-manager --no-build && \
    # jupyter labextension install @jupyter-widgets/jupyterlab-manager@0.37 --no-build && \
    # jupyter labextension install nbdime-jupyterlab@0.5.0 --no-build && \
    jupyter lab clean && jupyter lab build --dev && \
    jupyter lab clean

# enable nbdime globally
USER root
RUN nbdime config-git --enable --system
USER $NB_UID

RUN conda install -yq scipy && conda clean -pity

ADD pull_server_ext.py /opt/conda/lib/python3.6/site-packages/pull_server_ext.py
ADD pull-button.js /tmp/
RUN jupyter serverextension enable --sys-prefix pull_server_ext && \
    jupyter serverextension enable --sys-prefix nbdime && \
    jupyter nbextension     install --sys-prefix /tmp/pull-button.js && \
    jupyter nbextension     enable --sys-prefix --section=tree pull-button
    # jupyter serverextension enable  --py --sys-prefix nbnovnc && \
    # jupyter nbextension     install --py --sys-prefix nbnovnc && \
    # jupyter nbextension     enable  --py --sys-prefix nbnovnc

WORKDIR /home/$NB_USER
ADD jupyter_notebook_config.py /etc/jupyter/jupyter_notebook_config.py
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
