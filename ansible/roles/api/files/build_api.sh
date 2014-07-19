#!/bin/bash

USE_VERSION=$1
export PATH=$HOME/.rbenv/bin:$PATH
eval "`rbenv init -`"

cd $HOME/api

rbenv shell $USE_VERSION

bundle install

/usr/bin/rsync -ruptolg --delete --delay-updates \
    --exclude 'var/log' \
    /home/dpla/api/ /srv/www/api
if [ $? -ne 0 ]; then
    exit 1
fi

cd /srv/www/api
bundle exec rake db:migrate

logdir='/srv/www/api/var/log'
if [ ! -d $logdir ]; then
    mkdir $logdir \
        && chown dpla:webapp $logdir \
        && chmod 0775 $logdir
fi
