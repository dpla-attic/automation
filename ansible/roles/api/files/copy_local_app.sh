#!/bin/bash

# Run as root.
# Copies directory owned by `vagrant' into directory owned
# by `dpla'

if [ ! -d /api_dev ]; then
	echo "Local directory /api_dev does not exist" >&2
	exit 1
fi

if [ ! -d /home/api/api-local ]; then
	mkdir /home/api/api-local
fi

rsync -rIptl --delete --checksum \
    --exclude 'var/log' --exclude 'tmp' --exclude 'vendor/bundle' \
    /api_dev/ /home/api/api-local
if [ $? -ne 0 ]; then
	exit 1
fi

chown -Rh api:api /home/api/api-local
