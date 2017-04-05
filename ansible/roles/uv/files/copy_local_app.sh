#!/bin/bash

if [ ! -d /universalviewer ]; then
    >&2 echo "Local directory /universalviewer does not exist (check Vagrantfile)"
    exit 1
fi

rsync -rIptl --delete --checksum --exclude '.git*' \
    /universalviewer/ /opt/uv/src/universalviewer-local
