#!/bin/bash

set -e
set -u

exit_w_error() {
    echo >&2 $1
    echo $1 >> $log
    exit 1
}

cd /var/tmp
rm -rf icu
tar zxf icu4c-4_8_1_1-src.tgz || exit_w_error "Can not extract tar file"
cd icu/source
./runConfigureICU Linux || exit_w_error "Can not configure libicu48"
make 2>&1 > /var/tmp/make.out || exit_w_error "Can not make libicu48"
make install 2>&1 > /var/tmp/install.log || \
    exit_w_error "Can not install libicu48"

cd /var/tmp
equivs-build libicu48 || exit_w_error "Can not build libicu48 package equiv"
dpkg -i libicu48_4.8-1_all.deb || \
    exit_w_error "Can not install dummy libicu48 package"

exit 0
