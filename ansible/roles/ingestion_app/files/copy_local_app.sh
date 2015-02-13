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

if [ ! -d /home/dpla/krikri ]; then
    mkdir /home/dpla/krikri
fi
if [ ! -d /home/dpla/heidrun ]; then
    mkdir /home/dpla/heidrun
fi

rsync -ruptl --delete --checksum \
    --exclude '.git*' /krikri/ /home/dpla/krikri \
    || exit 1

rsync -ruptl --delete --checksum \
    --exclude '.git*' --exclude 'log' \
    /heidrun/ /home/dpla/heidrun \
    || exit 1


