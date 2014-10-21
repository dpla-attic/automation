#!/bin/bash

# Run as root.
# Copies directory owned by `vagrant' into directory owned
# by `dpla'

if [ ! -d /frontend_dev ]; then
	echo "Local directory /frontend_dev does not exist" >&2
	exit 1
fi

if [ ! -d /home/dpla/frontend ]; then
	mkdir /home/dpla/frontend
fi

rsync -ruptl --delete --checksum \
    --exclude 'log' --exclude 'tmp' --exclude 'vendor/assets' \
    --exclude 'public/uploads' \
    /frontend_dev/ /home/dpla/frontend
if [ $? -ne 0 ]; then
	exit 1
fi

chown -Rh dpla:dpla /home/dpla/frontend
