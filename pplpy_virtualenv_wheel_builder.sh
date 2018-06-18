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

# -----------------------------------------------------------------------------

if [ $# -eq 0 ]
then
    echo "ERROR: expecting python versions for building environments. usage: $0 <PYTHON_VERSION>"
    exit -1
fi

PYTHON_VERSION=$1

if [ ! -e $HOME/envs/python$PYTHON_VERSION ]
then

    set_action "create environment for python $PYTHON_VERSION"

    perform_and_exit $SCRIPTPATH/python_env_creator.sh $PYTHON_VERSION

    confirm_action

else

    message "found existing python evironment: $HOME/envs/python$PYTHON_VERSION"

fi
set_action "running pplpy_wheel_builder in expected environment"

export PIP_FLAGS=" "
export PIP_INSTALL_FLAGS=" "

export PYTHON_ENV=python
export PYTHON_PIP=pip
export WHEELS_PATH="${SCRIPTPATH}/generated_wheels_$PYTHON_VERSION/"

perform_and_exit source $HOME/envs/python$PYTHON_VERSION/bin/activate
perform_and_exit $SCRIPTPATH/pplpy_wheel_builder.sh

confirm_action