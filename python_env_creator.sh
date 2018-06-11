#!/usr/bin/env bash

SCRIPT=`realpath $0`
SCRIPTPATH=`dirname $SCRIPT`

function lineprint {
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' =
}

function message {
    lineprint
    printf "$1\n"
    lineprint
}

current_action="IDLE"

function confirm_action {
    message "successfully finished action: $current_action"
}

function set_action {
    current_action="$1"
    message "$1"
}

function perform {
    "$@"
    local status=$?
    if [ $status -ne 0 ]
    then
        message "$current_action failed!"
    fi
    return $status
}

function perform_and_exit {
    perform "$@" || exit -1
}

# --------------------------------------------

if [ $# -eq 0 ]
then
    echo "missing arguments. Usage: $0 <PYTHON_VERSION>"
    exit 1
fi

PYTHON_VERSION=$1
PYTHON_VERSION_MAJOR_MINOR=`echo $PYTHON_VERSION | cut -d. -f-2`
PYTHON_DIR=$HOME/envs/python_homes/python$PYTHON_VERSION/

set_action "download and extract python version $PYTHON_VERSION"

perform_and_exit mkdir -p $PYTHON_DIR
perform_and_exit mkdir -p ~/src/
perform_and_exit wget -O ~/src/python.tar.xz https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tar.xz
perform_and_exit cd ~/src
perform_and_exit rm -rf Python-$PYTHON_VERSION
perform_and_exit tar -xf python.tar.xz
perform_and_exit cd Python-$PYTHON_VERSION

confirm_action
set_action "compile python v$PYTHON_VERSION"

perform_and_exit ./configure --prefix=$HOME/envs/python_homes/python$PYTHON_VERSION/
perform_and_exit make -j4
perform_and_exit make install

confirm_action
set_action "create virtual environment in ~/envs/python$PYTHON_VERSION"

perform_and_exit virtualenv --python=$PYTHON_DIR/bin/python$PYTHON_VERSION_MAJOR_MINOR $HOME/envs/python$PYTHON_VERSION

confirm_action
