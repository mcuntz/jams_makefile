# -*- Makefile -*-
#
# PURPOSE
#     CHS Makefile for Fortran, C and mixed projects
#
# CALLING SEQUENCE
#     make [options] [VARIABLE=VARIABLE ...] [targets]
#
#     Variables can be set on the command line [VAR=VAR] or in the SWITCHES section below.
#
#     If PROGNAME is given then an executable will be compiled.
#     If LIBNAME  is given then a library will be created instead.
#
# TARGETS
#     all (default), check (=test), clean, cleanclean, cleancheck (=cleantest), html, info
#
# OPTIONS
#     All make options such as -f makefile. See 'man make'.
#
# VARIABLES
#     All variables defined in this makefile.
#     This makefile has lots of conditional statements depending on variables.
#     If the variable functions as a switch then the condition checks for variable = true,
#     otherwise the variable can have different values.
#     See individual variables in SWITCHES section below or try 'make info'.
#
#     Variables can be empty for disabling a certain behaviour,
#     e.g. if you do not want to use IMSL, set:  imsl=no  or  imsl=
#
#     For main variables see 'make info'.
#
# DEPENDENCIES
#    This make file uses the following files:
#        $(MAKEDPATH)/make.d.pl, $(CONFIGPATH)/$(system).$(compiler), $(CONFIGPATH)/$(system).alias
#        $(CONFIGPATH)/f2html, $(CONFIGPATH)/f2html.fgenrc
#    The default $(MAKEDPATH) and $(CONFIGPATH) is make.config
#
# RESTRICTIONS
#    Not all packages work with or are compiled for all compilers.
#    The static switch is maintained like a red-headed stepchild. Libraries might be not ordered correctly
#    if static linking and --begin/end-group is not supported.
#
# EXAMPLE
#    make release=debug compiler=intel11 imsl=vendor mkl=mkl95 PROGNAME=prog
#
# NOTES
#    Further information is given in the README, for example
#    on the repository of the makefile, further reading, how to add a new compiler on a system, or
#    how to add a new system.
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
# Written Matthias Cuntz & Juliane Mai, UFZ Leipzig, Germany, Nov. 2011 - mc (at) macu.de

SHELL = /bin/bash

#
# --- SWITCHES -------------------------------------------------------
#

# . is current directory, .. is parent directory
SRCPATH    := test_standard       # where are the source files; use test_??? to run a test directory
PROGPATH   := .       # where shall be the executable
CONFIGPATH := make.config # where are the $(system).$(compiler) files
MAKEDPATH  := make.config # where is the make.d.pl script
TESTPATH   := .
#
PROGNAME := Prog # Name of executable
LIBNAME  := #libminpack.a # Name of library
#
# Options
# Systems: eve, mcimac, mcpowerbook, mcair, jmmacbookpro, gdmacbookpro, stdesk, stubuntu, stufz, burnet
system   := mcair
# Compiler: intel11, intel12, gnu41, gnu42, gnu44, gnu45, gnu46, absoft, nag51, nag52, nag53, sun12
compiler := gnu
# Releases: debug, release
release  := release
# Netcdf versions (Network Common Data Form): netcdf3, netcdf4, [anything else]
netcdf   :=
# LAPACK (Linear Algebra Pack): true, [anything else]
lapack   := true
# MKL (Intel's Math Kernel Library): mkl, mkl95, [anything else]
mkl      :=
# Proj4 (Cartographic Projections Library): true, [anything else]
proj     :=
# IMSL (IMSL Numerical Libraries): vendor, imsl, [anything else]
imsl     :=
# OpenMP parallelization: true, [anything else]
openmp   :=
# Linking: static, shared, dynamic (last two are equal)
static   := shared

# The Makefile sets the following variables depending on the above options:
# FC, FCFLAGS, F90FLAGS, DEFINES, INCLUDES, LD, LDFLAGS, LIBS
# flags, defines, etc. will be set incremental. They will be initialised with
# the following EXTRA_* variables. This allows for example to set an extra compiler
# option or define a preprocessor variable such as: EXTRA_DEFINES := -DNOGUI -DDPREC
#
# INTEL optimisation: -ipo=0 -ipo-c
#     -ipo=n             Interprocedural optimization
# INTEL debug: -fpe=0 -fpe-all=0 -no-ftz -ftrapuv
#     -fpe=0 -fpe-all=0  errors on all floating point exceptions except underflow.
#     -no-ftz            catches then also all underflows.
#     -ftrapuv           sets undefined numbers to arbitrary values so that floating point exceptions kick in.
# SUN optimisation: -xipo=2
#     -xipo=n 0 disables interprocedural analysis, 1 enables inlining across source files,
#             2 adds whole-program detection and analysis.
# SUN debug: -ftrap=%all, %none, common, [no%]invalid, [no%]overflow, [no%]underflow, [no%]division, [no%]inexact.
#     -ftrap=%n  Set floating-point trapping mode.
# NAG debug: -C=undefined -C=intovf
#     -C=undefined  is also checking 0-strings. Function nonull in UFZ mo_string_utils will stop with error.
#     -C=intovf  check integer overflow, which is intentional in UFZ mo_xor4096.
#     -C=undefined fails UFZs mo_corr and mo_fit due to compiler bugs.
EXTRA_FCFLAGS  :=
EXTRA_F90FLAGS :=
EXTRA_DEFINES  :=
EXTRA_INCLUDES :=
EXTRA_LDFLAGS  :=
EXTRA_LIBS     :=
EXTRA_CFLAGS   :=

#
# --- CHECK 0 ---------------------------------------------------
#

# Check available switches
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

#
# --- PATHES ------------------------------------------------
#

# Make absolute pathes from relative pathes
ifeq (,$(strip $(PROGNAME)))
    PROG :=
else
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
endif

# Make absolute pathes from relative pathes
ifeq (,$(strip $(LIBNAME)))
    LIB :=
else
    ifeq ($(findstring //,/$(LIBPATH:~%=/%)),)         # starts not with / or ~
        ifeq ($(findstring '/.',/$(LIBPATH)),)       # starts not with .
            LIB := $(CURDIR)/$(strip $(LIBPATH))/$(strip $(LIBNAME))
        else                                        # starts with .
        ifeq ($(subst ./,,$(dir $(LIBPATH))),) # is just .
                LIB := $(CURDIR)/$(strip $(LIBNAME))
            else                                    # is ./etc
                LIB := $(CURDIR)/$(strip $(subst ./,,$(dir $(LIBPATH))))/$(strip $(LIBNAME))
            endif
        endif
    else                                            # starts with /
        LIB := $(strip $(LIBPATH:~%=${HOME}%))/$(strip $(LIBNAME))
    endif
endif

# Only Prog or Lib
ifeq (,$(strip $(PROG)))
    ifeq (,$(strip $(LIB)))
        $(error Error: PROGNAME or LIBNAME must be given.)
    else
        islib := True
    endif
else
    ifeq (,$(strip $(LIB)))
        islib := False
    else
        $(error Error: only one of PROGNAME or LIBNAME can be given.)
    endif
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

#
# --- CHECK 1 ---------------------------------------------------
#

systems=$(shell ls -1 $(CONFIGPATH) | sed -e '/make.d.pl/d' -e '/f2html/d' | cut -d '.' -f 1 | sort | uniq)
ifeq (,$(findstring $(system),$(systems)))
    $(error Error: system '$(system)' not found: known systems are $(systems))
endif

#
# --- ALIASES ---------------------------------------------------
#

# Include compiler alias on specific systems, e.g. nag for nag53
icompiler := $(compiler)
ALIASINC := $(strip $(CONFIGPATH))/$(system).alias
ifeq (exists, $(shell if [ -f $(ALIASINC) ] ; then echo 'exists' ; fi))
    include $(ALIASINC)
endif

#
# --- CHECK 2 ---------------------------------------------------
#
compilers=$(shell ls -1 $(CONFIGPATH) | sed -e '/make.d.pl/d' -e '/f2html/d' -e '/alias/d' | grep $(system) | cut -d '.' -f 2 | sort | uniq)
ifeq (,$(findstring $(icompiler),$(compilers)))
    $(error Error: compiler '$(icompiler)' not found: configured compilers for system $(system) are $(compilers))
endif

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
DEFINES  := $(EXTRA_DEFINES)
INCLUDES := $(EXTRA_INCLUDES)
# and link, and therefore set below
LD       :=
LDFLAGS  := $(EXTRA_LDFLAGS)
LIBS     := $(EXTRA_LIBS) -L$(SOURCEPATH)
AR       := ar
ARFLAGS  := -ru
RANLIB   := ranlib

#
# --- COMPILER / MACHINE SPECIFIC --------------------------------
#

# Set path where all the .mod, .o, etc. files will be written, set before include $(MAKEINC)
OBJPATH := $(SOURCEPATH)/.$(strip $(icompiler)).$(strip $(release))

# Include the individual configuration files
MAKEINC := $(strip $(CONFIGPATH))/$(system).$(icompiler)
ifneq (exists, $(shell if [ -f $(MAKEINC) ] ; then echo 'exists' ; fi))
    $(error Error: '$(MAKEINC)' not found.)
endif
include $(MAKEINC)

# Always use -DCFORTRAN for mixed C and Fortran compilations
DEFINES  += -DCFORTRAN

# Mac OS X is special, there is (almost) no static linking.
# MAC OS X does not work with -rpath. Set DYLD_LIBRARY_PATH if needed.
iOS := $(shell uname -s)
istatic := $(static)
ifneq (,$(findstring $(iOS),Darwin))
    istatic := dynamic
endif

# Start group for cyclic search in static linking
iLIBS :=
ifeq ($(istatic),static)
    iLIBS += -Bstatic -Wl,--start-group
else
    ifneq (,$(findstring $(iOS),Darwin))
        iLIBS += -Wl,-dynamic
    else
        iLIBS += -Bdynamic
    endif
endif

# --- COMPILER ---------------------------------------------------
ifneq (,$(findstring $(icompiler),gnu41 gnu42 gnu44 gnu45 gnu46))
    ifneq (exists, $(shell if [ -d "$(GFORTRANDIR)" ] ; then echo 'exists' ; fi))
        $(error Error: GFORTRAN path '$(GFORTRANDIR)' not found.)
    endif
    GFORTRANLIB ?= $(GFORTRANDIR)/lib
    iLIBS       += -L$(GFORTRANLIB) -lgfortran
    RPATH       += -Wl,-rpath,$(GFORTRANLIB)
endif

# --- IMSL ---------------------------------------------------
ifneq (,$(findstring $(imsl),vendor imsl))
    ifneq (exists, $(shell if [ -d "$(IMSLDIR)" ] ; then echo 'exists' ; fi))
        $(error Error: IMSL path '$(IMSLDIR)' not found.)
    endif
    IMSLINC ?= $(IMSLDIR)/include
    IMSLLIB ?= $(IMSLDIR)/lib

    INCLUDES += -I$(IMSLINC)
    ifneq ($(ABSOFT),)
        INCLUDES += -p $(IMSLINC)
    endif
    DEFINES  += -DIMSL

    ifeq (,$(findstring $(iOS),Darwin))
        iLIBS     += -z muldefs
        ifneq ($(istatic),static)
            iLIBS += -i_dynamic
        endif
    endif

    ifneq (,$(findstring $(iOS),Darwin))
        iLIBS += -L$(IMSLLIB) -limsl -limslscalar -limsllapack -limslblas -limsls_err -limslmpistub -limslsuperlu
    else
        ifeq ($(imsl),imsl)
            iLIBS += -L$(IMSLLIB) -limsl -limslscalar -limsllapack_imsl -limslblas_imsl -limsls_err -limslmpistub -limslsuperlu
        else
            iLIBS += -L$(IMSLLIB) -limsl -limslscalar -limsllapack_vendor -limslblas_vendor -limsls_err -limslmpistub -limslsuperlu -limslhpc_l
        endif
    endif
    RPATH += -Wl,-rpath,$(IMSLLIB)
endif

# --- OPENMP ---------------------------------------------------
iopenmp=
ifeq ($(openmp),true)
    ifneq (,$(findstring $(icompiler),gnu41 gnu42 gnu44 gnu45 gnu46))
        iopenmp = -fopenmp
    else
        iopenmp = -openmp
    endif
    DEFINES += -DOPENMP
endif
F90FLAGS += $(iopenmp)
FCFLAGS  += $(iopenmp)
CFLAGS   += $(iopenmp)
LDFLAGS  += $(iopenmp)
# IMSL needs openmp during linking in any case
ifneq ($(openmp),true)
    ifneq (,$(findstring $(imsl),vendor imsl))
        ifneq (,$(findstring $(icompiler),gnu41 gnu42 gnu44 gnu45 gnu46))
            LDFLAGS += -fopenmp
        else
            LDFLAGS += -openmp
        endif
    endif
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
        ifneq ($(ABSOFT),)
            INCLUDES += -p $(MKL95INC)
        endif
        DEFINES  += -DMKL95

        iLIBS += -L$(MKL95LIB) -lmkl_blas95_lp64 -lmkl_lapack95_lp64
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
    ifneq ($(ABSOFT),)
        INCLUDES += -p $(MKLINC)
    endif
    DEFINES  += -DMKL

    iLIBS += -L$(MKLLIB) -lmkl_intel_lp64 -lmkl_core #-lpthread
    ifneq (,$(findstring $(imsl),vendor imsl))
       iLIBS += -lmkl_intel_thread #-lpthread
    else
        ifeq ($(openmp),true)
            iLIBS += -lmkl_intel_thread #-lpthread
        else
            iLIBS += -lmkl_sequential #-lpthread
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
    ifneq ($(ABSOFT),)
        INCLUDES += -p $(NCINC)
    endif
    DEFINES += -DNETCDF

    iLIBS += -L$(NCLIB)
    RPATH += -Wl,-rpath,$(NCLIB)
    ifeq (libnetcdff, $(shell ls $(NCLIB)/libnetcdff.* 2> /dev/null | sed -n '1p' | sed -e 's/.*\(libnetcdff\)/\1/' -e 's/\(libnetcdff\).*/\1/'))
        iLIBS += -lnetcdff
    endif
    iLIBS += -lnetcdf

    ifeq (exists, $(shell if [ -d "$(NCDIR2)" ] ; then echo 'exists' ; fi))
        NCINC2 ?= $(strip $(NCDIR2))/include
        NCLIB2 ?= $(strip $(NCDIR2))/lib

        INCLUDES += -I$(NCINC2)
        ifneq ($(ABSOFT),)
            INCLUDES += -p $(NCINC2)
        endif

        iLIBS += -L$(NCLIB2)
        RPATH += -Wl,-rpath,$(NCLIB2)
        ifeq (libnetcdff, $(shell ls $(NCLIB2)/libnetcdff.* 2> /dev/null | sed -n '1p' | sed -e 's/.*\(libnetcdff\)/\1/' -e 's/\(libnetcdff\).*/\1/'))
            iLIBS += -lnetcdff
        endif
    endif

    # other libraries for netcdf4, ignored for netcdf3
    ifeq ($(netcdf),netcdf4)
        iLIBS += -L$(HDF5LIB) -lhdf5_hl -lhdf5 -L$(SZLIB) -lsz -lz
        RPATH += -Wl,-rpath,$(SZLIB) -Wl,-rpath,$(HDF5LIB)
        ifneq ($(CURLLIB),)
            iLIBS += -L$(CURLLIB) -lcurl
            RPATH += -Wl,-rpath,$(CURLLIB)
        endif
   endif
endif

# --- PROJ --------------------------------------------------
ifeq ($(proj),true)
    ifneq (exists, $(shell if [ -d "$(PROJ4DIR)" ] ; then echo 'exists' ; fi))
        $(error Error: PROJ4 path '$(PROJ4DIR)' not found.)
    endif
    PROJ4LIB ?= $(PROJ4DIR)/lib
    iLIBS    += -L$(PROJ4LIB) -lproj
    RPATH    += -Wl,-rpath=$(PROJ4LIB)

    ifneq (exists, $(shell if [ -d "$(FPROJDIR)" ] ; then echo 'exists' ; fi))
        $(error Error: FPROJ path '$(FPROJDIR)' not found.)
    endif
    FPROJINC ?= $(FPROJDIR)/include
    FPROJLIB ?= $(FPROJDIR)/lib

    INCLUDES += -I$(FPROJINC)
    ifneq ($(ABSOFT),)
        INCLUDES += -p $(FPROJINC)
    endif
    DEFINES  += -DFPROJ
    iLIBS    += -L$(FPROJLIB) -lfproj4 $(FPROJLIB)/proj4.o
    RPATH    += -Wl,-rpath,$(FPROJLIB)
endif

# --- LAPACK ---------------------------------------------------
ifeq ($(lapack),true)
    # Mac OS X uses frameworks
    ifneq (,$(findstring $(iOS),Darwin))
        iLIBS += -framework veclib
    else
        ifneq (exists, $(shell if [ -d "$(LAPACKDIR)" ] ; then echo 'exists' ; fi))
            $(error Error: LAPACK path '$(LAPACKDIR)' not found.)
        endif
        LAPACKLIB ?= $(LAPACKDIR)/lib
        iLIBS     += -L$(LAPACKLIB) -lblas -llapack
        RPATH     += -Wl,-rpath,$(LAPACKLIB)
    endif
    DEFINES += -DLAPACK
endif

#
# --- FINISH SETUP ---------------------------------------------------
#

ifeq ($(release),debug)
    DEFINES += -DDEBUG
endif

# Mac OS X is special, there is (almost) no static linking
ifeq ($(istatic),static)
    iLIBS += -Wl,--end-group
endif
# The NAG compiler links via gcc so that one has to give -Wl twice and double commas for the option
# i.e. instead of  -Wl,rpath,/path   you need   -Wl,-Wl,,rpath,,/path
ifneq (,$(findstring $(icompiler),nag51 nag52 nag53))
    comma  := ,
    iiLIBS := $(subst -Wl,-Wl$(comma)-Wl,$(subst $(comma),$(comma)$(comma),$(iLIBS)))
    iRPATH := $(subst -Wl,-Wl$(comma)-Wl,$(subst $(comma),$(comma)$(comma),$(RPATH)))
else
    iiLIBS := $(iLIBS)
    iRPATH := $(RPATH)
endif
LIBS += $(iiLIBS)
# Only Linux and Solaris can use -rpath in executable
ifeq (,$(findstring $(iOS),Darwin))
    LIBS += $(iRPATH)
endif

LD := $(F90)

iphony    := False
iphonyall := False
ifneq (,$(strip $(MAKECMDGOALS)))
    ifneq (,$(findstring $(strip $(MAKECMDGOALS))/,check/ test/ html/ cleancheck/ cleantest/))
        iphony := True
    endif
    ifneq (,$(findstring $(strip $(MAKECMDGOALS))/,check/ test/ html/ cleancheck/ cleantest/ info/ clean/ cleanclean/))
        iphonyall := True
    endif
endif

# ASRCS contain source dir informations
ifeq (False,$(iphony))
    ASRCS := $(wildcard $(SOURCEPATH)/*.f90)
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
GASRCS    := $(SRCS:.f90=.g90) $(addprefix $(SOURCEPATH)/, $(SRCS:.f90=.g90))

# Same for Fortran77 files with ending .for
ifeq (False,$(iphony))
    FORASRCS := $(wildcard $(SOURCEPATH)/*.for)
endif
FORSRCS   := $(notdir $(FORASRCS))
FORAOBJS  := $(FORSRCS:.for=.o)
FOREXCL   :=
OFORAOBJS := $(filter-out $(FOREXCL), $(FORAOBJS))
FOROBJS   := $(addprefix $(OBJPATH)/, $(OFORAOBJS))
FORDOBJS  := $(FOROBJS:.o=.d)
GFORASRCS := $(FORSRCS:.for=.g90) $(addprefix $(SOURCEPATH)/, $(FORSRCS:.for=.g90))

# Same for Fortran77 files with ending .f
ifeq (False,$(iphony))
    FASRCS := $(wildcard $(SOURCEPATH)/*.f)
endif
FSRCS     := $(notdir $(FASRCS))
FAOBJS    := $(FSRCS:.f=.o)
FEXCL     :=
OFAOBJS   := $(filter-out $(FEXCL), $(FAOBJS))
FOBJS     := $(addprefix $(OBJPATH)/, $(OFAOBJS))
FDOBJS    := $(FOBJS:.o=.d)
GFASRCS   := $(FSRCS:.f=.g90) $(addprefix $(SOURCEPATH)/, $(FSRCS:.f=.g90))

# Same for C files with ending .c
ifeq (False,$(iphony))
    CASRCS := $(wildcard $(SOURCEPATH)/*.c)
endif
CSRCS      := $(notdir $(CASRCS))
CAOBJS     := $(CSRCS:.c=.o)
CEXCL      :=
COAOBJS    := $(filter-out $(CEXCL), $(CAOBJS))
COBJS      := $(addprefix $(OBJPATH)/, $(COAOBJS))
CDOBJS     := $(COBJS:.o=.d)

# Static libraries in source path
ifeq (False,$(iphony))
    LAASRCS := $(wildcard $(SOURCEPATH)/*.a)
endif
LASRCS      := $(notdir $(LAASRCS))
LAAOBJS     := $(LASRCS:.a=)
LAEXCL      :=
LAOAOBJS    := $(filter-out $(LAEXCL), $(LAAOBJS))
LLAOAOBJS   := $(patsubst lib%, %, $(LAOAOBJS))
LAOBJS      := $(addprefix -l, $(LLAOAOBJS))

# Dynamic libraries in source path
ifeq (False,$(iphony))
    LOASRCS := $(wildcard $(SOURCEPATH)/*.so)
endif
LOSRCS      := $(notdir $(LOASRCS))
LOAOBJS     := $(LOSRCS:.so=)
LOEXCL      :=
LOOAOBJS    := $(filter-out $(LOEXCL), $(LOAOBJS))
LLOOAOBJS   := $(patsubst lib%, %, $(LOOAOBJS))
LOOBJS      := $(addprefix -l, $(LLOOAOBJS))

# The Absoft compiler needs that ABSOFT is set to the Absoft base path
ifneq ($(ABSOFT),)
    export ABSOFT
endif
ifneq ($(LDPATH),)
    export LD_LIBRARY_PATH=$(LDPATH)
endif

#
# --- TARGETS ---------------------------------------------------
#

.PHONY: clean cleanclean cleantest cleancheck html check test info

# Link Program
all: $(PROG) $(LIB)

$(PROG): $(DOBJS) $(FORDOBJS) $(FDOBJS) $(CDOBJS) $(OBJS) $(FOROBJS) $(FOBJS) $(COBJS)
	$(LD) $(LDFLAGS) -o $(PROG) $(OBJS) $(FOROBJS) $(FOBJS) $(COBJS) $(LIBS) $(LAOBJS) $(LOOBJS)

$(LIB): $(DOBJS) $(FORDOBJS) $(FDOBJS) $(CDOBJS) $(OBJS) $(FOROBJS) $(FOBJS) $(COBJS)
	$(AR) $(ARFLAGS) $(LIB) $(OBJS) $(FOROBJS) $(FOBJS) $(COBJS)
	$(RANLIB) $(LIB)

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
ifeq (False,$(islib))
	rm -f "$(PROG)"
endif
	rm -f $(GASRCS) $(GFORASRCS) $(GFASRCS)
#       Special cleaning of CHS library tests
        ifneq (,$(findstring $(SOURCEPATH),test_netcdf_imsl_proj))
	    @if [ -f $(SOURCEPATH)/test.nc ] ; then rm $(SOURCEPATH)/test.nc ; fi
        endif
	@if [ -f $(strip $(PROGPATH))/"Test.nc" ] ; then rm $(strip $(PROGPATH))/Test.nc ; fi
	@if [ -f $(strip $(PROGPATH))/"1_tmp_parasets.nc" ]  ; then rm $(strip $(PROGPATH))/?_tmp_parasets.nc  ; fi
	@if [ -f $(strip $(PROGPATH))/"10_tmp_parasets.nc" ] ; then rm $(strip $(PROGPATH))/??_tmp_parasets.nc ; fi

cleanclean: clean
	rm -rf "$(SOURCEPATH)"/.*.r* "$(SOURCEPATH)"/.*.d* "$(PROG)".dSYM $(strip $(PROGPATH))/html
ifeq (True,$(islib))
	rm -f "$(LIB)"
endif

cleancheck:
	for i in $(shell ls -d $(strip $(TESTPATH))/test*) ; do \
	    $(MAKE) SRCPATH=$$i cleanclean ; \
	done

cleantest: cleancheck

check:
ifeq (True,$(islib))
	$(error Error: check and test must be done with PROGNAME not LIBNAME.)
endif
	for i in $(shell ls -d $(strip $(TESTPATH))/test*) ; do \
	    rm -f "$(PROG)" ; \
	    j=$${i/minpack/maxpack} ; \
	    if [ $$i != $$j ] ; then \
	    	 $(MAKE) -s MAKEDPATH=$(MAKEDPATH) SRCPATH="$$i"/../../minpack PROGPATH=$(PROGPATH) \
	    	      CONFIGPATH=$(CONFIGPATH) PROGNAME= LIBNAME=libminpack.a system=$(system) \
	    	      release=$(release) netcdf=$(netcdf) static=$(static) proj=$(proj) \
	    	      imsl=$(imsl) mkl=$(mkl) lapack=$(lapack) compiler=$(compiler) \
	    	      openmp=$(openmp) NOMACWARN=true ; \
	    fi ; \
	    $(MAKE) -s MAKEDPATH=$(MAKEDPATH) SRCPATH=$$i PROGPATH=$(PROGPATH) \
	         CONFIGPATH=$(CONFIGPATH) PROGNAME=$(PROGNAME) system=$(system) \
	         release=$(release) netcdf=$(netcdf) static=$(static) proj=$(proj) \
	         imsl=$(imsl) mkl=$(mkl) lapack=$(lapack) compiler=$(compiler) \
	         openmp=$(openmp) NOMACWARN=true \
	    && { $(PROG) 2>&1 | grep -E '(o.k.|failed)' ;} ; status=$$? ; \
	    if [ $$status != 0 ] ; then \
	      echo "$$i failed!" ; \
	    fi ; \
	    $(MAKE) -s SRCPATH=$$i cleanclean ; \
	    if [ $$i != $$j ] ; then \
	    	 $(MAKE) -s SRCPATH="$$i"/../../minpack PROGNAME= LIBNAME=libminpack.a cleanclean ; \
	    fi ; \
	done

test: check

html:
	$(strip $(CONFIGPATH))/f2html -f $(strip $(CONFIGPATH))/f2html.fgenrc -d $(strip $(PROGPATH))/html $(SOURCEPATH)

info:
	@echo "CHS Makefile"
	@echo ""
	@echo "Config"
	@echo "system   = $(system)"
	@echo "compiler = $(compiler)"
	@echo "release  = $(release)"
	@echo "netcdf   = $(netcdf)"
	@echo "lapack   = $(lapack)"
	@echo "mkl      = $(mkl)"
	@echo "proj     = $(proj)"
	@echo "imsl     = $(imsl)"
	@echo "openmp   = $(openmp)"
	@echo "static   = $(static)"
	@echo ""
	@echo "Files/Pathes"
	@echo "SRCPATH    = $(SRCPATH)"
	@echo "PROGPATH   = $(PROGPATH)"
	@echo "CONFIGPATH = $(CONFIGPATH)"
	@echo "MAKEDPATH  = $(MAKEDPATH)"
	@echo "TESTPATH   = $(TESTPATH)"
	@echo "PROGNAME   = $(PROGNAME)"
	@echo "LIBNAME    = $(LIBNAME)"
	@echo "FILES      = $(SRCS) $(FORSRCS) $(FSRCS) $(CSRCS) $(LASRCS) $(LOSRCS)"
	@echo ""
	@echo "Programs/Flags"
	@echo "FC        = $(FC)"
	@echo "FCFLAGS   = $(FCFLAGS)"
	@echo "F90       = $(F90)"
	@echo "F90FLAGS  = $(F90FLAGS)"
	@echo "CC        = $(CC)"
	@echo "CFLAGS    = $(CFLAGS)"
	@echo "DEFINES   = $(DEFINES)"
	@echo "INCLUDES  = $(INCLUDES)"
	@echo "LD        = $(LD)"
	@echo "LDFLAGS   = $(LDFLAGS)"
	@echo "LIBS      = $(LIBS)"
	@echo "AR        = $(AR)"
	@echo "ARFLAGS   = $(ARFLAGS)"
	@echo "RANLIB    = $(RANLIB)"
	@echo ""
	@echo "Configured compilers on $(system): $(compilers)"
ifeq (exists, $(shell if [ -f $(ALIASINC) ] ; then echo 'exists' ; fi))
	@echo ""
	@echo "Compiler aliases for $(system)"
	@sed -n '/ifneq (,$$(findstring $$(compiler)/,/endif/p' $(ALIASINC) | \
	 sed -e '/endif/d' -e 's/icompiler ://' | \
	 sed -e 's/ifneq (,$$(findstring $$(compiler),//' -e 's/))//' | \
	 paste - - | tr -d '\t' | tr -s ' '
endif
	@echo ""
	@echo "All possibilities"
	@echo "system      $(shell ls -1 $(CONFIGPATH) | sed -e '/make.d.pl/d' -e '/f2html/d' | cut -d '.' -f 1 | sort | uniq)"
	@echo "compiler    $(shell ls -1 $(CONFIGPATH) | sed -e '/make.d.pl/d' -e '/f2html/d' -e '/alias/d' | cut -d '.' -f 2 | sort | uniq)"
	@echo "release     debug release"
	@echo "netcdf      netcdf3 netcdf4 [anything else]"
	@echo "lapack      true [anything else]"
	@echo "mkl         mkl mkl95 [anything else]"
	@echo "proj        true [anything else]"
	@echo "imsl        vendor imsl [anything else]"
	@echo "openmp      true [anything else]"
	@echo "static      static shared (=dynamic)"

# All dependencies create by perl script make.d.pl
ifeq (False,$(iphonyall))
-include $(DOBJS) $(FORDOBJS) $(FDOBJS) $(CDOBJS)
endif
