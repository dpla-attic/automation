#!/bin/bash

USE_VERSION=$1
USE_ASSETS=${2:-unrestricted}
export PATH=$HOME/.rbenv/bin:$PATH

eval "`rbenv init -`"

cd $HOME/frontend

rbenv shell $USE_VERSION

if [[ "$USE_ASSETS" = "restricted" ]]; then
    # Start ssh-agent and set environment variables.
    # Work-around for private GitHub repository in Gemfile.
    eval `ssh-agent`
    ssh-add $HOME/git_private_key
    bundle install
    bundle update dpla_frontend_assets
    # Variable set above by ssh-agent
    kill $SSH_AGENT_PID
else
    bundle install --without dpla_branding
fi

rbenv rehash
bundle exec rake assets:precompile

/usr/bin/rsync -ruptolg --checksum --delete --delay-updates \
    --exclude 'log' \
    --exclude 'tmp' \
    --exclude '.git' \
    --exclude 'public/uploads' \
    /home/dpla/frontend/ /srv/www/frontend
if [ $? -ne 0 ]; then
    exit 1
fi

cd /srv/www/frontend
bundle exec rake db:migrate

logdir='/srv/www/frontend/log'
if [ ! -d $logdir ]; then
    mkdir $logdir \
        && chown dpla:webapp $logdir \
        && chmod 0775 $logdir
fi
