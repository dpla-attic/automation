#!/bin/bash

USE_VERSION=$1
export PATH=$HOME/.rbenv/bin:$PATH

eval "`rbenv init -`"

cd /home/dpla/api

rbenv shell $USE_VERSION

bundle install
rbenv rehash

/usr/bin/rsync -ruptolg --checksum --delete --delay-updates \
    --exclude 'var/log' \
    --exclude 'tmp' \
    --exclude '.git' \
    /home/dpla/api/ /srv/www/api
if [ $? -ne 0 ]; then
    exit 1
fi

# Log and temporary directories
dirs_to_check='/srv/www/api/var/log /srv/www/api/tmp'
for dir in $dirs_to_check; do
    if [ ! -d $dir ]; then
        mkdir $dir \
            && chown dpla:webapp $dir \
            && chmod 0775 $dir
    fi
done

# Clear out the job queue, caches, and temporary files.
# Is it OK to do this here in one place, or will there be
# issues with upgrades?  We'll at least want to ensure that
# the current application instance is taken out of any
# loadbalancer's rotation for the duration of this script.
# - mb
cd /srv/www/api
bundle exec rake db:migrate \
     && bundle exec rake tmp:clear \
     && bundle exec rake jobs:clear \
     && bundle exec rake contentqa:delete_reports
