#!/bin/bash

# Drop any existing Elasticsearch river.

USE_VERSION=$1
export PATH=$HOME/.rbenv/bin:$PATH
tmpfile=/tmp/init_index_and_repos
eval "`rbenv init -`"
rbenv shell $USE_VERSION
cd /srv/www/api


# Check if river exists, and delete it if it does
bundle exec rake v1:river_list > $tmpfile || exit 1
river=`grep dpla_river $tmpfile`
if [ "$river" != "" ]; then
    bundle exec rake v1:delete_river > $tmpfile 2>&1 || exit 1
fi

rm $tmpfile
exit 0
