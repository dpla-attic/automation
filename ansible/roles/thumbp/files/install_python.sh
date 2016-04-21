#!/bin/bash

PY_VERSION=2.7.10
export PYENV_ROOT=$HOME/.pyenv
export PATH=$PYENV_ROOT/bin:$PATH
eval "$(pyenv init -)"

pyenv install -s $PY_VERSION

pyenv global $PY_VERSION

pip install --upgrade pip

pip install virtualenv

pyenv rehash

if [ ! -d /opt/thumbp/bin ]; then
    virtualenv /opt/thumbp
fi

if [ "`/opt/thumbp/bin/python -V`" != "Python $PY_VERSION" ]; then
    rm -rf /opt/thumbp/*
    virtualenv /opt/thumbp
fi
