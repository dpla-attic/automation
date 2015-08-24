#!/bin/bash

# Runs as 'dpla' user

rsync=/usr/bin/rsync

cd $HOME

$rsync -rIptl --delete --checksum \
    --exclude '.git' \
    --exclude 'wp-config.php' \
    --exclude 'wp-content/uploads' \
    /wordpress_dev/ $HOME/wordpress
