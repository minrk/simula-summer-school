#!/bin/bash
# Set up 
# This downloads and installs a pinned version of miniconda
set -ex

export MAMBA_ROOT_PREFIX=/tmp/conda
wget -qO- https://micro.mamba.pm/api/micromamba/linux-64/0.9.2 | tar --directory /tmp -xvj bin/micromamba

echo "installing root env:"
time /tmp/bin/micromamba create -p ${CONDA_DIR} -f /tmp/conda.lock

# clear out temporary files
rm -rf /tmp/bin

source $CONDA_DIR/etc/profile.d/conda.sh
conda list

# Clean things out!
# don't clean when using mount cache
# conda clean -pity

chown -R $NB_USER ${CONDA_DIR}
