#!/bin/bash

# Delete any undeployed search indices

USE_VERSION=$1
export PATH=$HOME/.rbenv/bin:$PATH
tmpfile=/tmp/init_index_and_repos
eval "`rbenv init -`"
rbenv shell $USE_VERSION
cd /srv/www/api


bundle exec rake v1:search_indices > $tmpfile || exit 1
undep_indices=`grep -v DEPLOYED $tmpfile`
if [ "$undep_indices" != "" ]; then
    for i in $undep_indices; do
        bundle exec rake v1:delete_search_index[$i,really] > $tmpfile 2>&1 \
                || exit 1
    done
fi

rm $tmpfile
exit 0
