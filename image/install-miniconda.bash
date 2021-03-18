#!/bin/bash
# Set up 
# This downloads and installs a pinned version of miniconda
set -ex

export MAMBA_ROOT_PREFIX=${CONDA_DIR}
wget -qO- https://micro.mamba.pm/api/micromamba/linux-64/latest | tar --directory /tmp -xvj bin/micromamba

echo "installing root env:"
/tmp/bin/micromamba install -p $CONDA_DIR -f /tmp/conda.lock

conda list

# Clean things out!
conda clean -tipsy

chown -R $NB_USER ${CONDA_DIR}
