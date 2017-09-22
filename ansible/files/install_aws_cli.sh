#!/bin/bash

# Install or upgrade the AWS Command-Line Interface (CLI) Python package in a
# Pyenv.

usage() {
    echo <<EOT

install_aws_cli.sh <pyenv Python version>

EOT
}

exit_w_error() {
    echo >&2 $1
    exit 1
}

if [ "x$1" == "x" ]; then
    usage
    exit_w_error "First argument is missing"
fi

env

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

if [ "x$PYENV_SHELL" == "x" ]; then
    exit_w_error "Pyenv is not installed, or not activated."
fi

if [ -d $HOME/.pyenv/versions/$1 ]; then
    export PYENV_VERSION=$1
else
    exit_w_error "Pyenv Python version $1 is not present."
fi

pip install -U awscli
pip install -U s3cmd
