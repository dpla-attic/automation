#!/bin/bash

use_version=$1
inventory_groups=`echo $2 | sed 's/,/ /g'`


echo $inventory_groups | grep ingestion_app > /dev/null \
    && do_webapp=1 || do_webapp=0
echo $inventory_groups | grep '\<worker\>' > /dev/null \
    && do_worker=1 || do_worker=0

export PATH=$HOME/.rbenv/bin:$PATH

eval "`rbenv init -`"
cd /home/dpla/heidrun || exit 1
rbenv global $use_version

bundle install || exit 1
rbenv rehash

/usr/bin/rsync -rptolg --checksum --delete --delay-updates \
    --exclude 'log' \
    --exclude 'tmp' \
    --exclude '.git' \
    /home/dpla/heidrun/ /opt/heidrun
if [ $? -ne 0 ]; then
    exit 1
fi

# Don't delete "extraneous" files in the destination directory, unlike the
# other two rsync calls
/usr/bin/rsync -rptolg --checksum --delay-updates \
    --exclude 'README.md' \
    --exclude 'LICENSE' \
    --exclude '.git*' \
    /home/dpla/heidrun-mappings/ /opt/heidrun/vendor/mappings
if [ $? -ne 0 ]; then
    exit 1
fi

# Log and temporary directories
dirs_to_check='/opt/heidrun/log /opt/heidrun/tmp'
for dir in $dirs_to_check; do
    if [ ! -d $dir ]; then
        mkdir $dir \
            && chown dpla:webapp $dir \
            && chmod 0775 $dir
    fi
done

cd /opt/heidrun
if [ $do_webapp -eq 1 ]; then
    bundle exec rake db:migrate || exit 1
    bundle exec rake assets:precompile || exit 1
fi
bundle exec rake tmp:clear || exit 1
