
# This is the Makefile project for Fortran, C and mixed projects of JAMS.

Created 11.11.2011 by Matthias Cuntz at the  
Department Computational Hydrosystems  
Helmholtz Centre for Environmental Research - UFZ  
Permoserstr. 15, 04318 Leipzig, Germany

Copyright 2011-2016 JAMS  
Contact Matthias Cuntz - mc (at) macu.de

---------------------------------------------------------------

The project tries to provide a portable, versatile way of compiling Fortran, C and mixed projects.
cfortran.h can be used for Fortran-C interoperability.  
It is released under the GNU Lesser General Public License (see below).

The library is maintained as a git repository on bitbucket:

    https://bitbucket.org/mcuntz/jams_makefile

---------------------------------------------------------------

## License

This file is part of the JAMS makefile project.

The JAMS makefile project is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The JAMS makefile project is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
details.

You should have received a copy of the GNU Lesser General Public License
along with the JAMS makefile project (cf. gpl.txt and lgpl.txt).
If not, see <http://www.gnu.org/licenses/>.

Copyright 2011-2016 Matthias Cuntz

---------------------------------------------------------------

## How to use the makefile
You have to checkout the Makefile and the directory make.config/.

Open the file 'Makefile' and make the proper settings for your source code
(select compiler, release, netcdf, openmp, mpi, lapack, etc.).

Read the header of the makefile for targets, etc.
'make info' gives detailed information.

You can give most makefile switches on the command line as well, eg.

    make system=mcair compiler=gnu openmp=true


## How to add a new compiler on a given system

As an example, one wants to add the PGI compiler suite version 8.5 on
the system eve2.  
Choose the compiler abbreviation pgi85, i.e. leading to system=eve2, compiler=pgi85

1. Create a config file in make.config/ with the name eve2.pgi85  
   One can copy an existing file and adapt it to the new compiler.  
   Take a compiler close to the new one, e.g. eve2.pgi83.  
   If there is none, take eve2.intel13 or eve2.gnu48 on a Linux system and
   mcair.gnu49 on a Mac as good starting points.
2. Adapt the pathes and compiler switches in the config file.
3. If wanted, you can give aliases for that compiler, e.g. simply 'pgi' instead of
   also the version number 'pgi85'. Edit eve2.alias, follow the examples of sun or nag.


## How to port the Makefile to a new system

As an example, one wants to port the Makefile onto a new system called 'Liclus'
on which exists a gnu compiler version 4.7, i.e. leading to system=liclus, compiler=gnu47.

1. Create a config file in make.config/ with the name liclus.gnu47  
   One can copy an existing file of a similar system and a similar
   compiler.  
   For example if Liclus is Mac OS X, then mcair.gnu49 might be a good start and
   if Liclus is Linux then eve2.gnu48 might give a head start.
2. Adapt the pathes and compiler switches in the config file.
3. One can give aliases for that compiler, e.g. simply 'gnu' instead
   of also the version number 'gnu47'.  
   Therefore a file liclus.alias is needed. Create it in make.config/;
   even an empty is possible if no alias is wanted. One can copy eve2.alias for examples.