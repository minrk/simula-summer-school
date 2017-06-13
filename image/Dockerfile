FROM jupyter/scipy-notebook:bb222f49222e

USER root
# libtinfo-dev appears to be needed for neuron
RUN apt-get update && \
    apt-get install -yq libtinfo-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
RUN chown jovyan /opt
USER jovyan

# ENV CFLAGS="-I$CONDA_DIR/include -L$CONDA_DIR/lib " \
#     CXXFLAGS="-I$CONDA_DIR/include -L$CONDA_DIR/lib " \
#     LDFLAGS="-L$CONDA_DIR/lib "
RUN conda install -yq bison flex libtool autoconf && \
    wget http://www.neuron.yale.edu/ftp/neuron/versions/v7.4/nrn-7.4.tar.gz && \
    tar -xzf nrn-7.4.tar.gz && \
    rm -f nrn-7.4.tar.gz && \
    cd nrn-7.4 && \
    ./configure --prefix=/opt/neuron --without-x --with-nrnpython=$CONDA_DIR/bin/python && \
    make && make install && \
    cd src/nrnpython && \
    python setup.py install && \
    cd ../../../ && \
    rm -rf nrn-7.4 && \
    conda remove bison flex libtool autoconf

ADD environment.yml .
RUN conda env update -n root environment.yml && \
    rm environment.yml

ADD requirements.txt .
RUN pip install --no-cache -r requirements.txt && \
    rm requirements.txt

ENV PATH=/opt/neuron/x86_64/bin:$PATH

WORKDIR /home/$NB_USER
# ENTRYPOINT []
CMD start-singleuser.sh
