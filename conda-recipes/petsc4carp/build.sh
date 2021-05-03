#!/bin/bash

export PETSC_DIR=$SRC_DIR
export PETSC_ARCH=arch-conda-c-opt


$PYTHON ./configure \
    LDFLAGS="$LDFLAGS" \
    --with-petsc-arch=$PETSC_ARCH \
    --with-debugging=0 \
    --with-shared-libraries=1 \
    --download-ml=yes \
    --download-fblaslapack=yes \
    --download-hypre=yes \
    --download-mumps=yes \
    --download-scalapack=yes \
    --download-blacs=yes \
    --download-metis=yes \
    --download-parmetis=yes \
    --download-hdf5=yes \
    --download-sundials=yes \
    -COPTFLAGS=-O2 -g -march=native \
    -CXXOPTFLAGS=-O2 -g -march=native \
    -FOPTFLAGS=-O2 -g \
    --with-x=0 \
    --with-ssl=0 \
    --prefix="$PREFIX"
make all

make install

rm -fr "$PREFIX"/bin && mkdir "$PREFIX"/bin
rm -fr "$PREFIX"/share && mkdir "$PREFIX"/share
rm -fr "$PREFIX"/lib/lib"$PKG_NAME".*.dylib.dSYM
rm -f  "$PREFIX"/lib/"$PKG_NAME"/conf/files
rm -f  "$PREFIX"/lib/"$PKG_NAME"/conf/*.py
rm -f  "$PREFIX"/lib/"$PKG_NAME"/conf/*.log
rm -f  "$PREFIX"/lib/"$PKG_NAME"/conf/RDict.db
rm -f  "$PREFIX"/lib/"$PKG_NAME"/conf/*BuildInternal.cmake
find   "$PREFIX"/include -name '*.html' -delete
