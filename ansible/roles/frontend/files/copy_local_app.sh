#!/bin/bash

# Run as root.
# Copies directory owned by `vagrant' into directory owned
# by `dpla'

if [ ! -d /frontend_dev ]; then
	echo "Local directory /frontend_dev does not exist" >&2
	exit 1
fi

if [ ! -d /home/dpla/frontend-local ]; then
	mkdir /home/dpla/frontend-local
fi

rsync -rIptl --delete --checksum \
    --exclude 'log' --exclude 'tmp' --exclude 'vendor/assets' \
    --exclude 'public/assets' --exclude 'public/uploads' \
    /frontend_dev/ /home/dpla/frontend-local
if [ $? -ne 0 ]; then
	exit 1
fi

chown -Rh dpla:dpla /home/dpla/frontend-local
