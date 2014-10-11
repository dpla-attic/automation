#!/bin/bash

# Create and deploy a new Elasticsearch index, with a river

USE_VERSION=$1
export PATH=$HOME/.rbenv/bin:$PATH
tmpfile=/tmp/init_index_and_repos
eval "`rbenv init -`"
rbenv shell $USE_VERSION
cd /srv/www/api

bundle exec rake v1:create_and_deploy_index || exit 1

exit 0
