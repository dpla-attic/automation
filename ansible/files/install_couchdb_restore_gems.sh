#!/bin/bash

cd $HOME

USE_VERSION=$1
export PATH=$HOME/.rbenv/bin:$PATH

eval "`rbenv init -`"

rbenv shell $USE_VERSION

gem install --conservative couchrest:1.1.3
gem install --conservative ruby-progressbar