# PPLPY WHEEL BUILDER

this script generates three precompiled wheels: 
* One for pplpy 
* One containing the libraries pplpy depends on
* One for gmpy2 

Currently it only runs on debian based distributions because it's using `apt` to install the build dependencies *(but porting this to other distros should be easy)*

### Prerequisites

* just a fresh Ubuntu installation (currently only tested on 16.04 LTS, but it should run also on newer versions)

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

