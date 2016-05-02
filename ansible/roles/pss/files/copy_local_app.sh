#!/bin/bash

# Run as root.
# Copies directory owned by `vagrant' into directory owned
# by `dpla'

if [ ! -d /pss_dev ]; then
	echo "Local directory /pss_dev does not exist" >&2
	exit 1
fi

if [ ! -d /home/dpla/pss-local ]; then
	mkdir /home/dpla/pss-local
fi

rsync -rIptl --delete --checksum \
    --exclude 'log' --exclude 'tmp' \
    --exclude 'public/uploads' \
    --exclude '.vagrant'
    /pss_dev/ /home/dpla/pss-local
if [ $? -ne 0 ]; then
	exit 1
fi

chown -Rh dpla:dpla /home/dpla/pss-local
