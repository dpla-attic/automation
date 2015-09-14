#!/bin/bash

# Usage:  build_ingestion.sh [-f] <ruby version> <inventory groups>
# ... where inventory groups are separated by commas.
# ... and -f means to go "fast," skipping certain tasks that are unnecessary
#     if you're making iterative changes to application code.
# ... and all switches (e.g. -f) must come before other arguments.

LOGFILE=/tmp/build_ingestion.log

echo "starting." > $LOGFILE

fast=0
while getopts :f opt; do
    case $opt in
        f)
            fast=1
            ;;
        \?)
            >&2 echo "Invalid option -$OPTARG"
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))  # Remove getopts switches from args

use_version=$1
inventory_groups=`echo $2 | sed 's/,/ /g'`

echo "use_version: $use_version" >> $LOGFILE
echo "inventory groups: $inventory_groups" >> $LOGFILE

echo $inventory_groups | grep ingestion_app > /dev/null \
    && do_webapp=1 || do_webapp=0
echo $inventory_groups | grep '\<worker\>' > /dev/null \
    && do_worker=1 || do_worker=0

export PATH=$HOME/.rbenv/bin:$PATH

eval "`rbenv init -`"
cd /home/dpla/heidrun || exit 1
rbenv global $use_version

echo "installing bundle ..." >> $LOGFILE

if [ $fast == 0 ]; then
    rm -f Gemfile.lock
    bundle install >> $LOGFILE 2>&1 || exit 1
    rbenv rehash
fi

echo "rsyncing to /opt/heidrun ..." >> $LOGFILE

/usr/bin/rsync -rIptolg --checksum --delete --delay-updates \
    --exclude 'log' \
    --exclude 'tmp' \
    --exclude '.git' \
    /home/dpla/heidrun/ /opt/heidrun
if [ $? -ne 0 ]; then
    exit 1
fi

echo "rsyncing mappings ..." >> $LOGFILE

# Don't delete "extraneous" files in the destination directory, unlike the
# other two rsync calls
/usr/bin/rsync -rIptolg --checksum --delay-updates \
    /home/dpla/heidrun-mappings/heidrun /opt/heidrun/vendor/mappings
if [ $? -ne 0 ]; then
    exit 1
fi

echo "checking directories ... " >> $LOGFILE

# Log and temporary directories
dirs_to_check='/opt/heidrun/log /opt/heidrun/tmp'
for dir in $dirs_to_check; do
    if [ ! -d $dir ]; then
        mkdir $dir \
            && chown dpla:webapp $dir \
            && chmod 0775 $dir
    fi
done

echo "running rake ..." >> $LOGFILE

cd /opt/heidrun
if [ $do_webapp -eq 1 ]; then
    bundle exec rake assets:precompile >> $LOGFILE 2>&1 || exit 1
    if [ $fast -eq 0 ]; then
        bundle exec rake db:migrate >> $LOGFILE 2>&1 || exit 1
    fi
fi

echo "clearing tmp directory ..." >> $LOGFILE

bundle exec rake tmp:clear >> $LOGFILE 2>&1 || exit 1

echo "done." >> $LOGFILE
