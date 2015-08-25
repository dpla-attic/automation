#!/bin/bash


rsync=/usr/bin/rsync

$rsync -rIptogl --checksum --delete --delay-updates \
    --exclude 'wp-content/uploads' \
    --exclude 'wp-config.php' \
    --exclude '.git' \
    /home/dpla/wordpress/ /srv/www/wordpress
