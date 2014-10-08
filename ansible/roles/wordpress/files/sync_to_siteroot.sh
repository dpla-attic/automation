#!/bin/bash


rsync=/usr/bin/rsync

$rsync -ruptolg --checksum --delete --delay-updates \
    /home/dpla/wordpress/ /srv/www/wordpress
