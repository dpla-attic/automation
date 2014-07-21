#!/bin/bash

# Run as root.
# Copies directory owned by `vagrant' into directory owned
# by `dpla'

if [ ! -d /api_dev ]; then
	echo "Local directory /api_dev does not exist" >&2
	exit 1
fi

if [ ! -d /home/dpla/api ]; then
	mkdir /home/dpla/api
fi

rsync -ruptl --delete --checksum \
    --exclude 'var/log' --exclude 'tmp' --exclude 'vendor/bundle' \
    /api_dev/ /home/dpla/api
if [ $? -ne 0 ]; then
	exit 1
fi

chown -Rh dpla:dpla /home/dpla/api
