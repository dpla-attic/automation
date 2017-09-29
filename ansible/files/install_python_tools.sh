#!/bin/bash

USE_VERSION=$1

cd $HOME

if [ ! -d $HOME/.pyenv ]; then
    git clone https://github.com/pyenv/pyenv.git $HOME/.pyenv && \
        echo 'export PYENV_ROOT="$HOME/.pyenv"' >> $HOME/.bashrc && \
        echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> $HOME/.bashrc && \
        echo 'eval "$(pyenv init -)"' >> $HOME/.bashrc
    if [ $? -ne 0 ]; then
        exit 1
    fi
fi

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

if [ -d $HOME/.pyenv/versions/$USE_VERSION ]; then
    pyenv global $USE_VERSION
else
    pyenv install $USE_VERSION
    if [ $? -ne 0 ]; then
        exit 1
    fi
    pyenv global $USE_VERSION
fi

pyenv rehash
