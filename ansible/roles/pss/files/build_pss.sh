#!/bin/bash

USE_VERSION=$1
export PATH=$HOME/.rbenv/bin:$PATH
LOGFILE=/tmp/build_pss.log

echo "starting" > $LOGFILE

eval "`rbenv init -`"

cd /home/dpla/pss

rbenv shell $USE_VERSION

echo "installing bundle ..." >> $LOGFILE

rm -f Gemfile.lock
bundle update
rbenv rehash

echo "precompiling assets ..." >> $LOGFILE
bundle exec rake assets:precompile

echo "killing ssh_agent ..." >> $LOGFILE
# Variable set above by ssh-agent
kill $SSH_AGENT_PID

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
bundle exec rake db:migrate
