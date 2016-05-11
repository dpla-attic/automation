#!/bin/bash

log=/tmp/build_thumbp.log

export NVM_DIR="$HOME/.nvm"
. $NVM_DIR/nvm.sh

echo "Starting at `date`" > $log

cd /opt/thumbp/src/thumbp || exit_w_error "Can not cd to /opt/thumbp/src/thumbp"

exit_w_error() {
    echo >&2 $1
    echo $1 >> $log
    exit 1
}

echo "Ensuring correct version of Node" | tee -a $log
nvm install || exit_w_error "nvm install failed"

echo "Installing packages ..." | tee -a $log
npm install || exit_w_error "npm install failed"

echo "rsyncing to /opt/thumbp ..." | tee -a $log
/usr/bin/rsync -rIptolg --checksum --delete --delay-updates \
    --exclude '.git' \
    /opt/thumbp/src/thumbp/ /opt/thumbp/thumbp
if [ $? -ne 0 ]; then
    exit_w_error "rsync failed"
fi

echo "Success" | tee -a $log
exit 0
