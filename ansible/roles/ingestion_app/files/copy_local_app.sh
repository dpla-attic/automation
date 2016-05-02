#!/bin/bash

# Run as root.
# Copies _both_ heidrun and krikri directories owned by `vagrant' into
# directories owned by `dpla'

if [ ! -d /krikri ]; then
    >&2 echo "Local directory /krikri does not exist"
    exit 1
fi

if [ ! -d /heidrun ]; then
    >&2 echo "Local directory /heidrun does not exist"
    exit 1
fi

if [ ! -d /heidrun-mappings ]; then
    >&2 echo "Local directory /heidrun-mappings does not exist"
    exit 1
fi

if [ ! -d /home/dpla/krikri ]; then
    mkdir /home/dpla/krikri
fi
if [ ! -d /home/dpla/heidrun-local ]; then
    mkdir /home/dpla/heidrun-local
fi

if [ ! -d /home/dpla/heidrun-mappings-local ]; then
    mkdir /home/dpla/heidrun-mappings-local
fi

rsync -rIptl --delete --checksum \
    --exclude '.git*' --exclude '.vagrant' /krikri/ /home/dpla/krikri \
    || exit 1

rsync -rIptl --delete --checksum \
    --exclude '.git*' --exclude 'log' \
    /heidrun/ /home/dpla/heidrun-local \
    || exit 1

rsync -rIptl --delete --checksum \
    --exclude '.git*' --exclude 'README.md' --exclude 'LICENSE' \
    /heidrun-mappings/ /home/dpla/heidrun-mappings-local \
    || exit 1
