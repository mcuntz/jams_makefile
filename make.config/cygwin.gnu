# -*- Makefile -*-

#
# Setup file for GNU compiler on cygwin on Windows
#
# This file is part of the JAMS Makefile system, distributed under the MIT License.
#
# Copyright (c) 2011-2019 Matthias Cuntz - mc (at) macu (dot) de
#

# Paths
GNUDIR := /usr
GNULIB := $(GNUDIR)/lib
GNUBIN := $(GNUDIR)/bin

# Compiling
F90 := $(GNUBIN)/gfortran
FC  := $(F90)
CC  := $(GNUBIN)/gcc
CPP := /usr/bin/cpp
# GNU Fortran version >= 4.4
ifeq ($(release),debug)
    F90FLAGS += -pedantic-errors -Wall -W -O -g -Wno-maybe-uninitialized
    FCFLAGS  += -pedantic-errors -Wall -W -O -g -Wno-maybe-uninitialized
    CFLAGS   += -pedantic -Wall -W -O -g -Wno-maybe-uninitialized
else
    F90FLAGS += -O3
    FCFLAGS  += -O3
    CFLAGS   += -O3
endif
F90FLAGS += -cpp -ffree-form -ffixed-line-length-132
FCFLAGS  += -ffixed-form -ffixed-line-length-132 -x f77-cpp-input
CFLAGS   +=
MODFLAG  := -J# space significant
DEFINES  += -D__GFORTRAN__ -D__gFortran__ -D__CYGWIN__
# LDFLAGS  += -L$(GNULIB) -lgfortran -Wl,-rpath,$(GNULIB)
# OpenMP
F90OMPFLAG := -fopenmp
FCOMPFLAG  := -fopenmp
COMPFLAG   := -fopenmp
LDOMPFLAG  := -fopenmp
OMPDEFINE  := -D__OPENMP__

# Linking
LIBS  += -L$(GNULIB)
RPATH += -Wl,-rpath,$(GNULIB)

# NETCDF
ifeq ($(netcdf),netcdf3)
    NCDIR  := /usr/local/netcdf/3.6.3_gcc46
    NCFLAG := -lnetcdff -lnetcdf
    NCDEF  := -D__NETCDF__ -D__NETCDF3__
else
    NCDIR    := /usr
    NCFLAG   := -lnetcdf
    NCDEF    := -D__NETCDF__
    NCFDIR   := /usr
    NCFFLAG  := -lnetcdff
    HDF5LIB  := /usr/lib
    HDF5FLAG := -lhdf5_hl -lhdf5
endif

# LAPACK
LAPACKDIR  := /usr/lib
LAPACKLIB  := $(LAPACKDIR)/lapack
LAPACKFLAG := -lblas -llapack
LAPACKDEF  := -D__LAPACK__

# Documentation
DOXYGENDIR := /usr/bin
DOTDIR     := /usr/bin
TEXDIR     := /usr/bin
PERLDIR    := /usr/bin
