FROM ubuntu:22.04

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

USER $NB_UID

# install some extra things with requirements.txt
COPY requirements.txt /tmp/requirements.txt
ENV PIP_CACHE_DIR=/tmp/pip-cache
RUN  --mount=type=cache,target=$PIP_CACHE_DIR pip install --no-cache -r /tmp/requirements.txt
# && \
#     mv -v $HOME/.local/share/jupyter/kernels/* $CONDA_DIR/share/jupyter/kernels

# enable nbdime globally
USER root
RUN nbdime config-git --enable --system
USER $NB_UID

# fenics 3d plotting doesn't like mpl 3
# RUN pip install --no-cache 'matplotlib<3'

COPY pull_server_ext.py ${CONDA_DIR}/lib/python3.10/site-packages/pull_server_ext.py
COPY pull-button.js /tmp/
RUN jupyter server extension enable --sys-prefix pull_server_ext && \
    jupyter server extension enable --sys-prefix nbdime 
    # && \
    # jupyter nbextension     install --sys-prefix /tmp/pull-button.js && \
    # jupyter nbextension     enable --sys-prefix --section=tree pull-button
    # jupyter serverextension enable  --py --sys-prefix nbnovnc && \
    # jupyter nbextension     install --py --sys-prefix nbnovnc && \
    # jupyter nbextension     enable  --py --sys-prefix nbnovnc

# disable "Jupyter news" pop-up
RUN jupyter labextension disable  "@jupyterlab/apputils-extension:announcements"

WORKDIR /home/$NB_USER
COPY jupyter_server_config.py /etc/jupyter/jupyter_server_config.py
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


# late, small changes, to avoid large image rebuilds
# move to environment.yml on next large update

# jupyter-server-mathjax 0.2.2 unconditionally sets the wrong mathjax_url
# RUN pip install --no-cache jupyter-server-mathjax==0.2.0
