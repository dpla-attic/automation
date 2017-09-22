#!/bin/bash

# This script installs Node Version Manager, NVM.
# It's expected that deployments will install the correct version of node by
# running `nvm install` inside a directory with an `.nvmrc` file that specifies
# the version of Node.js.

NVM_VERSION=$1
nvm_tag="v$1"

log=/tmp/install_nvm_$LOGNAME.log
echo Starting > $log

cd $HOME

exit_w_error() {
    echo >&2 $1
    echo $1 >> $log
    exit 1
}

if (! `grep -q NVM_DIR $HOME/.bashrc`); then
    echo 'export NVM_DIR="$HOME/.nvm"' >> $HOME/.bashrc
    echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"' >> $HOME/.bashrc
else
    export NVM_DIR=$HOME/.nvm
    . $NVM_DIR/nvm.sh
    v=`nvm --version`
    if [ $v == $NVM_VERSION ]; then
        echo Already installed | tee -a $log
        exit 0
    fi
fi

if [ ! -d $HOME/.nvm ]; then
    git clone https://github.com/creationix/nvm.git $HOME/.nvm || \
        exit_w_error "Could not clone nvm repo"
fi

cd $HOME/.nvm

echo "Checking out NVM $nvm_tag" >> $log
git fetch || exit_w_error "Could not fetch from nvm repo"
git checkout $nvm_tag || exit_w_error "Could not check out $nvm_tag"

echo "Success: changed" | tee -a $log

exit 0
