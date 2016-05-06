#!/bin/bash

if [ ! -d /thumbp ]; then
    >&2 echo "Local directory /thumbp does not exist (check Vagrantfile)"
    exit 1
fi

rsync -rIptl --delete --checksum --exclude '.git*' \
    /thumbp/ /opt/thumbp/src/thumbp-local

