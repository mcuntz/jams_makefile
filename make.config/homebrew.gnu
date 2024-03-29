# -*- Makefile -*-

#
# Setup file for GNU compiler installed with homebrew (http://brew.sh) on macOS
#
# This file is part of the JAMS Makefile system, distributed under the MIT License.
#
# Copyright (c) 2011-2022 Matthias Cuntz - mc (at) macu (dot) de
#

# Paths
BREWDIR := $(shell if [[ -d /opt/homebrew ]] ; then echo '/opt/homebrew' ; else echo '/usr/local' ; fi)

GNUDIR := $(BREWDIR)
GNULIB := $(GNUDIR)/lib
GNUBIN := $(GNUDIR)/bin

# Compiling
F90 := $(GNUBIN)/gfortran
FC  := $(F90)
CC  := /usr/bin/cc  # clang, same as /usr/bin/gcc
CPP := /usr/bin/cpp # could be 'gcc -E -cpp' on Linux but does not work on Mac
ifeq ($(release),debug)
    F90FLAGS += -pedantic-errors -Wall -W -O -g -Wno-maybe-uninitialized # -ffpe-trap=invalid,zero,overflow,underflow,inexact,denormal
    FCFLAGS  += -pedantic-errors -Wall -W -O -g -Wno-maybe-uninitialized # -ffpe-trap=invalid,zero,overflow,underflow,inexact,denormal
    CFLAGS   += -pedantic -Wall -W -O -g -Wno-uninitialized # -ffpe-trap=invalid,zero,overflow,underflow,inexact,denormal
else
    F90FLAGS += -O3 -Wno-aggressive-loop-optimizations
    FCFLAGS  += -O3 -Wno-aggressive-loop-optimizations
    CFLAGS   += -O3
endif
F90FLAGS += -cpp -ffree-form -ffixed-line-length-132 # -ffree-line-length-none
FCFLAGS  += -ffixed-form -ffixed-line-length-132 # -ffree-line-length-none
CFLAGS   +=
MODFLAG  := -J# space significant
DEFINES  += -D__GFORTRAN__ -D__gFortran__
# OpenMP
F90OMPFLAG := -fopenmp
FCOMPFLAG  := -fopenmp
COMPFLAG   := -fopenmp
LDOMPFLAG  := -fopenmp
OMPDEFINE  := -D__OPENMP__

# Linking
LIBS  += -L$(GNULIB)
RPATH += -Wl,-rpath,$(GNULIB)

# IMSL
IMSLDIR  :=
IMSLFLAG := #-limsl -limslscalar -limsllapack -limslblas -limsls_err -limslmpistub -limslsuperlu
IMSLDEF  := #-D__IMSL__

# MKL
INTEL  :=
MKLDIR := # $(INTEL)/mkl
ifeq ($(openmp),true)
    MKLFLAG := -lmkl_intel_lp64 -lmkl_core -lmkl_intel_thread #-lpthread
else
    MKLFLAG := -lmkl_intel_lp64 -lmkl_core -lmkl_sequential #-lpthread
endif
MKLDEF := -D__MKL__
MKL95DIR  :=
MKL95LIB  := # $(MKL95DIR)/lib
MKL95INC  := # $(MKL95DIR)/include/intel64/lp64
MKL95FLAG := -lmkl_lapack95_lp64
MKL95DEF  := -D__MKL95__

# NETCDF
ifeq ($(netcdf),netcdf3)
    NCDIR  :=
    NCFLAG := -lnetcdff -lnetcdf
    NCDEF  := -D__NETCDF__ -D__NETCDF3__
else
    NCDIR    := $(BREWDIR)
    NCFLAG   := -lnetcdf
    NCDEF    := -D__NETCDF__
    NCFDIR   :=
    NCFFLAG  := -lnetcdff
    HDF5LIB  := $(BREWDIR)/lib
    HDF5FLAG := -lhdf5_hl -lhdf5
    SZLIB    := $(BREWDIR)/lib
    SZFLAG   := -lsz
    CURLLIB  := /usr/lib
    CURLFLAG := -lcurl
    ZFLAG    := -lz
endif

# PROJ
PROJ4DIR  := $(BREWDIR)
PROJ4FLAG := -lproj
FPROJDIR  :=
FPROJLIB  :=
FPROJFLAG := #-lfproj4 $(FPROJLIB)/proj4.o
FPROJDEF  := #-D__FPROJ__

# LAPACK
LAPACKDIR  :=
LAPACKFLAG := -framework Accelerate
LAPACKDEF  := -D__LAPACK__

# MPI
OPENMPIDIR  :=
OPENMPIDEF  := -D__MPI__

# Documentation
DOXYGENDIR :=
DOTDIR     := $(BREWDIR)/bin
TEXDIR     := /Library/TeX/texbin
PERLDIR    := /usr/bin
