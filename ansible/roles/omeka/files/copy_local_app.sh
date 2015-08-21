#!/bin/bash

# Run as root.
# Copies directory owned by `vagrant' into directory owned
# by `dpla'

if [ ! -d /exhibitions_dev ]; then
  echo "Local directory /exhibitions_dev does not exist" >&2
  exit 1
fi

if [ ! -d /home/dpla/exhibitions-local ]; then
  mkdir /home/dpla/exhibitions-local
fi

rsync -rIptl --delete --checksum \
    --exclude 'application/logs' \
    /exhibitions_dev/ /home/dpla/exhibitions-local
if [ $? -ne 0 ]; then
  exit 1
fi

chown -Rh dpla:dpla /home/dpla/exhibitions-local