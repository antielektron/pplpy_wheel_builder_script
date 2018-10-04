# PPLPY WHEEL BUILDER

the script [pplpy_wheel_builder.sh](pplpy_wheel_builder.sh) generates three precompiled wheels: 
* One for pplpy 
* One containing the libraries pplpy depends on
* One for gmpy2 

Currently it only runs on debian and redhat/fedora based distributions because it's using `apt` and `dnf` to install the build dependencies *(but porting this to other distros should be easy)*

### Prerequisites

* just a fresh Ubuntu or Fedora installation

### Download

* Precompiled wheels for the amd64 architecture (linux) and the builder script itself can be found in the release section

### How to use the script

* download this script by cloning this repo
* change to the scripts directory and run

  ```bash
  ./pplpy_wheel_builder.sh
  ```

* The generated wheels can be found in the `generated_wheels` folder

### installing the wheels

* make sure `cython` and `cysignals` are installed:

  ```bash
  pip3 install cython cysignals --user
  ```

  * or system wide with

    ```bash
    sudo -H pip3 install cython cysignals 
    ```

* run

  ```bash
  pip3 install *.whl --user
  ```

  * or system wide:

    ```
    sudo -H pip3 install *.whl
    ```

* **NOTE**: you have to adjust your `LD_LIBRARY_PATH` otherwise the installed libraries are not found at runtime. To do this add the line

  ```bash
  export LD_LIBRARY_PATH=~/.local/lib/:$LD_LIBRARY_PATH
  ```

  * or if the packages are installed system wide:

    ```bash
    export LD_LIBRARY_PATH=/usr/local/lib/:$LD_LIBRARY_PATH
    ```

  at the end of your `~/.bashrc` (or your `.zshrc` or whatever fancy shell you use)

----

## Running the script for different python versions

the script [pplpy_virtualenv_wheel_builder.sh](pplpy_virtualenv_wheel_builder.sh) creates a virtual environment for a given python version (full version number!) in `~/envs` and generates the wheels using that python environment. Usage:

```bash
./pplpy_virtualenv_wheel_builder.sh $PYTHON_VERSION
```

* e.g.: for `python2.7.15`:

  ```bash
  ./pplpy_virtualenv_wheel_builder.sh 2.7.15
  ```

**NOTE**: [virtualenv](apt://virtualenv) has to be installed before (using your favourite package manager)

## overwritable system variables:

| name                    | default value                     | notes                                                        |
| ----------------------- | --------------------------------- | ------------------------------------------------------------ |
| `GMP_VERSION`           | `gmp-6.1.0`                       |                                                              |
| `PPL_VERSION`           | `1.2`                             | ignored so far, since version tags in git repo are missing (last stable is used instead) |
| `MPFR_VERSION`          | `4.0.1`                           |                                                              |
| `MPC_VERSION`           | `1.1.0`                           |                                                              |
| `GMPY_VERSION`          | `gmpy2-2.1.0a1`                   |                                                              |
| `PPLPY_VERSION`         | `0.7`                             |                                                              |
| `WHEELS_PATH`           | `${SCRIPTPATH}/generated_wheels}` | folder where the generated wheels will be stored             |
| `PYTHON_ENV`            | `python3`                         | not available when using `pplpy_virtualenv_wheel_builder.sh` |
| `PYTHON_PIP`            | `pip3`                            | not available when using `pplpy_virtualenv_wheel_builder.sh` |
| ` PYTHON_MAJOR_VERSION` | `3`                               | only used for searching for virtualenv binary (should only be overwritten two `2` if virtualenv binary only exists as `virtualenv-2`, at least not the case on ubuntu and fedora) |

* so as an example: for using pplpy in version `0.6` just run

  ```bash
  export PPLPY_VERSION=0.6
  ```

  before running [pplpy_wheel_builder.sh](pplpy_wheel_builder.sh) or [pplpy_virtualenv_wheel_builder.sh](pplpy_virtualenv_wheel_builder.sh)



## Troubleshooting

* if the script responds`error : _ssl.c:510: EOF occurred in violation of protocol`  during the installation of GMP, then there is an unpatched Bug in the `hg` command of [mercurial](https://www.mercurial-scm.org/) (happens on Ubuntu 14.04). A workaround is either to install a newer version manually or [download](https://gmplib.org/) GMP and then compile it manually by running the following commands inside the extracted folder:

  ```bash
  ./configure --prefix=`realpath ~/local` --enable-cxx --enable-fat
  make -j4
  make install
  ```

  then you can run the script [pplpy_wheel_builder.sh](pplpy_wheel_builder.sh) again and it will detect that gmp is already installed

* older Versions of Python (e.g. Python3.4) need older Versions of the libssl-header. You can install them on ubuntu with:

  ```bash
  sudo apt install libssl1.0-dev
  ```




