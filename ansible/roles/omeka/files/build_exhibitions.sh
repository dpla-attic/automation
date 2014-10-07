#!/bin/sh

/usr/bin/rsync -ruptolgC --delete --delay-updates \
    --exclude 'themes/dpla/exhibitions-assets' \
    --exclude 'application/logs' \
    --exclude 'files' \
    /home/dpla/exhibitions /srv/www

if [ $? -ne 0 ]; then
	exit 1
fi

/usr/bin/rsync -ruptolgC --delete --delay-updates \
    /home/dpla/exhibitions-assets/ /srv/www/exhibitions/themes/dpla/exhibitions-assets

