# -*- Makefile -*-

#
# Generic setup file for GNU gfortran on Ubuntu
#
# Needs the Ubuntu packages: gfortran libblas-dev liblapacke-dev


# The Makefile assumes the standard bin, include and lib directories for instaled libraries,
# i.e. if SOMEDIR = /path/to/library, the make file will define the two dirs if not given:
#   SOMEINC ?= SOMEDIR/include
#   SOMELIB ?= SOMEDIR/lib
# It also looks for SOMEFLAG and SOMEDEF for library linker and CPP flags, resp.

# LICENSE
#    This file is part of the JAMS makefile project.
#
#    The JAMS makefile project is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Lesser General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    The JAMS makefile project is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#    GNU Lesser General Public License for more details.
#
#    You should have received a copy of the GNU Lesser General Public License
#    along with the JAMS makefile project. If not, see <http://www.gnu.org/licenses/>.
#
#    Copyright 2012-2019 Matthias Cuntz

# Paths
GNUDIR := /usr/
GNULIB := $(GNUDIR)/lib
GNUBIN := $(GNUDIR)/bin

# Compiling
F90 := $(GNUBIN)/gfortran
FC  := $(F90)
CC  := $(GNUBIN)/gcc
CPP := /usr/bin/cpp
# GNU Fortran version >= 4.4
ifeq ($(release),debug)
    F90FLAGS += -pedantic-errors -Wall -W -O -g -Wno-maybe-uninitialized # -ffpe-trap=invalid,zero,overflow,underflow,inexact,denormal
    FCFLAGS  += -pedantic-errors -Wall -W -O -g -Wno-maybe-uninitialized # -ffpe-trap=invalid,zero,overflow,underflow,inexact,denormal
    CFLAGS   += -pedantic -Wall -W -O -g -Wno-uninitialized # -ffpe-trap=invalid,zero,overflow,underflow,inexact,denormal
else
    F90FLAGS += -O3 -Wno-aggressive-loop-optimizations
    FCFLAGS  += -O3 -Wno-aggressive-loop-optimizations
    CFLAGS   += -O3
endif
F90FLAGS += -cpp -ffree-form -ffixed-line-length-132
FCFLAGS  += -ffixed-form -ffixed-line-length-132
CFLAGS   +=
MODFLAG  := -J# space significant
DEFINES  += -DGFORTRAN -DgFortran
# OpenMP
F90OMPFLAG := -fopenmp
FCOMPFLAG  := -fopenmp
COMPFLAG   := -fopenmp
LDOMPFLAG  := -fopenmp
OMPDEFINE  := -DOPENMP

# Linking
LIBS  += -L$(GNULIB)
RPATH += -Wl,-rpath,$(GNULIB)

# MKL
INTEL  :=
MKLDIR := # $(INTEL)/mkl
MKLINC := # $(MKLDIR)/include/intel64/lp64
MKLLIB := # $(MKLDIR)/lib/intel64
ifeq ($(openmp),true)
    MKLFLAG := -lmkl_intel_lp64 -lmkl_core -lmkl_intel_thread
else
    MKLFLAG := -lmkl_intel_lp64 -lmkl_core -lmkl_sequential
endif
MKLDEF := -DMKL
INTELLIB  := # $(INTEL)/compiler/lib/intel64
MKL95DIR  :=
MKL95FLAG := # -lmkl_blas95_lp64 -lmkl_lapack95_lp64
MKL95DEF  := # -DMKL95

# NETCDF
ifeq ($(netcdf),netcdf3)
    NCDIR  :=
    NCFLAG := -lnetcdff -lnetcdf
    NCDEF  := -DNETCDF -DNETCDF3
else
    NCDIR    :=
    NCFLAG   := -lnetcdf
    NCDEF    := -DNETCDF
    NCFDIR   :=
    NCFFLAG  := -lnetcdff
    HDF5LIB  :=
    HDF5FLAG := -lhdf5_hl -lhdf5
    SZLIB    :=
    SZFLAG   := -lsz
    ZLIB     :=
    ZFLAG    := -lz
endif

# PROJ
PROJ4DIR  :=
PROJ4FLAG := -lproj
FPROJDIR  :=
FPROJFLAG := # -lfproj4 $(FPROJLIB)/proj4.o
FPROJDEF  := # -DFPROJ

# LAPACK
LAPACKDIR  := /usr
LAPACKFLAG := -lblas -llapack
LAPACKDEF  := -DLAPACK

# MPI
OPENMPIDIR :=
OPENMPIDEF := -DMPI

# Documentation
DOXYGENDIR :=
DOTDIR     :=
TEXDIR     := /usr/bin
PERLDIR    := /usr/bin
