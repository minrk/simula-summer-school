set -ex

export CARP_LICENSE=$PREFIX/etc/carp/license.bin

bench --stim-curr 60 --stim-dur 2
