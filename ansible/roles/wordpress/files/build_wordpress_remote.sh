#!/bin/bash

# Runs as 'dpla' user

branch_or_tag=${1:-master}
rsync=/usr/bin/rsync

eval `ssh-agent`
ssh-add $HOME/git_private_key

# Check out theme and transfer into build directory.
# So far, this only has one branch, master.
if [ -d "$HOME/wordpress/.git" ]; then
    cd $HOME/wordpress
    git checkout $branch_or_tag
    git pull || exit 1
else
    rm -rf $HOME/wordpress
    cd $HOME
    git clone git@github.com:dpla/frontend-wp.git wordpress \
        || exit 1
    cd $HOME/wordpress
    git checkout $branch_or_tag
fi
