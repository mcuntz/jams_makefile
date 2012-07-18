# -*- Makefile -*-
#
# PURPOSE
#     Makefile for CHS projects
#
# CALLING SEQUENCE
#     make [options] [VARIABLE=VARIABLE ...] [targets]
#
#     Variables can be set on the command line [VAR=VAR] or in the SWITCHES section in this file.
#
# INPUTS
#     targets    all (default), check (=test), clean, cleanclean, cleancheck (=cleantest), html
#
# OPTIONS
#     All make options such as -f makefile. See 'man make'.
#
# VARIABLES
#     All variables defined in this makefile.
#     This makefile has lots of conditional statements depending on variables.
#     If the variable functions as a switch then the condition checks for variable = true,
#     otherwise the variable can have different values.
#     See individual variables in SWITCHES section below.
#
#     Variables can be empty for disabling a certain behaviour,
#     e.g. if you do not want to use IMSL, set:  imsl=no  or  imsl=
#
#     Current variables are
#         system      eve, mcimac, mcpowerbook, mcair, jmmacbookpro, gdmacbookpro
#         release     debug, release
#         netcdf      netcdf3, netcdf4
#         static      static, shared, dynamic (last two are equal)
#         proj        true, [anything else]
#         imsl        vendor, imsl, [anything else]
#         mkl         mkl, mkl95, [anything else]
#         lapack      true, [anything else]
#         compiler    intel11, intel12, gnu41, gnu42, gnu44, gnu45, gnu46, absoft, nag51, nag52, nag53, sun12
#                     alternative names are:
#                     On eve.ufz.de
#                       gnu, gfortran, gcc=gnu44
#                       gfortran41, gcc41=gnu41
#                       gfortran44, gcc44=gnu44
#                       gfortran45, gcc45=gnu45
#                       gfortran46, gcc46=gnu46
#                       intel, ifort, ifort11=intel11
#                       ifort12=intel12
#                       sun=sun12
#                       nag=nag53
#                     On Matthias' Macbook Air
#                       gnu, gfortran, gcc, gfortran46, gcc44=gnu46
#                     On Matthias' iMac
#                       gnu, gfortran, gcc, gfortran45, gcc44=gnu45
#                       intel, ifort, ifort12=intel12
#                       nag=nag52 nag53
#                     On Matthias' Powerbook
#                       gnu, gfortran, gcc, gfortran42, gcc42=gnu42 for mcpowerbook
#                       nag=nag52 nag53
#                     On Jule's MacBook Pro
#                       gnu, gfortran, gcc, gfortran46=gcc46
#                     On Stephan's Desktop
#                       ifort=intel12
#                     On Stephan's Laptop
#                       ifort=intel12
#         openmp      true, [anything else]
#
# DEPENDENCIES
#    This make file uses the following files:
#        $(MAKEDPATH)/make.d.pl, $(CONFIGPATH)/$(system).$(compiler)
#    The default $(MAKEDPATH) and $(CONFIGPATH) is make.config
#
# RESTRICTIONS
#    Not all packages work with or are compiled for all compilers.
#    The script does check some but not all of these dependencies.
#
# EXAMPLE
#    make release=debug compiler=intel11 imsl=vendor mkl=mkl95
#
# LITERATURE
#    The following links provide general documentation:
#        Make
#          GNU           http://www.gnu.org/s/make/
#        Compiler
#          GFORTRAN      http://gcc.gnu.org/fortran/
#          INTEL         http://software.intel.com/en-us/articles/intel-composer-xe/
#          NAG           http://www.nag.co.uk/nagware/np.asp
#                        http://www.nag.co.uk/nagware/np/doc_index.asp
#          ABSOFT        http://www.absoft.com/Support/Documentation/fortran_documentation.html
#        Libraries
#          MKL           http://software.intel.com/en-us/articles/intel-mkl/
#          IMSL          http://www.roguewave.com/products/imsl-numerical-libraries.aspx
#          NETCDF        http://www.unidata.ucar.edu/software/netcdf/
#          PROJ4         http://trac.osgeo.org/proj/
#          LAPACK        http://www.netlib.org/lapack/
#
# LICENSE
#    This file is part of the UFZ makefile project.
#
#    The UFZ makefile project is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Lesser General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    The UFZ makefile project is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#    GNU Lesser General Public License for more details.
#
#    You should have received a copy of the GNU Lesser General Public License
#    along with the UFZ makefile project. If not, see <http://www.gnu.org/licenses/>.
#
#    Copyright 2011-2012 Matthias Cuntz, Juliane Mai, Stephan Thober
#
# Written Matthias Cuntz & Juliane Mai, UFZ Leipzig, Germany, Aug. 2011 - matthias.cuntz@ufz.de

SHELL = /bin/bash

#
# --- SWITCHES -------------------------------------------------------
#

# . is current directory, .. is parent directory
SRCPATH    := test_cfortran         # where are the source files; use test_??? to run a test directory
PROGPATH   := .           # where shall be the executable
CONFIGPATH := make.config # where are the $(system).$(compiler) files
MAKEDPATH  := make.config # where is the make.d.pl script
TESTPATH   := .
#
PROGNAME := Prog # Name of executable
#
# Options
# Systems: eve, mcimac, mcpowerbook, mcair, jmmacbookpro, gdmacbookpro, stdesk, stubuntu
system   := stdesk
# Releases: debug, release
release  := debug
# Netcdf versions (Network Common Data Form): netcdf3, netcdf4
netcdf   := 
# Linking: static, shared, dynamic (last two are equal)
static   := shared
# Proj4 (Cartographic Projections Library): true, [anything else]
proj     :=
# IMSL (IMSL Numerical Libraries): vendor, imsl, [anything else]
imsl     :=
# MKL (Intel's Math Kernel Library): mkl, mkl95, [anything else]
mkl      :=
# LAPACK (Linear Algebra Pack): true, [anything else]
lapack   :=
# Compiler: intel11, intel12, gnu41, gnu42, gnu44, gnu45, gnu46, absoft, nag51, nag52, nag53, sun12
compiler := intel12
# OpenMP parallelization: true, [anything else]
openmp   :=

# Write out warning/reminder if compiled on Mac OS X. If NOMACWARN=true then no warning is written out: true, [anything else]
NOMACWARN = no

# This Makefile sets the following variables depending on the above options:
# FC, FCFLAGS, F90FLAGS, DEFINES, INCLUDES, LD, LDFLAGS, LIBS
# flags, defines, etc. will be set incremental. They will be initialised with
# the following EXTRA_* variables. This allows for example to set an extra compiler
# option or define a preprocessor variable such as: EXTRA_DEFINES := -DNOGUI
EXTRA_FCFLAGS  :=
EXTRA_F90FLAGS :=
EXTRA_DEFINES  :=
EXTRA_INCLUDES :=
EXTRA_LDFLAGS  :=
EXTRA_LIBS     :=
EXTRA_CFLAGS   :=

#
# --- ALIASES ---------------------------------------------------
#

# Set aliases so that one can, for example, say ifort to invoke standard intel11 on eve
icompiler := $(compiler)
ifeq ($(system),eve)
    ifneq (,$(findstring $(compiler),gnu gfortran gcc))
        icompiler := gnu44
    endif
    ifneq (,$(findstring $(compiler),gfortran41 gcc41))
        icompiler := gnu41
    endif
    ifneq (,$(findstring $(compiler),gfortran41 gcc44))
        icompiler := gnu44
    endif
    ifneq (,$(findstring $(compiler),gfortran45 gcc45))
        icompiler := gnu45
    endif
    ifneq (,$(findstring $(compiler),gfortran46 gcc46))
        icompiler := gnu46
    endif
    ifneq (,$(findstring $(compiler),intel ifort ifort11))
        icompiler := intel11
    endif
    ifeq ($(compiler),ifort12)
        icompiler := intel12
    endif
    ifneq (,$(findstring $(compiler),sun))
        icompiler := sun12
    endif
    ifneq (,$(findstring $(compiler),nag))
        icompiler := nag53
    endif
endif
ifeq ($(system),mcimac)
    ifneq (,$(findstring $(compiler),gnu gfortran gcc gfortran45 gcc45))
        icompiler := gnu45
    endif
    ifneq (,$(findstring $(compiler),intel ifort ifort12))
        icompiler := intel12
    endif
    ifneq (,$(findstring $(compiler),nag nag52 nag53))
        icompiler := nag53
    endif
endif
ifeq ($(system),mcpowerbook)
    ifneq (,$(findstring $(compiler),gnu gfortran gcc gfortran42 gcc42))
        icompiler := gnu42
    endif
    ifneq (,$(findstring $(compiler),nag nag52 nag53))
        icompiler := nag53
    endif
endif
ifeq ($(system),mcair)
    ifneq (,$(findstring $(compiler),gnu gfortran gcc gfortran46 gcc46))
        icompiler := gnu46
    endif
    ifneq (,$(findstring $(compiler),nag nag52 nag53))
        icompiler := nag53
    endif
endif
ifeq ($(system),jmmacbookpro)
    ifneq (,$(findstring $(compiler),gnu gfortran gcc gfortran46 gcc46))
        icompiler := gnu46
    endif
#    ifneq (,$(findstring $(compiler),nag nag52 nag53))
#        icompiler := nag53
#    endif
endif
ifeq ($(system),gdmacbookpro)
    ifneq (,$(findstring $(compiler),gnu gfortran gcc gfortran46 gcc46))
        icompiler := gnu46
    endif
#    ifneq (,$(findstring $(compiler),nag nag52 nag53))
#        icompiler := nag53
#    endif
endif
ifeq ($(system),stdesk)
    ifneq (,$(findstring $(compiler),intel12))
        icompiler := intel12
    endif
endif
ifeq ($(system),stubuntu)
    ifneq (,$(findstring $(compiler),intel12))
        icompiler := intel12
    endif
endif

#
# --- CHECKS ---------------------------------------------------
#

# Check some dependices, e.g. IMSL needs intel11 on eve
ifeq (,$(findstring $(system),eve mcimac mcpowerbook mcair jmmacbookpro gdmacbookpro stdesk stubuntu))
    $(error Error: system '$(system)' not found: must be in 'eve mcimac mcpowerbook mcair jmmacbookpro gdmacbookpro stdesk stubuntu')
endif

ifeq (,$(findstring $(release),debug release))
    $(error Error: release '$(release)' not found: must be in 'debug release')
endif

ifneq ($(netcdf),)
    ifeq (,$(findstring $(netcdf),netcdf3 netcdf4))
        $(error Error: netcdf '$(netcdf)' not found: must be in 'netcdf3 netcdf4')
    endif
endif

ifeq (,$(findstring $(static),static shared dynamic))
    $(error Error: static '$(static)' not found: must be in 'static shared dynamic')
endif

ifneq (,$(findstring $(system),eve))
    ifneq (,$(findstring $(imsl),vendor imsl))
        ifneq ($(icompiler),intel11)
            $(error Error: IMSL needs intel11.0.075, set 'compiler=intel11')
        endif
        ifeq ($(imsl),vendor)
            ifeq (,$(findstring $(mkl),mkl mkl95))
                $(error Error: IMSL vendor needs MKL, set 'mkl=mkl' or 'mkl=mkl95')
            endif
        endif
    endif
endif

ifeq (,$(findstring $(icompiler),intel11 intel12 gnu41 gnu42 gnu44 gnu45 gnu46 absoft nag51 nag52 nag53 sun12))
    $(error Error: compiler '$(icompiler)' not found: must be in 'intel11 intel12 gnu41 gnu42 gnu44 gnu45 gnu46 absoft nag51 nag52 nag53 sun12')
endif

#
# --- PATHS ------------------------------------------------
#

# Make absolute pathes from relative pathes
ifeq ($(findstring //,/$(PROGPATH:~%=/%)),)         # starts not with / or ~
    ifeq ($(findstring '/.',/$(PROGPATH)),)       # starts not with .
        PROG := $(CURDIR)/$(strip $(PROGPATH))/$(strip $(PROGNAME))
    else                                        # starts with .
	ifeq ($(subst ./,,$(dir $(PROGPATH))),) # is just .
            PROG := $(CURDIR)/$(strip $(PROGNAME))
        else                                    # is ./etc
            PROG := $(CURDIR)/$(strip $(subst ./,,$(dir $(PROGPATH))))/$(strip $(PROGNAME))
        endif
    endif
else                                            # starts with /
    PROG := $(strip $(PROGPATH:~%=${HOME}%))/$(strip $(PROGNAME))
endif

ifeq ($(findstring //,/$(MAKEDPATH:~%=/%)),)
    ifeq ($(findstring '/.',/$(MAKEDPATH)),)
        MAKEDEPSPROG := $(CURDIR)/$(strip $(MAKEDPATH))/make.d.pl
    else
	ifeq ($(subst ./,,$(dir $(MAKEDPATH))),)
            MAKEDEPSPROG := $(CURDIR)/make.d.pl
        else
            MAKEDEPSPROG := $(CURDIR)/$(strip $(subst ./,,$(dir $(MAKEDPATH))))/make.d.pl
        endif
    endif
else
    MAKEDEPSPROG := $(strip $(MAKEDPATH:~%=${HOME}%))/make.d.pl
endif
ifneq (exists, $(shell if [ -f $(MAKEDEPSPROG) ] ; then echo 'exists' ; fi))
    $(error Error: '$(MAKEDEPSPROG)' not found.)
endif

ifeq ($(findstring //,/$(strip $(SRCPATH:~%=/%))),)
    ifeq ($(findstring '/.',/$(strip $(SRCPATH))),)
        SOURCEPATH := $(CURDIR)/$(strip $(SRCPATH))
    else
	ifeq ($(subst ./,,$(dir $(SRCPATH))),)
            SOURCEPATH := $(CURDIR)
        else
            SOURCEPATH := $(CURDIR)/$(strip $(subst ./,,$(dir $(SRCPATH))))
        endif
    endif
else
    SOURCEPATH := $(strip $(SRCPATH:~%=${HOME}%))
endif
ifneq (exists, $(shell if [ -d "$(SOURCEPATH)" ] ; then echo 'exists' ; fi))
    $(error Error: source path '$(SOURCEPATH)' not found.)
endif

# Path where all the .mod, .o, etc. files will be written
OBJPATH := $(SOURCEPATH)/.$(strip $(icompiler)).$(strip $(release))

#
# --- DEFAULTS ---------------------------------------------------
#

# These variables will be used to compile
FC       :=
FCFLAGS  := $(EXTRA_FCFLAGS)
F90      :=
F90FLAGS := $(EXTRA_F90FLAGS)
CC       :=
CFLAGS   := $(EXTRA_CFLAGS)
DEFINES  := $(EXTRA_DEFINES) -DCFORTRAN
INCLUDES := $(EXTRA_INCLUDES)
# and link, and therefore set below
LD       :=
LDFLAGS  := $(EXTRA_LDFLAGS)
LIBS     := $(EXTRA_LIBS)

#
# --- COMPILER / MACHINE SPECIFIC --------------------------------
#

# Mac OS X is special, there is (almost) no static linking
istatic := $(static)
ifneq (,$(findstring $(system),mcimac mcpowerbook mcair jmmacbookpro gdmacbookpro))
    istatic := dynamic
endif
ifeq ($(istatic),static)
    LIBS += -Bstatic -Wl,--start-group
else
    ifneq (,$(findstring $(system),mcimac mcpowerbook mcair jmmacbookpro gdmacbookpro))
        LIBS += -Wl,-dynamic
    else
        LIBS += -Bdynamic
    endif
endif

# check for openmp flag before including configuration files
ifeq ($(openmp),true)
    iopenmp = -openmp
endif

# Include the individual configuration files
MAKEINC := $(strip $(CONFIGPATH))/$(system).$(icompiler)
ifneq (exists, $(shell if [ -f $(MAKEINC) ] ; then echo 'exists' ; fi))
    $(error Error: '$(MAKEINC)' not found.)
endif
include $(MAKEINC)

# Always use -DCFORTRAN for mixed C and Fortran compilations
DEFINES  += -DCFORTRAN

# --- COMPILER ---------------------------------------------------
ifneq (,$(findstring $(icompiler),gnu41 gnu42 gnu44 gnu45 gnu46))
    ifneq (exists, $(shell if [ -d "$(GFORTRANDIR)" ] ; then echo 'exists' ; fi))
        $(error Error: GFORTRAN path '$(GFORTRANDIR)' not found.)
    endif
    GFORTRANLIB ?= $(GFORTRANDIR)/lib
    LIBS        += -L$(GFORTRANLIB) -lgfortran
    RPATH       += -Wl,-rpath,$(GFORTRANLIB)
endif

# --- OPENMP -----------------------------------------------------
ifeq ($(openmp),true)
    LDFLAGS  += -openmp
else
    ifneq (,$(findstring $(imsl),vendor imsl))
        LDFLAGS  += -openmp
    endif
endif

# --- IMSL ---------------------------------------------------
ifneq (,$(findstring $(imsl),vendor imsl))
    ifneq (exists, $(shell if [ -d "$(IMSLDIR)" ] ; then echo 'exists' ; fi))
        $(error Error: IMSL path '$(IMSLDIR)' not found.)
    endif
    IMSLINC ?= $(IMSLDIR)/include
    IMSLLIB ?= $(IMSLDIR)/lib

    INCLUDES += -I$(IMSLINC)
    DEFINES  += -DIMSL

    LIBS     += -z muldefs
    ifneq ($(istatic),static)
       LIBS += -i_dynamic
    endif

    ifeq ($(imsl),imsl)
        LIBS += -L$(IMSLLIB) -limsl -limslscalar -limsllapack_imsl -limslblas_imsl -limsls_err -limslmpistub -limslsuperlu
    else
        LIBS  += -L$(IMSLLIB) -limsl -limslscalar -limsllapack_vendor -limslblas_vendor -limsls_err -limslmpistub -limslsuperlu -limslhpc_l
    endif
    RPATH += -Wl,-rpath,$(IMSLLIB)
endif

# --- MKL ---------------------------------------------------
ifneq (,$(findstring $(mkl),mkl mkl95))
    ifeq ($(mkl),mkl95) # First mkl95 then mkl for .mod files other then intel
        ifneq (exists, $(shell if [ -d "$(MKL95DIR)" ] ; then echo 'exists' ; fi))
            $(error Error: MKL95 path '$(MKL95DIR)' not found.)
        endif
        MKL95INC ?= $(MKL95DIR)/include
        MKL95LIB ?= $(MKL95DIR)/lib

        INCLUDES += -I$(MKL95INC)
        DEFINES  += -DMKL95

        LIBS  += -L$(MKL95LIB) -lmkl_blas95_lp64 -lmkl_lapack95_lp64
        RPATH += -Wl,-rpath,$(MKL95LIB)
        ifneq ($(ABSOFT),)
            F90FLAGS += -p $(MKL95INC)
        endif
    endif

    ifneq (exists, $(shell if [ -d "$(MKLDIR)" ] ; then echo 'exists' ; fi))
        $(error Error: MKL path '$(MKLDIR)' not found.)
    endif
    MKLINC ?= $(MKLDIR)/include
    MKLLIB ?= $(MKLDIR)/lib

    INCLUDES += -I$(MKLINC)
    DEFINES  += -DMKL

    LIBS += -L$(MKLLIB) -lmkl_intel_lp64 -lmkl_core #-lpthread
    ifneq (,$(findstring $(imsl),vendor imsl))
       LIBS += -lmkl_intel_thread #-lpthread
    else
        ifeq ($(openmp),true)
            LIBS += -lmkl_intel_thread #-lpthread
        else
            LIBS += -lmkl_sequential #-lpthread
        endif
    endif
    RPATH += -Wl,-rpath,$(MKLLIB)
endif

# --- NETCDF ---------------------------------------------------
ifneq (,$(findstring $(netcdf),netcdf3 netcdf4))
    ifneq (exists, $(shell if [ -d "$(NCDIR)" ] ; then echo 'exists' ; fi))
        $(error Error: NETCDF path '$(NCDIR)' not found.)
    endif
    NCINC ?= $(strip $(NCDIR))/include
    NCLIB ?= $(strip $(NCDIR))/lib

    INCLUDES += -I$(NCINC)
    DEFINES  += -DNETCDF

    LIBS  += -L$(NCLIB)
    RPATH += -Wl,-rpath,$(NCLIB)
    ifneq ($(icompiler),absoft)
        LIBS += -lnetcdff
    endif
    LIBS  += -lnetcdf

    # other libraries for netcdf4, ignored for netcdf3
    ifeq ($(netcdf),netcdf4)
        LIBS  += -lz -L$(SZLIB) -lsz -L$(HDF5LIB) -lhdf5 -lhdf5_hl
        RPATH += -Wl,-rpath,$(SZLIB) -Wl,-rpath,$(HDF5LIB)
        ifneq ($(CURLLIB),)
            LIBS     += -L$(CURLLIB) -lcurl
            RPATH    += -Wl,-rpath,$(CURLLIB)
        endif
   endif
endif

# --- PROJ --------------------------------------------------
ifeq ($(proj),true)
    ifneq (exists, $(shell if [ -d "$(PROJ4DIR)" ] ; then echo 'exists' ; fi))
        $(error Error: PROJ4 path '$(PROJ4DIR)' not found.)
    endif
    PROJ4LIB ?= $(PROJ4DIR)/lib
    LIBS     += -L$(PROJ4LIB) -lproj
    RPATH    += -Wl,-rpath=$(PROJ4LIB)

    ifneq (exists, $(shell if [ -d "$(FPROJDIR)" ] ; then echo 'exists' ; fi))
        $(error Error: FPROJ path '$(FPROJDIR)' not found.)
    endif
    FPROJINC ?= $(FPROJDIR)/include
    FPROJLIB ?= $(FPROJDIR)/lib

    INCLUDES += -I$(FPROJINC)
    DEFINES  += -DFPROJ
    LIBS     += -L$(FPROJLIB) -lfproj4 $(FPROJLIB)/proj4.o
    RPATH    += -Wl,-rpath,$(FPROJLIB)
endif

# --- LAPACK ---------------------------------------------------
ifeq ($(lapack),true)
    # Mac OS X uses frameworks
    ifneq (,$(findstring $(system),mcimac mcpowerbook mcair jmmacbookpro gdmacbookpro))
        LIBS += -framework veclib
    else
        ifneq (exists, $(shell if [ -d "$(LAPACKDIR)" ] ; then echo 'exists' ; fi))
            $(error Error: LAPACK path '$(LAPACKDIR)' not found.)
        endif
        LAPACKLIB ?= $(LAPACKDIR)/lib
        LIBS      += -L$(LAPACKLIB) -lblas -llapack
        RPATH     += -Wl,-rpath,$(LAPACKLIB)
    endif
    DEFINES += -DLAPACK

    # Lapack on Eve needs libgfortran
    ifneq (,$(findstring $(system),eve))
        ifeq (,$(findstring $(icompiler),gnu41 gnu42 gnu44 gnu45 gnu46))
            ifneq (exists, $(shell if [ -d "$(GFORTRANDIR)" ] ; then echo 'exists' ; fi))
                $(error Error: GFORTRAN path '$(GFORTRANDIR)' not found.)
            endif
            GFORTRANLIB ?= $(GFORTRANDIR)/lib
            LIBS        += -L$(GFORTRANLIB) -lgfortran
            RPATH       += -Wl,-rpath,$(GFORTRANLIB)
        endif
    endif
endif

#
# --- FINISH SETUP ---------------------------------------------------
#

ifeq ($(release),debug)
    DEFINES += -DDEBUG
endif

# Mac OS X is special, there is (almost) no static linking
ifeq ($(istatic),static)
    LIBS += -Wl,--end-group
endif
# Only Linux and Solaris can use -rpath in executable
ifeq (,$(findstring $(system),mcimac mcpowerbook mcair jmmacbookpro gdmacbookpro))
    # The NAG compiler links via gcc so that one has to give -Wl twice and double commas for the option
    # i.e. instead of  -Wl,rpath,/path   you need   -Wl,-Wl,,rpath,,/path
    ifneq (,$(findstring $(icompiler),nag51 nag52 nag53))
        comma  := ,
        iRPATH := $(subst -Wl,-Wl$(comma)-Wl,$(subst $(comma),$(comma)$(comma),$(RPATH)))
    else
        iRPATH := $(RPATH)
    endif
    LIBS += $(iRPATH)
endif

LD := $(F90)

# ASRCS contain source dir informations
ifeq (,$(findstring $(strip $(MAKECMDGOALS)),check test clean cleanclean cleancheck cleantest html))
ASRCS     := $(wildcard $(SOURCEPATH)/*.f90)
endif
# SRCS without dir
SRCS      := $(notdir $(ASRCS))
# AOBJS objects without dir
AOBJS     := $(SRCS:.f90=.o)
# objects can be excluded, e.g. mo_test.o
EXCL      :=
# OAOBJS objects without excluded files and without dir
OAOBJS    := $(filter-out $(EXCL), $(AOBJS))
# objects with full dir path
OBJS      := $(addprefix $(OBJPATH)/, $(OAOBJS))
# dependency files with full dir path
DOBJS     := $(OBJS:.o=.d)
# g90 debug files of NAG compiler
GASRCS    := $(ASRCS:.f90=.g90)

# Same for Fortran77 files with ending .for
ifeq (,$(findstring $(strip $(MAKECMDGOALS)),check test clean cleanclean cleancheck cleantest html))
FORASRCS  := $(wildcard $(SOURCEPATH)/*.for)
endif
FORSRCS   := $(notdir $(FORASRCS))
FORAOBJS  := $(FORSRCS:.for=.o)
FOREXCL   :=
OFORAOBJS := $(filter-out $(FOREXCL), $(FORAOBJS))
FOROBJS   := $(addprefix $(OBJPATH)/, $(OFORAOBJS))
FORDOBJS  := $(FOROBJS:.o=.d)
GFORASRCS := $(FORASRCS:.for=.g90)
# Same for Fortran77 files with ending .f
ifeq (,$(findstring $(strip $(MAKECMDGOALS)),check test clean cleanclean cleancheck cleantest html))
FASRCS    := $(wildcard $(SOURCEPATH)/*.f)
endif
FSRCS     := $(notdir $(FASRCS))
FAOBJS    := $(FSRCS:.f=.o)
FEXCL     :=
OFAOBJS   := $(filter-out $(FEXCL), $(FAOBJS))
FOBJS     := $(addprefix $(OBJPATH)/, $(OFAOBJS))
FDOBJS    := $(FOBJS:.o=.d)
GFASRCS   := $(FASRCS:.f=.g90)

# ASRCS contain source dir informations
ifeq (,$(findstring $(strip $(MAKECMDGOALS)),check test clean cleanclean cleancheck cleantest html))
CASRCS     := $(wildcard $(SOURCEPATH)/*.c)
endif
CSRCS      := $(notdir $(CASRCS))
CAOBJS     := $(CSRCS:.c=.o)
CEXCL      :=
COAOBJS    := $(filter-out $(CEXCL), $(CAOBJS))
COBJS      := $(addprefix $(OBJPATH)/, $(COAOBJS))
CDOBJS     := $(COBJS:.o=.d)

# The Absoft compiler needs that ABSOFT is set to the Absoft base path
ifneq ($(ABSOFT),)
    export ABSOFT
endif
ifneq ($(LDPATH),)
    export LD_LIBRARY_PATH=$(LDPATH)
endif
#$(shell echo "aaa$(SOURCEPATH)aaa")

#
# --- TARGETS ---------------------------------------------------
#

.PHONY: clean cleanclean cleantest cleancheck html

# target for executables
all: $(PROG)
        ifneq (,$(findstring $(system),mcimac mcpowerbook mcair jmmacbookpro gdmacbookpro))
            ifneq ($(NOMACWARN),true)
                ifeq (${DYLD_LIBRARY_PATH},)
	            @echo
                    ifeq ($(static),static)
	                @echo "WARNING: MAC OS X does only link dynamically and does not work with -rpath"
                    else
	                @echo "WARNING: MAC OS X does not work with -rpath"
                    endif
	            @echo "         Set DYLD_LIBRARY_PATH if needed."
	            @echo
                endif
            endif
        endif

# Link Program
$(PROG): $(DOBJS) $(FORDOBJS) $(FDOBJS) $(CDOBJS) $(OBJS) $(FOROBJS) $(FOBJS) $(COBJS)
	$(LD) $(LDFLAGS) -o $(PROG) $(OBJS) $(FOROBJS) $(FOBJS) $(COBJS) $(LIBS)

# Get Dependencies
$(DOBJS): $(OBJPATH)/%.d: $(SOURCEPATH)/%.f90
#	@set -e; rm -f $@
	@dirname $@ | xargs mkdir -p 2>/dev/null
	$(MAKEDEPSPROG) $< "$(OBJPATH)" "$(SOURCEPATH)"

$(FORDOBJS): $(OBJPATH)/%.d: $(SOURCEPATH)/%.for
	@dirname $@ | xargs mkdir -p 2>/dev/null
	$(MAKEDEPSPROG) $< "$(OBJPATH)" "$(SOURCEPATH)"

$(FDOBJS): $(OBJPATH)/%.d: $(SOURCEPATH)/%.f
	@dirname $@ | xargs mkdir -p 2>/dev/null
	$(MAKEDEPSPROG) $< "$(OBJPATH)" "$(SOURCEPATH)"

$(CDOBJS): $(OBJPATH)/%.d: $(SOURCEPATH)/%.c
	@dirname $@ | xargs mkdir -p 2>/dev/null
	gcc $(DEFINES) -M $< | sed "s|$(notdir $(<:.c=.o)):|$(OBJPATH)/$(notdir $(<:.c=.o)):|" > $@

# Compile Objects
$(OBJS): $(OBJPATH)/%.o: $(SOURCEPATH)/%.f90
ifneq (,$(findstring $(icompiler),gnu41 gnu42))
	$(F90) -E -x c $(DEFINES) $(INCLUDES) $(F90FLAGS) $< > $(OBJPATH)/tmp.gf3.$(notdir $<)
	$(F90) $(DEFINES) $(INCLUDES) $(F90FLAGS) -c $(OBJPATH)/tmp.gf3.$(notdir $<) -o $@
	rm -r $(OBJPATH)/tmp.gf3.$(notdir $<)
else
	$(F90) $(DEFINES) $(INCLUDES) $(F90FLAGS) -c $< -o $@
endif

$(FOROBJS): $(OBJPATH)/%.o: $(SOURCEPATH)/%.for
ifneq (,$(findstring $(icompiler),gnu41 gnu42))
	$(FC) -E -x c $(DEFINES) $(INCLUDES) $(FCFLAGS) $< > $(OBJPATH)/tmp.gf3.$(notdir $<)
	$(FC) $(DEFINES) $(INCLUDES) $(FCFLAGS) -c $(OBJPATH)/tmp.gf3.$(notdir $<) -o $@
	rm -r $(OBJPATH)/tmp.gf3.$(notdir $<)
else
	$(FC) $(DEFINES) $(INCLUDES) $(FCFLAGS) -c $< -o $@
endif

$(FOBJS): $(OBJPATH)/%.o: $(SOURCEPATH)/%.f
ifneq (,$(findstring $(icompiler),gnu41 gnu42))
	$(FC) -E -x c $(DEFINES) $(INCLUDES) $(FCFLAGS) $< > $(OBJPATH)/tmp.gf3.$(notdir $<)
	$(FC) $(DEFINES) $(INCLUDES) $(FCFLAGS) -c $(OBJPATH)/tmp.gf3.$(notdir $<) -o $@
	rm -r $(OBJPATH)/tmp.gf3.$(notdir $<)
else
	$(FC) $(DEFINES) $(INCLUDES) $(FCFLAGS) -c $< -o $@
endif

$(COBJS): $(OBJPATH)/%.o: $(SOURCEPATH)/%.c
	$(CC) $(DEFINES) $(INCLUDES) $(CFLAGS) -c $< -o $@

# Helper Targets
clean:
	rm -f $(DOBJS) $(FORDOBJS) $(FDOBJS) $(CDOBJS) $(OBJS) $(FOROBJS) $(FOBJS) $(COBJS) "$(OBJPATH)"/*.mod "$(PROG)"
	rm -f $(GASRCS) $(GFORASRCS) $(GFASRCS)
        ifneq (,$(findstring $(SOURCEPATH),test_netcdf_imsl_proj))
	    @if [ -f $(SOURCEPATH)/test.nc ] ; then rm $(SOURCEPATH)/test.nc ; fi
        endif
	@if [ -f $(strip $(PROGPATH))/"Test.nc" ] ; then rm $(strip $(PROGPATH))/"Test.nc" ; fi

cleanclean: clean
	rm -rf "$(SOURCEPATH)"/.*.r* "$(SOURCEPATH)"/.*.d* $(PROG).dSYM $(strip $(PROGPATH))/html

cleancheck:
	for i in $(shell ls -d $(strip $(TESTPATH))/test*) ; do \
	    make SRCPATH=$$i cleanclean ; \
	done

cleantest: cleancheck

check:
	for i in $(shell ls -d $(strip $(TESTPATH))/test*) ; do \
	    rm -f "$(PROG)" ; \
	    make -s MAKEDPATH=$(MAKEDPATH) SRCPATH=$$i PROGPATH=$(PROGPATH) \
	         CONFIGPATH=$(CONFIGPATH) PROGNAME=$(PROGNAME) system=$(system) \
	         release=$(release) netcdf=$(netcdf) static=$(static) proj=$(proj) \
	         imsl=$(imsl) mkl=$(mkl) lapack=$(lapack) compiler=$(compiler) \
	         openmp=$(openmp) NOMACWARN=true \
	    && { $(PROG) 2>&1 | grep -E '(o.k.|failed)' ;} ; status=$$? ; \
	    if [ $$status != 0 ] ; then \
	      echo "$$i failed!"; \
	    fi ; \
	    make -s SRCPATH=$$i cleanclean ; \
	done

test: check

html:
	$(strip $(CONFIGPATH))/f2html -f $(strip $(CONFIGPATH))/f2html.fgenrc -d $(strip $(PROGPATH))/html $(SOURCEPATH)

# All dependencies create by perl script make.d.pl
ifeq (,$(findstring $(strip $(MAKECMDGOALS)),clean cleanclean cleancheck cleantest html))
-include $(DOBJS) $(FORDOBJS) $(FDOBJS)
endif
