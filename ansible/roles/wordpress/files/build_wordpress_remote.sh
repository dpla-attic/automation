#!/bin/bash

# Runs as 'dpla' user

LOGFILE=/tmp/build_wordpress_remote.log

echo "starting." > $LOGFILE

branch_or_tag=${1:-master}
rsync=/usr/bin/rsync

eval `ssh-agent`
ssh-add $HOME/git_private_key

# Check out theme and transfer into build directory.
# So far, this only has one branch, master.
if [ -d "$HOME/wordpress/.git" ]; then
    echo "doing checkout in $HOME/wordpress ..." >> $LOGFILE
    cd $HOME/wordpress
    git checkout $branch_or_tag
    echo "doing git pull ..." >> $LOGFILE
    git pull || exit 1
else
    echo "clearing $HOME/wordpress and doing a checkout ..." >> $LOGFILE
    rm -rf $HOME/wordpress
    cd $HOME
    echo "... cloning ..." >> $LOGFILE
    git clone git@github.com:dpla/frontend-wp.git wordpress \
        || exit 1
    echo "... checking out ..." >> $LOGFILE
    cd $HOME/wordpress
    git checkout $branch_or_tag
fi

echo "done." >> $LOGFILE
