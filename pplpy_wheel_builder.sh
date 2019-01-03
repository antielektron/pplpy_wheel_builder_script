#!/usr/bin/env bash

# WARNING: this script is still under construction!!!

SCRIPT=`realpath $0`
SCRIPTPATH=`dirname $SCRIPT`

WHEEL_DEPS_PATH="${SCRIPTPATH}/pplpy_wheel_deps"

: "${WHEELS_PATH:=${SCRIPTPATH}/generated_wheels}"

if [ -z "$PIP_FLAGS" ]
then
    PIP_FLAGS="--user" 
fi

if [ -z "$PIP_INSTALL_FLAGS" ]
then
    PIP_INSTALL_FLAGS="--prefix=$HOME/.local"
fi

echo $PIP_FLAGS
echo $PIP_INSTALL_FLAGS

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

# some variables and tags for Versions (using git or mecurial tags here!)
: "${GMP_VERSION:=gmp-6.1.0}"
: "${PPL_VERSION:=1.2}" # not used, since the ppl repo does not declares git-tags for their published versions (?!?)
: "${MPFR_VERSION:=4.0.1}"
: "${MPC_VERSION:=1.1.0}"
: "${GMPY_VERSION:=gmpy2-2.1a4}"
: "${PPLPY_VERSION:=0.7}"

: "${PYTHON_ENV:=python3}"
: "${PYTHON_PIP:=pip3}"

# setting up our environment:
export LD_LIBRARY_PATH=~/local/lib:~/.local/lib/:$LD_LIBRARY_PATH
export C_INCLUDE_PATH=~/local/include:$C_INCLUDE_PATH
export CPLUS_INCLUDE_PATH=~/local/include:$CPLUS_INCLUDE_PATH
export LIBRARY_PATH=$LD_LIBRARY_PATH

# if not exists: create ~/src and ~/local
mkdir -p ~/src
mkdir -p ~/local

echo "checking whether we're on a distro with apt-package-management..."

apt --version

if [ $? -ne 0 ]
then
    message "seems we're not on a debian based distribution. Checking for dnf"

    dnf --version

    if [ $? -ne 0 ]
    then

        message "no apt or dnf package manager found. skipping installing dependencies"

    else

        set_action "installing build dependencies"
        perform_and_exit sudo dnf install git python3-pip python3-devel python-pip wget gcc-c++ gcc-gfortran mercurial libtool bison texinfo autoconf

        # fixing strange default fedora flags
        export CFLAGS=-Wp,-U_FORTIFY_SOURCE

        confirm_action
    fi


else
    # installing build dependencies
    set_action "installing build dependencies"

    perform_and_exit sudo apt install git python3-pip python3-dev python-pip wget build-essential mercurial libtool bison texinfo autoconf
    confirm_action
fi

if [ -e ~/local/lib/libgmp.so ]
then
    message "found existing GMP library in ~/local/lib/"
else

    # download and compile GMP
    set_action "download GMP sources for version $GMP_VERSION"

    perform_and_exit cd ~/src
    # removing existing sources
    rm -rf ./gmp/

    # checking out correct version
    perform_and_exit hg clone https://gmplib.org/repo/gmp/ ./gmp
    cd gmp

    perform_and_exit hg up $GMP_VERSION

    confirm_action
    set_action "compile GMP $GMP_VERSION"

    perform_and_exit ./.bootstrap
    perform_and_exit ./configure --prefix=`realpath ~/local` --enable-cxx --enable-fat
    perform_and_exit make -j4
    perform_and_exit make install

    confirm_action

fi

if [ -e ~/local/lib/libppl.so ]
then
    message "found existing PPL library in ~/local/lib/"
else

    set_action "download PPL sources for version $PPL_VERSION"

    perform_and_exit cd ~/src/

    rm -rf ./ppl/

    perform_and_exit git clone git://git.cs.unipr.it/ppl/ppl.git

    confirm_action
    set_action "compile PPL $PPL_VERSION"

    perform_and_exit cd ppl/
    perform_and_exit autoreconf
    perform_and_exit ./configure --prefix=`realpath ~/local` --disable-documentation
    perform_and_exit make -j4
    perform_and_exit make install

    confirm_action
fi


if [ -e ~/local/lib/libmpfr.so ]
then
    message "found existing MPFR library in ~/local/lib/"
else

    set_action "download MPFR sources for version $MPFR_VERSION"

    perform_and_exit cd ~/src

    perform_and_exit rm -rf mpfr-${MPFR_VERSION} # cleaning up

    perform_and_exit wget http://www.mpfr.org/mpfr-current/mpfr-${MPFR_VERSION}.tar.xz
    perform_and_exit tar -xf mpfr-${MPFR_VERSION}.tar.xz

    # cleaning up
    perform_and_exit rm mpfr-${MPFR_VERSION}.tar.xz

    confirm_action
    set_action "compile MPFR $MPFR_VERSION"

    perform_and_exit cd mpfr-${MPFR_VERSION}

    perform_and_exit ./configure --prefix=$HOME/local --with-gmp=$HOME/local
    perform_and_exit make -j4
    perform_and_exit make install

    confirm_action
fi

if [ -e ~/local/lib/libmpc.so ]
then
    message "found existing MPC library in ~/local/lib/"
else

    set_action "download MPC sources for version $MPC_VERSION"

    perform_and_exit cd ~/src
    perform_and_exit wget https://ftp.gnu.org/gnu/mpc/mpc-${MPC_VERSION}.tar.gz
    perform_and_exit tar -xf mpc-${MPC_VERSION}.tar.gz

    # cleaning up
    perform_and_exit rm mpc-${MPC_VERSION}.tar.gz

    perform_and_exit cd mpc-${MPC_VERSION}

    confirm_action
    set_action "compile MPC $MPC_VERSION"

    perform_and_exit ./configure --prefix=$HOME/local --with-gmp=$HOME/local --with-mpfr=$HOME/local
    perform_and_exit make -j4
    perform_and_exit make install

    confirm_action

fi

set_action "looking for installed wheels package and install it if neccessary"

$PYTHON_PIP show wheel
pip_status=$?

if [ $pip_status -ne 0 ]
then
    $PYTHON_PIP install $PIP_FLAGS wheel
else
    message "found existing wheel in: $($PYTHON_PIP show wheel | grep Location | awk '{print $2}')"  
fi

confirm_action


set_action "download GMPY sources for version $GMPY_VERSION"

perform_and_exit cd ~/src/

perform_and_exit rm -rf gmpy

perform_and_exit git clone https://github.com/aleaxit/gmpy.git

confirm_action

perform_and_exit cd gmpy/
perform_and_exit git checkout $GMPY_VERSION

confirm_action

# this patch is only necessary for gmpy version older than 2.1.0a4
# set_action "patching gmpy's setup.py to make it compatible with python-wheel"

# perform_and_exit git apply < $SCRIPTPATH/gmpy.patch

# confirm_action
set_action "compile, build_wheel and install GMPY $GMPY_VERSION with git"

export CFLAGS="-I~/local/include/ -L~/local/lib/ $CFLAGS"

perform_and_exit /usr/bin/env $PYTHON_ENV setup.py bdist_wheel
perform_and_exit /usr/bin/env $PYTHON_ENV setup.py install $PIP_INSTALL_FLAGS

confirm_action


confirm_action
set_action "looking for cython and cysignals and install them if needed"

$PYTHON_PIP show cython
pip_status=$?

if [ $pip_status -ne 0 ]
then
    $PYTHON_PIP install $PIP_FLAGS cython
else
    message "found existing cython in: $($PYTHON_PIP show cython | grep Location | awk '{print $2}')"  
fi

$PYTHON_PIP show cysignals
pip_status=$?

if [ $pip_status -ne 0 ]
then
    $PYTHON_PIP install $PIP_FLAGS cysignals
else
    message "found existing cysignals in: $($PYTHON_PIP show cysignals | grep Location | awk '{print $2}')"
fi

confirm_action

# now setup a list of external libraries to include in our wheel build and create something like 
# a 'pure dependency package' for the pplpy-wheel

set_action "create binary dependency wheel for pplpy"

perform_and_exit cd $WHEEL_DEPS_PATH

# copy all needed libraries in here

perform_and_exit cp ~/local/lib/*.so ./
perform_and_exit cp ~/local/lib/*.so.* ./

# and building package:

perform_and_exit /usr/bin/env $PYTHON_ENV setup.py bdist_wheel

# clean up:

perform_and_exit rm -rf ./*.so

confirm_action
set_action "download pplpy sources"

perform_and_exit cd ~/src

# setting up cflags:
export CFLAGS="-I~/local/include/ -L~/local/lib/ $CFLAGS"

perform_and_exit rm -rf ./pplpy

perform_and_exit git clone https://github.com/videlec/pplpy.git

perform_and_exit cd pplpy

perform_and_exit git checkout $PPLPY_VERSION

confirm_action

set_action "patching pplpy's setup.py"

perform_and_exit git apply < $SCRIPTPATH/pplpy.patch

confirm_action
set_action "create wheel for pplpy"

/usr/bin/env $PYTHON_ENV setup.py bdist_wheel

confirm_action

# copy built wheels to working directory

set_action "copy built wheels to $WHEELS_PATH"

perform_and_exit rm -rf $WHEELS_PATH
perform_and_exit mkdir $WHEELS_PATH
perform_and_exit cp $WHEEL_DEPS_PATH/dist/*.whl "$WHEELS_PATH/"
perform_and_exit cp ~/src/pplpy/dist/*.whl "$WHEELS_PATH/"
perform_and_exit cp ~/src/gmpy/dist/*.whl "$WHEELS_PATH/"

confirm_action

message "...and we're done!\nGenerated wheels can be found in $WHEELS_PATH\nTo install a wheel file just run: $PYTHON_PIP install wheel_file.whl --user\nHave a nice day :-)"

