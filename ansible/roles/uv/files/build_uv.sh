#!/bin/bash

node_version=$1
log=/tmp/build_uv.log
src_dir=/opt/uv/src/universalviewer
export NVM_DIR="/opt/uv/.nvm"

. $NVM_DIR/nvm.sh  # necessary?  It's already in `uv' user's .bashrc

echo "Starting at `date`" > $log


cd $src_dir || exit_w_error "Can not cd to $src_dir"

exit_w_error() {
    echo >&2 $1
    echo $1 >> $log
    exit 1
}

echo "Ensuring correct version of Node" | tee -a $log
nvm install $node_version || exit_w_error "nvm install failed"

echo "Making sure that Grunt is installed." | tee -a $log
npm install grunt-cli || exit_w_error "could not install Grunt"

echo "Making sure that Bower is installed." | tee -a $log
npm install bower || exit_w_error "could not install Bower"

src_modules_dir=$src_dir/node_modules
export PATH=$src_modules_dir/grunt-cli/bin:$src_modules_dir/bower/bin:$PATH

echo "Installing packages ..." | tee -a $log

npm install || exit_w_error "'npm install' failed"
bower install || exit_w_error "'bower install' failed"
grunt sync || exit_w_error "'grunt sync' failed"

echo "... done" | tee -a $log

echo "rsyncing ..." | tee -a $log
/usr/bin/rsync -rIptolg --checksum --delete --delay-updates \
    --exclude '.git' \
    $src_dir/ /opt/uv/universalviewer
if [ $? -ne 0 ]; then
    exit_w_error "rsync failed"
fi

echo "Success" | tee -a $log
exit 0
