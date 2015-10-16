#!/bin/bash

USE_VERSION=$1
export PATH=$HOME/.rbenv/bin:$PATH
LOGFILE=/tmp/build_frontend.log

echo "starting" > $LOGFILE

eval "`rbenv init -`" >> $LOGFILE 2>&1
# Start ssh-agent and set environment variables.
# Work-around for private GitHub repository in Gemfile.
eval `ssh-agent`
ssh-add $HOME/git_private_key  >> $LOGFILE 2>&1

cd $HOME/frontend

rbenv shell $USE_VERSION >> $LOGFILE 2>&1

echo "installing bundle ..." >> $LOGFILE

rm -f Gemfile.lock
bundle install >> $LOGFILE 2>&1
bundle update dpla_frontend_assets >> $LOGFILE 2>&1
rbenv rehash

echo "precompiling assets ..." >> $LOGFILE
bundle exec rake assets:precompile >> $LOGFILE 2>&1

echo "killing ssh_agent ..." >> $LOGFILE
# Variable set above by ssh-agent
kill $SSH_AGENT_PID

echo "rsync home to /srv/www ..." >> $LOGFILE
/usr/bin/rsync -rIptogl --checksum --delete --delay-updates \
    --exclude 'log' \
    --exclude 'tmp' \
    --exclude '.git' \
    --exclude 'public/uploads' \
    /home/dpla/frontend/ /srv/www/frontend
if [ $? -ne 0 ]; then
    exit 1
fi

echo "migrate database ..." >> $LOGFILE
cd /srv/www/frontend
bundle exec rake db:migrate

echo "check logfile directory ..." >> $LOGFILE

logdir='/srv/www/frontend/log'
if [ ! -d $logdir ]; then
    mkdir $logdir \
        && chown dpla:webapp $logdir \
        && chmod 0775 $logdir
fi
