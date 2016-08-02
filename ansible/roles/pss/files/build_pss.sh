#!/bin/bash

USE_VERSION=$1
BRANDING=${2:-""}
export PATH=$HOME/.rbenv/bin:$PATH
LOGFILE=/tmp/build_pss.log

echo "starting" > $LOGFILE

eval "`rbenv init -`"

if [ "$BRANDING" == "branding" ]; then
    # Start ssh-agent and set environment variables.
    # Work-around for private GitHub repository in Gemfile.
    eval `ssh-agent`
    ssh-add $HOME/git_private_key
fi

cd /home/dpla/pss

rbenv shell $USE_VERSION

echo "using version ${USE_VERSION} ..." >> $LOGFILE
echo "installing bundle ..." >> $LOGFILE

rm -f Gemfile.lock
bundle install >> $LOGFILE 2>&1
if [ $? -ne 0 ]; then
    exit 1
fi
rbenv rehash >> $LOGFILE 2>&1

echo "precompiling assets ..." >> $LOGFILE
bundle exec rake assets:precompile >> $LOGFILE 2>&1 || exit 1

if [ "$BRANDING" == "branding" ]; then
    echo "killing ssh_agent ..." >> $LOGFILE
    # Variable set above by ssh-agent
    kill $SSH_AGENT_PID
fi

echo "rsync from home to /srv/www/pss ..." >> $LOGFILE

/usr/bin/rsync -rIptogl --checksum --delete --delay-updates \
    --exclude 'log' \
    --exclude 'tmp' \
    --exclude '.git' \
    --exclude 'public/uploads' \
    /home/dpla/pss/ /srv/www/pss
if [ $? -ne 0 ]; then
    exit 1
fi

cd /srv/www/pss

echo "migrate database ..." >> $LOGFILE
cd /srv/www/pss
bundle exec rake db:migrate >> $LOGFILE 2>&1 || exit 1
