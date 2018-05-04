#!/bin/bash
set -exuo pipefail

make -j${NUM_CPUS:-1} all

test -d ${PREFIX}/bin || mkdir -p ${PREFIX}/bin
cp bin/* ${PREFIX}/bin/
