#!/bin/bash

# Runs as 'dpla' user

rsync=/usr/bin/rsync

# Sync newly-downloaded Wordpress with build directory

$rsync -ruptl --checksum --delete \
    --exclude '.git' \
    --exclude 'wp-content/plugins' \
    --exclude 'wp-content/themes/berkman_custom_dpla' \
    --exclude 'wp-config.php' \
    /tmp/wordpress/ /home/dpla/wordpress
