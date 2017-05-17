#!/bin/bash


rsync=/usr/bin/rsync

$rsync -rIptogl --checksum --delete --delay-updates \
    --exclude 'wp-content/uploads' \
    --exclude 'wp-config.php' \
    --exclude '.git' \
    /home/wordpress/wordpress/ /srv/www/wordpress
