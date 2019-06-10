
# This is the JAMS Makefile project for Fortran, C, C++, and mixed projects.

The project provides a portable, versatile way of compiling Fortran, C, C++, and mixed projects.  
cfortran.h can be used for Fortran-C interoperability.  

Created November 2011 by Matthias Cuntz  
while at the Department Computational Hydrosystems, Helmholtz Centre
for Environmental Research - UFZ, Permoserstr. 15, 04318 Leipzig, Germany

It is distributed under the MIT License (see LICENSE file and below).

Copyright (c) 2011-2019 Matthias Cuntz - mc (at) macu (dot) de


---------------------------------------------------------------

### Description

Compiling a program from source code is an elaborate process. The compiler has to find all
source files, of course. It has to know all dependencies between the source files. For C programs,
it has to find all the header (.h) files. For Fortran programs, it has to find the module (.mod)
files, which are produced by the compiler itself, which means that the files have to be compiled
in a certain order. Last but not least, the compiler and linker have to find external libraries
and use appropriate compiler options.

Different solutions exist for this problem, the two most prominent being GNU's configure and
Kitware's CMake. One amost always has to give non-standard directories on
the command line, e.g.

    configure --with-netcdf=/path/to/netcdf
    cmake -DCMAKE_NETCDF_DIR:STRING=/path/to/netcdf

Therefore, one has to know all installation directories, configure and cmake options, etc. for the
current computer (system), or load the appropriate, matching modules, which is tedious if you or a
team work on several computers such as your local computer for development and one or two clusters
or supercomputers for production. This can be externalised in CMake by giving a script with -C or
-P once all information was gathered. 

This Makefile project follows a similar idea that the information about the current computer (system)
must only be gathered once and stored in a config file. The user can then easily compile the same code
on different computer (systems) with different compilers in debug or release mode, by simply
telling on the command line:

    make system=mcinra compiler=gnu release=debug

This uses the system specific files _mcinra.alias_ to look for the default GNU compiler, which is
version 6.1 in this case and then uses all variables set in the file _mcinra.gnu61_. The user has
to provide _mcinra.alias_ and _mcinra.gnu61_ populated with the directories and specific compiler
options for the GNU compiler suite 6.1 on the macOS system _mcinra_. Checking the same code with
another compiler would be (given _mcinra.intel_ exists):

    make system=mcinra compiler=intel release=debug

After checking with debug compiler options, one can simply compile the release version of the program by typing:

    make system=mcinra compiler=intel release=release

Once _mcinra.alias_ and _mcinra.gnu61_  are setup, they can be reused for every other project on the computer (system) _mcinra_.

The project includes examples for different operating systems, i.e. Unix (e.g. _pearcey_),
Linux (e.g. _explor_), macOS (e.g. _mcinra_), and Windows (e.g. _uwin_). The system _mcinra_
provides examples for different compilers, i.e. the GNU compiler suite, the Intel compiler suite,
the NAG Fortran compiler, and the PGI Fortran compiler.

The project provides some standard configurations for the GNU compiler suite such as
_homebrew_ on macOS, _ubuntu_ on Linux, and _cygwin_ and ubuntu (_uwin_) on Windows.


---------------------------------------------------------------

### How to use

The library is maintained with a git repository at:

    https://github.com/mcuntz/jams_makefile/

To use it, checkout the git repository:

    git clone https://github.com/mcuntz/jams_python.git

Open the file _Makefile_ and make the proper settings for your source code
(compiler, release, netcdf, openmp, mpi, lapack, etc.). Read the header of the _Makefile_ for targets, etc.
_make info_ gives detailed information. Then run _make_:

    make

You can give most makefile switches on the command line as well because they are simply variables, e.g.:

    make system=mcair compiler=gnu netcdf=netcdf4

You might have to setup your computer (system) and compilers first
(see below). You might also use some generic setups with the GNU
compiler suite such as _homebrew_ on macOS (everything in /usr/local), _ubuntu_ on Linux
(/usr), and _cygwin_ and ubuntu (_uwin_) on Windows (/usr).


---------------------------------------------------------------

### Notes

1. The makefile provides dependency generation using the Python script
   _make.config/make.d.py_. Dependency generation must be done in serial. Parallel make (-j) does
   hence not work from scratch.  
  One can split dependency generation and compilation by first calling make with a dummy target,
      which creates all dependencies, and then second calling parallel make with the -j switch,
      i.e.:

        make      system=mcinra compiler=intel release=release  dum
        make -j 8 system=mcinra compiler=intel release=release

2. The static switch is maintained like a red-headed stepchild. Libraries might be not ordered
  correctly if static linking and --begin-group/--end-group is not supported by the linker.

3. C- and C++-file dependencies are generated with:

        $(CC) -E $(DEFINES) -MM


---------------------------------------------------------------

### Example

Mixed project with Fortran and C code using revision system git, and is used on different
computer systems. The Fortran code is in the subdirectory _src/fortran_ and the C code in _src/c_.

- Copy file _Makefile_ and directory _make.config_ into project home.

- Edit _Makefile_ giving the directories with the source files, a sensible PROGNAME, and setting
  appropriate libraries such as netcdf, openmp and/or mpi:

        SRCPATH := src/fortran src/c
        PROGNAME := myproject
		netcdf := netcdf4
		lapack := true

- Debug project on computer with system with name, for example, _mcinra_:

        make system=mcinra compiler=gnu release=debug   &&   ./myproject

- Added new _use module, only: func_ in one of the Fortran source files: one has to re-generate
  dependencies first:

        make system=mcinra compiler=gnu release=debug   depend
        make system=mcinra compiler=gnu release=debug   &&   ./myproject

- Debug further with other compilers:

        make system=mcinra compiler=intel release=debug   &&   ./myproject

        make system=mcinra compiler=nag release=debug   &&   ./myproject

- Produce fast release version:

        make system=mcinra compiler=intel release=release   &&   ./myproject

- Clean the project and commit everything to revision system (use target _cleanclean_ to clean
 builds with several compilers or debug and release code; target _clean_ removes only code from
 current compiler and build):

        make system=mcinra compiler=intel release=release cleanclean
        git add Makefile make.config
        git commit -a -m "Debugged project with different compilers"
        git push

- Checkout the project on deployment machine, for example, _explor_:

        git clone https://github.com/mcuntz/project.git
        cd project
        make system=explor compiler=intel release=release

- Run the program.

        qsub submit_myproject.sh

Note, for faster parallel builds, the above make commands, e.g.

    make system=explor compiler=intel release=release

can be split in two (see Note 1), which is expedient for large code bases:

    make      system=explor compiler=intel release=release   dum
    make -j 8 system=explor compiler=intel release=release


---------------------------------------------------------------

### How to add a new compiler on a given system

As an example, one wants to add the PGI compiler suite version 8.5 on
the system _eve_.  
Choose the compiler abbreviation _pgi85_, i.e. leading to _system=eve compiler=pgi85_.

1. Create a config file in _make.config/_ with the name _eve.pgi85_.  
 One can copy an existing file and adapt it to the new compiler.  
 Take a compiler close to the new one, e.g. _eve.pgi83_.  
 If there is none, take _eve.gnu48_ on a Linux system and _mcinra.gnu61_ on macOS as good starting
 points.
2. Adapt the directories and compiler switches in the config file.
3. If wanted, you can give aliases for that compiler, e.g. simply _pgi_ instead of the name
 including the version number _pgi85_.  
 Edit _eve.alias_, follow the examples of _pgfortran_ or _intel_.


### How to port the Makefile to a new computer (system)

As an example, one wants to port the Makefile onto a new system called _Liclus_
on which exists a GNU compiler version 4.7, i.e. leading to _system=liclus compiler=gnu47_.

1. Create a config file in _make.config/_ with the name _liclus.gnu47_.  
 One can copy an existing file of a similar system and a similar compiler.  
 For example if Liclus is macOS, then mcinra.gnu61 might be a good start and if Liclus is Linux
 then eve.gnu48 might give a head start.
2. Adapt the directories and compiler switches in the config file.
3. One can give aliases for that compiler, e.g. simply _gnu_ instead of the name
 including the version number _gnu47_.  
 Therefore a file _liclus.alias_ is needed. Create it in _make.config/_;  even an empty one is
 possible if no aliases are wanted. One can copy _eve.alias_ or _mcinra.alias_ for examples.


---------------------------------------------------------------

###  License

This file is part of the JAMS Makefile system, distributed under the MIT License.

Copyright (c) 2011-2019 Matthias Cuntz - mc (at) macu (dot) de

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
