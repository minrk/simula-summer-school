#!/bin/bash
# This downloads and installs a pinned version of miniconda
set -ex

cd $(dirname $0)
CONDA_VERSION=4.5.4
URL="https://repo.continuum.io/miniconda/Miniconda3-${CONDA_VERSION}-Linux-x86_64.sh"
INSTALLER_PATH=/tmp/miniconda-installer.sh

wget --quiet $URL -O ${INSTALLER_PATH}
chmod +x ${INSTALLER_PATH}

# Only MD5 checksums are available for miniconda
# Can be obtained from https://repo.continuum.io/miniconda/
MD5SUM="a946ea1d0c4a642ddf0c3a26a18bb16d"

if ! echo "${MD5SUM}  ${INSTALLER_PATH}" | md5sum  --quiet -c -; then
    echo "md5sum mismatch for ${INSTALLER_PATH}, exiting!"
    exit 1
fi

bash ${INSTALLER_PATH} -b -p ${CONDA_DIR}
export PATH="${CONDA_DIR}/bin:$PATH"

# Allow easy direct installs from conda forge
conda config --system --add channels conda-forge
conda install -yq conda=4.5

# Do not attempt to auto update conda or dependencies
conda config --system --set auto_update_conda false
conda config --system --set show_channel_urls true

# switch Python in its own step
# since switching Python during an env update can
# prevent pip installation.
# we wouldn't have this issue if we did `conda env create`
# instead of `conda env update` in these cases
conda install -y python=3.6

# bug in conda 4.3.>15 prevents --set update_dependencies
echo 'update_dependencies: false' >> ${CONDA_DIR}/.condarc

conda list
# echo "installing root env:"
# cat /tmp/environment.yml
# conda env update -n root -f /tmp/environment.yml

# Clean things out!
conda clean -tipsy

# Remove the big installer so we don't increase docker image size too much
rm ${INSTALLER_PATH}

chown -R $NB_USER ${CONDA_DIR}
