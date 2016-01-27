#!/bin/bash

USE_VERSION=$1
export PATH=$HOME/.rbenv/bin:$PATH
LOGFILE=/tmp/build_api.log

echo "starting" > $LOGFILE

eval "`rbenv init -`"

cd /home/dpla/api

rbenv shell $USE_VERSION >> $LOGFILE 2>&1

echo "installing bundle ..." >> $LOGFILE

rm -f Gemfile.lock
bundle install >> $LOGFILE 2>&1
rbenv rehash

echo "rsync from home to /srv/www/api ..." >> $LOGFILE

/usr/bin/rsync -rIptolg --checksum --delete --delay-updates \
    --exclude 'var/log' \
    --exclude 'tmp' \
    --exclude '.git' \
    /home/dpla/api/ /srv/www/api
if [ $? -ne 0 ]; then
    exit 1
fi

echo "checking log and tmp directories ..." >> $LOGFILE

# Log and temporary directories
dirs_to_check='/srv/www/api/var/log /srv/www/api/tmp'
for dir in $dirs_to_check; do
    if [ ! -d $dir ]; then
        mkdir $dir \
            && chown dpla:webapp $dir \
            && chmod 0775 $dir
    fi
done

echo "running rake tasks ..." >> $LOGFILE

# Clear out the job queue, caches, and temporary files.
# Is it OK to do this here in one place, or will there be
# issues with upgrades?  We'll at least want to ensure that
# the current application instance is taken out of any
# loadbalancer's rotation for the duration of this script.
# - mb
cd /srv/www/api
bundle exec rake db:migrate >> $LOGFILE 2>&1 \
     && bundle exec rake tmp:clear >> $LOGFILE 2>&1
