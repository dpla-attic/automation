#!/bin/bash

LOG=/tmp/install_elastichq.log

echo "Installing ElasticHQ" > $LOG

set -e


cd $HOME

echo "In $HOME ..." >> $LOG

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
export PYENV_DIR=`pwd`
eval "$(pyenv init -)"


git clone https://github.com/ElasticHQ/elasticsearch-HQ.git

echo "... cloned Git repository" >> $LOG

cd elasticsearch-HQ

echo "... in elasticsearch-HQ" >> $LOG

selector=`grep gunicorn requirements.txt | tr -d '#'`

pip install $selector

echo "... did pip install $selector" >> $LOG

pip install -r requirements.txt

echo "... did pip install -r requirements.txt"
