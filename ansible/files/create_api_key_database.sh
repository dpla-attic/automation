#!/bin/bash

USE_VERSION=$1
export PATH=$HOME/.rbenv/bin:$PATH
tmpfile=/tmp/init_index_and_repos
eval "`rbenv init -`"
rbenv shell $USE_VERSION
cd /srv/www/api

bundle exec rake v1:recreate_repo_api_key_database
