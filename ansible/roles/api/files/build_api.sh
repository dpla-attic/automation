#!/bin/bash

USE_VERSION=$1
export PATH=$HOME/.rbenv/bin:$PATH

eval "`rbenv init -`"

cd /home/dpla/api

rbenv shell $USE_VERSION

bundle install

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

cd /srv/www/api
bundle exec rake jobs:clear \
    && rm -rf tmp/qa_reports/* \
    && bundle exec rake tmp:clear \
    && bundle exec rake db:migrate
