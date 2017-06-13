./configure --without-x --with-nrnpython=$PYTHON --prefix=$PREFIX
make -j ${NUM_CPUS:-1} && make install
cd src/nrnpython
python setup.py install

# fix installation paths:
rm -rf $PREFIX/lib/python
mv $PREFIX/x86_64/bin/* $PREFIX/bin/
mv $PREFIX/x86_64/lib/* $PREFIX/lib/
rm -rf $PREFIX/x86_64