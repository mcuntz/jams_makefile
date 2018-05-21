# -*- Makefile -*-
#
# PURPOSE
#     JAMS Makefile for Fortran, C and mixed projects
#
# CALLING SEQUENCE
#     make [options] [VARIABLE=VARIABLE ...] [targets]
#
#     Variables can be set on the command line [VAR=VAR] or in the section SWITCHES below.
#
#     If $(PROGNAME) is given, an executable will be compiled.
#     If $(LIBNAME)  is given, a library will be created.
#
#     Sources are in $(SRCPATH), which can be several directories separated by whitespace.
#
#     File suffixes can be given in $(F90SUFFIXES), $(F77SUFFIXES), and $(CSUFFIXES)
#     Default Fortran 90 is: .f90, .F90, .f95, .F95, .f03, .F03, .f08, .F08
#     Default Fortran 77 is: .f,   .F,   .for, .FOR, .f77, .F77, .ftn, .FTN
#     Default C is:          .c,   .C,   .cc,  .CC
#
# TARGETS
#     all (default), check (=test), clean, cleanclean (=distclean), cleancheck (=cleantest=checkclean=testclean),
#     cleancleancheck (=cleancleantest=checkcleanclean=testcleanclean), dependencies (=depend),
#     html, pdf, latex, doxygen, info
#
# OPTIONS
#     All make options such as -f makefile. See 'man make'.
#
# VARIABLES
#     All variables defined in this makefile.
#     This makefile has lots of conditional statements depending on variables.
#     If the variable works as a switch then the condition checks for variable = true,
#     i.e. ifeq ($(variable),true)
#     otherwise the variable can have any other value.
#     See individual variables in section SWITCHES below or type 'make info'.
#
#     Variables can be empty for disabling a certain behaviour,
#     e.g. if you do not want to use IMSL, set:  imsl=no  or  imsl=
#
#     For main variables see 'make info'.
#
# DEPENDENCIES
#    This makefile uses the following files:
#        $(MAKEDPATH)/make.d.py, $(CONFIGPATH)/$(system).$(compiler), $(CONFIGPATH)/$(system).alias
#    The default $(MAKEDPATH) and $(CONFIGPATH) is make.config
#    The makefile can use doxygen for html and pdf automatic documentation.
#        It is then using $(DOXCONFIG).
#    If this is not available, it uses the perl script f2html for html documentation:
#        $(TOOLPATH)/f2html, $(TOOLPATH)/f2html.fgenrc
#
# RESTRICTIONS
#    Not all packages work with or are compiled for all compilers.
#    The static switch is maintained like a red-headed stepchild. Libraries might be not ordered correctly
#    if static linking and --begin-group/--end-group is not supported.
#
#    C-file dependencies are generated with
#        $(CC) -E $(DEFINES) -MM
#
# EXAMPLE
#    make system=eve compiler=intel release=debug mkl=mkl95 PROGNAME=prog
#
# NOTES
#    Further information is given in the README, for example on
#    the repository of the makefile,
#    further reading,
#    how to add a new compiler on a given system, or
#    how to add a new system.
#
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
#    along with the JAMS makefile project (cf. gpl.txt and lgpl.txt).
#    If not, see <http://www.gnu.org/licenses/>.
#
#    Copyright 2011-2017 Matthias Cuntz
#
# Written and maintained Matthias Cuntz, Nov. 2011 - mc (at) macu.de

SHELL = /bin/bash

#
# --- SWITCHES -------------------------------------------------------
#

# . is current directory, .. is parent directory
SRCPATH    := ../fortran/test/test_mo_netcdf # where are the source files; use test_??? to
PROGPATH   := .                  # where shall be the executable
CONFIGPATH := make.config        # where are the $(system).$(compiler) files
MAKEDPATH  := $(CONFIGPATH)      # where is the make.d.sh script
CHECKPATH  := ../fortran/test    # path for $(CHECKPATH)/test* and $(CHECKPATH)/check* directories if target is check
TOOLPATH   := tools              # tools such as f2html
DOXCONFIG  := ./doxygen.config   # the doxygen config file
#
PROGNAME := Prog # Name of executable
LIBNAME  := # Name of library, e.g. libminpack.a
#
# Options
# Systems: eve and personal computers such as mcair for Matthias' MacBook Air; look in $(MAKEDPATH) or type 'make info'
system   := mcair
# Compiler: e.g. gnuX where X stands for version number, e.g. intel13;
#   look at $(MAKEDPATH)/$(system).alias for shortcuts such as gnu for gnuX or type 'make info'
compiler := gnu
# Releases: debug, release, true (last two are equal)
release  := debug
# Netcdf versions (Network Common Data Form): netcdf3, netcdf4, [anything else]
netcdf   := netcdf4
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
# MPI parallelization - experimental: true, [anything else]
mpi      :=
# Linking: static, shared, dynamic (last two are equal)
static   := shared

# The Makefile sets the following variables depending on the above options:
# FC, FCFLAGS, F90, F90FLAGS, CC, CFLAGS, CPP, DEFINES, INCLUDES, LD, LDFLAGS, LIBS
# flags, defines, etc. will be set incremental. They will be initialised with
# the following EXTRA_* variables. This allows for example to set an extra compiler
# option or define a preprocessor variable such as: EXTRA_DEFINES := -DNOGUI -DDPREC

# The Makefile compiles all files found in the source directories.
# If you want excludes files from compilation, set EXCLUDE_FILES, e.g.
# make EXCLUDE_FILES="*mpi*.f90"

# Specific notes
# If you encounter error messages during linking such as
#     ... relocation truncated to fit: R_X86_64_PC32 against ...
# then you ran out of memory address space, i.e. some hard-coded numbers in the code got too big.
# Check that you have set the 64-bit addressing model in the F90FLAGS and LDFAGS: -m64
# On *nix systems, you can set the addressing model with -mcmodel=medium (F90FLAGS and LDFAGS) for gfortran and intel.
# Intel might also need -shared-intel at the LDFLAGS, i.e.
#     EXTRA_F90FLAGS := -mcmodel=medium
#     EXTRA_LDFLAGS  := -mcmodel=medium -shared-intel
#
# If you encouter the following error with the intel compiler (compiler bug):
#      0_10708
#     : catastrophic error: **Internal compiler error: internal abort** Please report this error along with the
#     circumstances in which it occurred in a Software Problem Report.
#      Note: File and line given may not be explicit cause of this error.
# then you probably assume the F2003 feature that arrays can be allocated as a result of a function.
# Add the affected file to the list
#     INTEL_EXCLUDE
# below. This will not set the compiler flag -assume realloc-lhs.
# If this does not work, try to reduce the optimisation in the make.config files (e.g. -O1)

# Specific notes on optimisation and debugging
# INTEL optimisation: -fast (=-ipo -O3 -static)
#     -fast             Multifile interprocedure optimization
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
#     -C=undefined is also checking 0-strings. Function nonull in JAMS mo_string_utils will stop with error.
#     -C=undefined must be used on all routines, i.e. also on netcdf for example.
#                  This means that all tests do not work which use netcdf and/or lapack.
#     -C=intovf    check integer overflow, which is intentional in JAMS mo_xor4096.

# Special compilation flags 
EXTRA_FCFLAGS  :=
EXTRA_F90FLAGS :=
EXTRA_DEFINES  :=
EXTRA_INCLUDES :=
EXTRA_LDFLAGS  :=
EXTRA_LIBS     :=
EXTRA_CFLAGS   :=

# Intel F2003 -assume realloc-lhs
INTEL_EXCLUDE  :=

# Exclude specific files from compilation
EXCLUDE_FILES  :=

# Fortran 90 suffixes: .f90 .F90 .f95 .F95 .f03 .F03 .f08 .F08
F90SUFFIXES := .f90 .F90 .f95 .F95 .f03 .F03 .f08 .F08
# Fortran 77 suffixes: .f .F .for .FOR .f77 .F77 .ftn .FTN
F77SUFFIXES := .f .F .for .FOR .f77 .F77 .ftn .FTN
# C suffixes: .c .C .cc .CC
CSUFFIXES   := .c .C .cc .CC
# Library suffixes: .a .so .dylib
LIBSUFFIXES := .a .so .dylib

#
# --- PATHS ------------------------------------------------
#

# Make absolute paths from relative paths - there should be no space nor comment at the end of the next lines
SRCPATH1   := $(word 1, $(SRCPATH))
SRCPATH1   := $(abspath $(SRCPATH1:~%=${HOME}%))
override SRCPATH    := $(abspath $(SRCPATH:~%=${HOME}%))
override PROGPATH   := $(abspath $(PROGPATH:~%=${HOME}%))
override CONFIGPATH := $(abspath $(CONFIGPATH:~%=${HOME}%))
override MAKEDPATH  := $(abspath $(MAKEDPATH:~%=${HOME}%))
override CHECKPATH  := $(abspath $(CHECKPATH:~%=${HOME}%))
override DOXCONFIG  := $(abspath $(DOXCONFIG:~%=${HOME}%))
# $(info "DOXCONFIG: "$(DOXCONFIG))

# Only Prog or Lib
ifneq ($(and $(strip $(PROGNAME)),$(strip $(LIBNAME))),)
    $(error Error: only one of PROGNAME or LIBNAME can be given.)
else ifeq ($(or $(strip $(PROGNAME)),$(strip $(LIBNAME))),)
    $(error Error: PROGNAME or LIBNAME must be given.)
else ifneq ($(strip $(PROGNAME)),)
    ifeq ($(findstring //, /$(PROGNAME)),)
        override PROGNAME := $(PROGPATH)/$(strip $(PROGNAME))
        LIBNAME  :=
    endif
else
    ifeq ($(findstring //, /$(LIBNAME)),)
        override LIBNAME  := $(PROGPATH)/$(strip $(LIBNAME))
        PROGNAME :=
    endif
endif

# allow release=true and debug=true; debug comes from command line only and supercedes release
irelease := $(if $(debug),debug,$(release:true=release))

# this makefile
THISMAKEFILE := $(lastword $(MAKEFILE_LIST))

# dependency files creation script 
MAKEDSCRIPT := make.d.py
MAKEDPROG   := $(MAKEDPATH)/$(MAKEDSCRIPT)

# .PHONY targets
# some targets should not compile the code, e.g. documentation
# but some targets should not compile but be aware of the source files, e.g. clean
iphony    := False
iphonyall := False
ifneq ($(strip $(MAKECMDGOALS)),)
    ifneq ($(filter $(strip $(MAKECMDGOALS)),check test html latex pdf doxygen),)
        iphony := True
    endif
    ifneq (,$(filter $(strip $(MAKECMDGOALS)),check test html latex pdf doxygen info clean cleanclean distclean cleancheck checkclean cleantest testclean cleancleancheck checkcleanclean cleancleantest testcleanclean))
        iphonyall := True
    endif
endif

#
# --- CHECK SYSTEM ----------------------------------------------
#

systems := $(shell ls -1 $(CONFIGPATH) | sed -e "/$(MAKEDSCRIPT)/d" -e '/f2html/d' | cut -d '.' -f 1 | sort | uniq)
ifeq (,$(filter $(system),$(systems)))
    $(error Error: system '$(system)' not found: known systems are $(systems))
endif

#
# --- ALIASES ---------------------------------------------------
#

# Include compiler alias on specific systems, e.g. nag for nag53
icompiler := $(compiler)
ALIASINC  := $(CONFIGPATH)/$(system).alias
ifneq ($(strip $(ALIASINC)),)
    include $(ALIASINC)
endif

#
# --- CHECK COMPILER --------------------------------------------
#

compilers := $(shell ls -1 $(CONFIGPATH) | sed -e "/$(MAKEDSCRIPT)/d" -e '/f2html/d' -e '/alias/d' -e '/~$$/d' | grep $(system) | cut -d '.' -f 2- | sort | uniq)
gnucompilers := $(filter gnu%, $(compilers))
nagcompilers := $(filter nag%, $(compilers))
intelcompilers := $(filter intel%, $(compilers))
ifeq (,$(filter $(icompiler),$(compilers)))
    $(error Error: compiler '$(icompiler)' not found: configured compilers for system $(system) are $(compilers))
endif

#
# --- SOURCE FILES ---------------------------------------------------
#

# System specific files
ifeq (False,$(iphony))
    SSRCS := $(foreach suff,$(system),$(wildcard $(addsuffix /*$(suff), $(SRCPATH))))
endif
SOBJS := $(foreach suff, $(system), $(patsubst %.$(suff), %, $(filter %$(suff), $(SSRCS))))

# Available Fortran90 source files
ifeq (False,$(iphony))
    SRCS1 := $(foreach suff,$(F90SUFFIXES),$(wildcard $(addsuffix /*$(suff), $(SRCPATH))))
endif
# exclude user-defined $(EXCLUDE_FILES)
SRCS  := $(foreach f,$(SRCS1),$(if $(findstring $(f),$(abspath $(EXCLUDE_FILES))),,$(f)))
# source files but with suffix .o
OSRCS := $(foreach suff, $(F90SUFFIXES), $(patsubst %$(suff), %.o, $(filter %$(suff), $(SRCS))))
# object files
OBJS  := $(join $(dir $(OSRCS)), $(addprefix .$(strip $(icompiler)).$(strip $(irelease))/,$(notdir $(OSRCS))))
# dependency files
DOBJS := $(OBJS:.o=.d)
# g90 debug files of NAG compiler are in current directory or in source directory
GOBJS := $(addprefix $(CURDIR)/,$(patsubst %.o,%.g90,$(notdir $(OBJS)))) $(patsubst %.o,%.g90,$(OSRCS))

# Fortran77
ifeq (False,$(iphony))
    FSRCS1 := $(foreach suff,$(F77SUFFIXES),$(wildcard $(addsuffix /*$(suff), $(SRCPATH))))
endif
FSRCS  := $(foreach f,$(FSRCS1),$(if $(findstring $(f),$(abspath $(EXCLUDE_FILES))),,$(f)))
FOSRCS := $(foreach suff, $(F77SUFFIXES), $(patsubst %$(suff), %.o, $(filter %$(suff), $(FSRCS))))
FOBJS  := $(join $(dir $(FOSRCS)), $(addprefix .$(strip $(icompiler)).$(strip $(irelease))/,$(notdir $(FOSRCS))))
FDOBJS := $(FOBJS:.o=.d)
FGOBJS := $(addprefix $(CURDIR)/,$(patsubst %.o,%.g90,$(notdir $(FOBJS)))) $(patsubst %.o,%.g90,$(FOSRCS))

# C
ifeq (False,$(iphony))
    CSRCS1 := $(foreach suff,$(CSUFFIXES),$(wildcard $(addsuffix /*$(suff), $(SRCPATH))))
endif
CSRCS  := $(foreach f,$(CSRCS1),$(if $(findstring $(f),$(abspath $(EXCLUDE_FILES))),,$(f)))
COSRCS := $(foreach suff, $(CSUFFIXES), $(patsubst %$(suff), %.o, $(filter %$(suff), $(CSRCS))))
COBJS  := $(join $(dir $(COSRCS)), $(addprefix .$(strip $(icompiler)).$(strip $(irelease))/,$(notdir $(COSRCS))))
CDOBJS := $(COBJS:.o=.d)

# Libraries
ifeq (False,$(iphony))
    LSRCS1 := $(foreach suff,$(LIBSUFFIXES),$(wildcard $(addsuffix /*$(suff), $(SRCPATH))))
endif
LSRCS  := $(foreach f,$(LSRCS1),$(if $(findstring $(f),$(abspath $(EXCLUDE_FILES))),,$(f)))
LOSRCS := $(foreach suff, $(LIBSUFFIXES), $(patsubst %$(suff), %.o, $(filter %$(suff), $(LSRCS))))
LOBJS  := $(addprefix -L,$(dir $(SRCPATH))) $(addprefix -l, $(patsubst lib%, %, $(notdir $(LOSRCS))))

#
# --- DEFAULTS ---------------------------------------------------
#

# These variables will be used to compile and link, and therefore expanded below
# Fortran77
FC       :=
FCFLAGS  := $(EXTRA_FCFLAGS)
# Fortran90
F90      :=
F90FLAGS := $(EXTRA_F90FLAGS)
# C
CC       :=
CFLAGS   := $(EXTRA_CFLAGS)
# all
CPP      :=
DEFINES  := $(EXTRA_DEFINES)
INCLUDES := $(EXTRA_INCLUDES) $(addprefix -I,$(SRCPATH))
# linking
LD       :=
LDFLAGS  := $(EXTRA_LDFLAGS)
LIBS     := $(EXTRA_LIBS) $(addprefix -L,$(SRCPATH))
# library
AR       := ar
ARFLAGS  := -ru
RANLIB   := ranlib

#
# --- COMPILER / MACHINE SPECIFIC --------------------------------
#

# Set path where all the .mod, .o, etc. files will be written, set before include $(MAKEINC)
OBJPATH := $(addsuffix /.$(strip $(icompiler)).$(strip $(irelease)), $(SRCPATH))

# Files with lists of file names
OBJPATH1 := $(addsuffix /.$(strip $(icompiler)).$(strip $(irelease)), $(SRCPATH1))
SRCSFILE := $(OBJPATH1)/make.d.srcs
OBJSFILE := $(OBJPATH1)/make.d.objs
DOBJSFILE := $(OBJPATH1)/make.d.dobjs
FSRCSFILE := $(OBJPATH1)/make.d.fsrcs
FOBJSFILE := $(OBJPATH1)/make.d.fobjs
FDOBJSFILE := $(OBJPATH1)/make.d.fdobjs
CSRCSFILE := $(OBJPATH1)/make.d.csrcs
COBJSFILE := $(OBJPATH1)/make.d.cobjs
CDOBJSFILE := $(OBJPATH1)/make.d.cdobjs
LSRCSFILE := $(OBJPATH1)/make.d.lsrcs
LOBJSFILE := $(OBJPATH1)/make.d.lobjs
$(shell if [[ ! -d $(OBJPATH1) ]] ; then mkdir -p $(OBJPATH1) ; fi)
$(shell if [[ -f $(SRCSFILE) ]]   ; then rm $(SRCSFILE)   ; fi ; echo $(SRCS)   | tr ' ' '\n' >> $(SRCSFILE))
$(shell if [[ -f $(OBJSFILE) ]]   ; then rm $(OBJSFILE)   ; fi ; echo $(OBJS)   | tr ' ' '\n' >> $(OBJSFILE))
$(shell if [[ -f $(DOBJSFILE) ]]  ; then rm $(DOBJSFILE)  ; fi ; echo $(DOBJS)  | tr ' ' '\n' >> $(DOBJSFILE))
$(shell if [[ -f $(FSRCSFILE) ]]  ; then rm $(FSRCSFILE)  ; fi ; echo $(FSRCS)  | tr ' ' '\n' >> $(FSRCSFILE))
$(shell if [[ -f $(FOBJSFILE) ]]  ; then rm $(FOBJSFILE)  ; fi ; echo $(FOBJS)  | tr ' ' '\n' >> $(FOBJSFILE))
$(shell if [[ -f $(FDOBJSFILE) ]] ; then rm $(FDOBJSFILE) ; fi ; echo $(FDOBJS) | tr ' ' '\n' >> $(FDOBJSFILE))
$(shell if [[ -f $(CSRCSFILE) ]]  ; then rm $(CSRCSFILE)  ; fi ; echo $(CSRCS)  | tr ' ' '\n' >> $(CSRCSFILE))
$(shell if [[ -f $(COBJSFILE) ]]  ; then rm $(COBJSFILE)  ; fi ; echo $(COBJS)  | tr ' ' '\n' >> $(COBJSFILE))
$(shell if [[ -f $(CDOBJSFILE) ]] ; then rm $(CDOBJSFILE) ; fi ; echo $(CDOBJS) | tr ' ' '\n' >> $(CDOBJSFILE))
$(shell if [[ -f $(LSRCSFILE) ]]  ; then rm $(LSRCSFILE)  ; fi ; echo $(LSRCS)  | tr ' ' '\n' >> $(LSRCSFILE))
$(shell if [[ -f $(LOBJSFILE) ]]  ; then rm $(LOBJSFILE)  ; fi ; echo $(LOBJS)  | tr ' ' '\n' >> $(LOBJSFILE))

# Mac OS X is special, there is (almost) no static linking.
# Mac OS X does not work with -rpath. Set DYLD_LIBRARY_PATH if needed.
iOS := $(shell uname -s)
istatic := $(static)
ifneq (,$(filter $(iOS),Darwin))
    istatic := dynamic
endif

# Include the individual configuration files
MAKEINC := $(addsuffix /$(system).$(icompiler), $(abspath $(CONFIGPATH:~%=${HOME}%)))
ifeq ($(strip $(MAKEINC)),)
    $(error Error: Individual configuration file '$(MAKEINC)' not found.)
endif
include $(MAKEINC)

# Always use -DCFORTRAN for mixed C and Fortran compilations
DEFINES += -DCFORTRAN

# Start group for cyclic search in static linking
iLIBS :=
ifeq ($(istatic),static)
    iLIBS += -Bstatic -Wl,--start-group
else
    ifneq (,$(filter $(iOS),Darwin))
        iLIBS += -Wl,-dynamic
    else
        iLIBS += -Bdynamic
    endif
endif

ifneq (,$(SOBJS))
    $(foreach ff,$(SOBJS),$(shell if [[ -f $(ff) ]] ; then isdiff=`diff $(ff) $(ff).$(system)` ; if [[ "$${isdiff}z" != "z" ]] ; then cp $(ff).$(system) $(ff) ; fi ; else cp $(ff).$(system) $(ff) ; fi))
endif

# --- LINKER ---------------------------------------------------
# Link with the fortran compiler if fortran code
ifneq ($(SRCS)$(FSRCS),)
    LD := $(F90)
else
    LD := $(CC)
endif

# --- INCLUDES/LIBS/FLAGS/DEFINES/RPATH --------------------------
SDIRS :=
ifneq (,$(filter $(mkl),mkl mkl95))
    # First mkl95 then mkl for .mod files other then intel
    ifeq ($(mkl),mkl95)
        SDIRS += MKL95DIR
    endif
    SDIRS += MKLDIR
endif
ifneq (,$(filter $(netcdf),netcdf3 netcdf4))
    SDIRS += NCFDIR NCDIR
    ifeq ($(netcdf),netcdf4)
        SDIRS += HDF5DIR SZDIR CURLDIR ZDIR
    endif
endif
ifeq ($(proj),true)
    SDIRS += PROJ4DIR FPROJDIR
endif
ifeq ($(lapack),true)
    SDIRS += LAPACKDIR
    SDIRS += BLASDIR
endif
ifeq ($(mpi),true)
    SDIRS += MPIDIR
endif
ifneq (,$(filter $(imsl),vendor imsl))
    SDIRS += IMSLDIR
endif
# function (=) used below to set flag if given
if_flag   = $(if $($(dir:DIR=FLAG)),$($(dir:DIR=FLAG)))
# include flags such as -I/usr/local/include
INCLUDES += $(foreach dir,$(SDIRS),$(if $($(dir:DIR=INC)),-I$($(dir:DIR=INC)),$(if $($(dir)),-I$($(dir))/include)))
# lib flags such as -L/usr/local/lib -lcurl
iLIBS    += $(foreach dir,$(SDIRS),$(if $($(dir:DIR=LIB)),-L$($(dir:DIR=LIB)) $(if_flag),$(if $($(dir)),-L$($(dir))/lib $(if_flag))))
# lib flags that do not have a directory such as -lz or -framework Accelerate
iLIBS    += $(foreach dir,$(SDIRS),$(if $(or $($(dir)),$($(dir:DIR=LIB))),,$(if_flag)))
# rpath
WL       := -Wl,-rpath,
RPATH    += $(foreach dir,$(SDIRS),$(if $($(dir:DIR=LIB)),$(WL)$($(dir:DIR=LIB)),$(if $($(dir)),$(WL)$($(dir))/lib)))
# defines
DEFINES  += $(foreach dir,$(SDIRS),$(if $($(dir:DIR=DEF)),$($(dir:DIR=DEF))))


# # --- MKL ---------------------------------------------------
# ifneq (,$(filter $(mkl),mkl mkl95))
#     ifneq (,$(filter $(imsl),vendor imsl))
#        iLIBS += -lmkl_intel_thread #-lpthread
#     else
#         ifeq ($(openmp),true)
#             iLIBS += -lmkl_intel_thread #-lpthread
#         else
#             iLIBS += -lmkl_sequential #-lpthread
#         endif
#     endif
#     ifeq ($(openmp),true)
#         ifeq (,$(filter $(icompiler),$(intelcompilers)))
#             iLIBS += -L$(INTELLIB) -liomp5
#             RPATH += -Wl,-rpath,$(INTELLIB)
#         endif
#     endif
# endif

# --- MPI ---------------------------------------------------
MPI_F90FLAGS :=
MPI_FCFLAGS  :=
MPI_CFLAGS   :=
MPI_LDFLAGS  :=
ifeq ($(mpi),true)
    MPIINC ?= $(MPIDIR)/include
    MPILIB ?= $(MPIDIR)/lib
    MPIBIN ?= $(MPIDIR)/bin
    MPI_F90FLAGS += $(shell $(MPIBIN)/mpif90 --showme:compile)
    MPI_FCFLAGS  += $(shell $(MPIBIN)/mpif77 --showme:compile)
    MPI_CFLAGS   += $(shell $(MPIBIN)/mpicc --showme:compile)
    ifeq ($(LD),$(F90))
        MPI_LDFLAGS += $(shell $(MPIBIN)/mpif90 --showme:link)
    else
        MPI_LDFLAGS += $(shell $(MPIBIN)/mpicc --showme:link)
    endif
    INCLUDES += -I$(MPILIB) # mpi.h in lib and not include <- strange
endif

# --- OPENMP ---------------------------------------------------
iopenmp :=
ifeq ($(openmp),true)
    F90FLAGS += $(F90OMPFLAG)
    FCFLAGS  += $(FCOMPFLAG)
    CFLAGS   += $(COMPFLAG)
    LDFLAGS  += $(LDOMPFLAG)
    DEFINES  += $(OMPDEFINE)
else ifneq (,$(filter $(imsl),vendor imsl))
    # IMSL needs openmp during linking in any case
    LDFLAGS  += $(LDOMPFLAG)
endif

# --- DOXYGEN ---------------------------------------------------
DOXYGEN  := $(if $(DOXYGENDIR),$(strip $(DOXYGENDIR))/doxygen,$(shell which doxygen 2>/dev/null))
DOTPATH  := $(if $(DOTDIR),$(strip $(DOTDIR)),$(dir $(shell which dot 2>/dev/null)))
TEXPATH  := $(if $(TEXDIR),$(strip $(TEXDIR)),$(dir $(shell which latex 2>/dev/null)))
PERLPATH := $(if $(PERLDIR),$(strip $(PERLDIR)),$(dir $(shell which perl 2>/dev/null)))

# --- INTEL F2003 REALLOC-LHS ---------------------------------------
ifneq (,$(filter $(icompiler),$(intelcompilers)))
    F90FLAGS1 := $(subst -assume realloc-lhs,,"$(F90FLAGS)")
else
    F90FLAGS1 := $(F90FLAGS)
endif

#
# --- FINISH SETUP ---------------------------------------------------
#

ifeq ($(irelease),debug)
    DEFINES += -DDEBUG
endif

# Mac OS X is special, there is (almost) no static linking; otherwise close static group
ifeq ($(istatic),static)
    iLIBS += -Wl,--end-group
endif

# The NAG compiler links via gcc so that one has to give -Wl twice and double commas for the option
# i.e. instead of  -Wl,rpath,/path   you need   -Wl,-Wl,,rpath,,/path
ifneq (,$(filter $(icompiler),$(nagcompilers)))
    comma  := ,
    iiLIBS := $(subst -Wl,-Wl$(comma)-Wl,$(subst $(comma),$(comma)$(comma),$(iLIBS)))
    iRPATH := $(subst -Wl,-Wl$(comma)-Wl,$(subst $(comma),$(comma)$(comma),$(RPATH)))
else
    iiLIBS := $(iLIBS)
    iRPATH := $(RPATH)
endif
LIBS += $(iiLIBS)
# Only Linux and Solaris can use -rpath in executable
ifeq (,$(filter $(iOS),Darwin))
    LIBS += $(iRPATH)
endif

# export LD_LIBRARY_PATH of make.config files
ifneq ($(LDPATH),)
    empty:=
    space:= $(empty) $(empty)
    export LD_LIBRARY_PATH=$(subst $(space),$(empty),$(LDPATH))
endif

INCLUDES += $(addprefix -I,$(OBJPATH))

#
# --- TARGETS ---------------------------------------------------
#

#.SUFFIXES: .f90 .F90 .f95 .F95 .f03 .F03 .f08 .F08 .f .F .for .FOR .ftn .FTN .c .C .cc .CC .d .o .a .so .dylib
.SUFFIXES:

.PHONY: clean cleanclean distclean cleantest testclean checkclean cleancheck cleancleantest testcleanclean checkcleanclean cleancleancheck html latex pdf doxygen check test info

all: $(PROGNAME) $(LIBNAME)

# Link program
$(PROGNAME): $(OBJS) $(FOBJS) $(COBJS)
	@echo "Linking program"
	$(LD) $(LDFLAGS) -o $(PROGNAME) $(OBJS) $(FOBJS) $(COBJS) $(LIBS) $(LOBJS) $(MPI_LDFLAGS)

# Link library
$(LIBNAME): $(DOBJS) $(FDOBJS) $(CDOBJS) $(OBJS) $(FOBJS) $(COBJS)
	@echo "Linking library"
	$(AR) $(ARFLAGS) $(LIBNAME) $(OBJS) $(FOBJS) $(COBJS)
	$(RANLIB) $(LIBNAME)

# Get dependencies
$(DOBJS):
	@if [[ ! -d $(dir $@) ]] ; then mkdir -p $(dir $@) ; fi
	@nobj=$$(grep -n -w -F $@  $(DOBJSFILE) | sed 's/:.*//') ; \
	src=$$(sed -n $${nobj}p $(SRCSFILE)) ; \
	$(CPP) -C -P $(DEFINES) $(INCLUDES) $$src > $$src.pre 2>/dev/null ; \
	$(MAKEDPROG) -f $$src $$src.pre .$(strip $(icompiler)).$(strip $(irelease)) $(SRCSFILE) $(FSRCSFILE) ; \
	\rm $$src.pre

$(FDOBJS):
	@if [[ ! -d $(dir $@) ]] ; then mkdir -p $(dir $@) ; fi
	@nobj=$$(grep -n -w -F $@ $(FDOBJSFILE) | sed 's/:.*//') ; \
	src=$$(sed -n $${nobj}p $(FSRCSFILE)) ; \
	obj=$$(sed -n $${nobj}p $(FOBJSFILE)) ; \
	dobj=$$(sed -n $${nobj}p $(FOBJSFILE) | sed 's|\.o[[:blank:]]*$$|.d|') ; \
	echo "$$obj $$dobj : $$src" > $$dobj

$(CDOBJS):
	@if [[ ! -d $(dir $@) ]] ; then mkdir -p $(dir $@) ; fi
	@nobj=$$(grep -n -w -F $@ $(CDOBJSFILE) | sed 's/:.*//') ; \
	src=$$(sed -n $${nobj}p $(CSRCSFILE)) ; \
	pobj=$(dir $@) ; psrc=$(dir $$src) ; \
	$(CC) -E $(DEFINES) $(INCLUDES) -MM $$src | sed "s|.*:|$(patsubst %.d,%.o,$@) $@ :|" > $@

# Compile
$(OBJS):
ifneq (,$(filter $(icompiler),gnu41 gnu42))
	@nobj=$$(grep -n -w -F $@ $(OBJSFILE) | sed 's/:.*//') ; \
	src=$$(sed -n $${nobj}p $(SRCSFILE)) ; \
	ssrc=$$(basename $$(sed -n $${nobj}p $(SRCSFILE))) ; \
	tmp=$@.$$(echo $${src} | sed 's/.*\.//') ; \
	doex=$$(echo $(INTEL_EXCLUDE) | grep -i "$${ssrc}" -) ; \
	f90flag=$$(if [[ "$${doex}" != "" ]] ; then echo "$(F90FLAGS1)" ; else echo "$(F90FLAGS)" ; fi) ; \
	echo "$(F90) -E $(DEFINES) $(INCLUDES) $${f90flag} $${src} | sed 's/^#[[:blank:]]\{1,\}[[:digit:]]\{1,\}.*$$//' > $${tmp}" ; \
	$(F90) -E $(DEFINES) $(INCLUDES) $${f90flag} $${src} | sed 's/^#[[:blank:]]\{1,\}[[:digit:]]\{1,\}.*$$//' > $${tmp} ; \
	echo "$(F90) $(DEFINES) $(INCLUDES) $(MPI_F90FLAGS) $(F90FLAGS) $(MODFLAG)$(dir $@) -c $${tmp} -o $@" ; \
	$(F90) $(DEFINES) $(INCLUDES) $(MPI_F90FLAGS) $(F90FLAGS) $(MODFLAG)$(dir $@) -c $${tmp} -o $@ ; \
	rm $${tmp}
else
	@nobj=$$(grep -n -w -F $@ $(OBJSFILE) | sed 's/:.*//') ; \
	src=$$(sed -n $${nobj}p $(SRCSFILE)) ; \
	ssrc=$$(basename $$(sed -n $${nobj}p $(SRCSFILE))) ; \
	doex=$$(echo $(INTEL_EXCLUDE) | grep -i "$${ssrc}" -) ; \
	f90flag=$$(if [[ "$${doex}" != "" ]] ; then echo "$(F90FLAGS1)" ; else echo "$(F90FLAGS)" ; fi) ; \
	echo $(F90) $(DEFINES) $(INCLUDES) $(MPI_F90FLAGS) $${f90flag} $(MODFLAG)$(dir $@) -c $${src} -o $@ ; \
	$(F90) $(DEFINES) $(INCLUDES) $(MPI_F90FLAGS) $${f90flag} $(MODFLAG)$(dir $@) -c $${src} -o $@
endif

$(FOBJS):
ifneq (,$(filter $(icompiler),gnu41 gnu42))
	@nobj=$$(grep -n -w -F $@ $(FOBJSFILE) | sed 's/:.*//') ; \
	src=$$(sed -n $${nobj}p $(FSRCSFILE)) ; \
	tmp=$@.$$(echo $${src} | sed 's/.*\.//') ; \
	echo "$(FC) -E $(DEFINES) $(INCLUDES) $(FCFLAGS) $${src} | sed 's/^#[[:blank:]]\{1,\}[[:digit:]]\{1,\}.*$$//' > $${tmp}" ; \
	$(FC) -E $(DEFINES) $(INCLUDES) $(FCFLAGS) $${src} | sed 's/^#[[:blank:]]\{1,\}[[:digit:]]\{1,\}.*$$//' > $${tmp} ; \
	echo "$(FC) $(DEFINES) $(INCLUDES) $(MPI_FCFLAGS) $(FCFLAGS) -c $${tmp} -o $@" ; \
	$(FC) $(DEFINES) $(INCLUDES) $(MPI_FCFLAGS) $(FCFLAGS) -c $${tmp} -o $@ ; \
	rm $${tmp}
else
	@nobj=$$(grep -n -w -F $@ $(FOBJSFILE) | sed 's/:.*//') ; \
	src=$$(sed -n $${nobj}p $(FSRCSFILE)) ; \
	echo $(FC) $(DEFINES) $(INCLUDES) $(MPI_FCFLAGS) $(FCFLAGS) -c $$src -o $@ ; \
	$(FC) $(DEFINES) $(INCLUDES) $(MPI_FCFLAGS) $(FCFLAGS) -c $$src -o $@
endif

$(COBJS):
	@nobj=$$(grep -n -w -F $@ $(COBJSFILE) | sed 's/:.*//') ; \
	src=$$(sed -n $${nobj}p $(CSRCSFILE)) ; \
	echo $(CC) $(DEFINES) $(INCLUDES) $(MPI_CFLAGS) $(CFLAGS) -c $${src} -o $@ ; \
	$(CC) $(DEFINES) $(INCLUDES) $(MPI_CFLAGS) $(CFLAGS) -c $${src} -o $@

# Helper Targets
clean:
ifneq (,$(SOBJS))
	for ff in $(SOBJS) ; do if [[ -f $${ff}.default ]] ; then cp $${ff}.default $${ff} ; fi ; done
endif
ifneq ($(strip $(OBJS)),)
	rm -f $(OBJS)
endif
ifneq ($(strip $(DOBJS)),)
	rm -f $(DOBJS)
endif
ifneq ($(strip $(FOBJS)),)
	rm -f $(FOBJS)
endif
ifneq ($(strip $(FDOBJS)),)
	rm -f $(FDOBJS)
endif
ifneq ($(strip $(COBJS)),)
	rm -f $(COBJS)
endif
ifneq ($(strip $(CDOBJS)),)
	rm -f $(CDOBJS)
endif
ifneq ($(strip $(GOBJS)),)
	rm -f $(GOBJS)
endif
ifneq ($(strip $(FGOBJS)),)
	rm -f $(FGOBJS)
endif
	rm -f $(addsuffix /*.mod, $(OBJPATH))
	rm -f $(addsuffix /*.pre, $(SRCPATH))
ifneq ($(PROGNAME),)
	rm -f  "$(PROGNAME)"
	rm -rf "$(PROGNAME)".dSYM
endif
ifneq ($(LIBNAME),)
	rm -f "$(LIBNAME)"
endif
ifneq ($(SRCPATH),)
	rm -rf $(addsuffix /.$(strip $(icompiler)).$(strip $(irelease)),$(SRCPATH))
endif
	rm -f *make_check_test_file

cleanclean:
	for irr in release debug ; do \
	    for icc in $(compilers) ; do \
	        $(MAKE) -f $(THISMAKEFILE) system=$(system) release=$$irr compiler=$$icc \
	        MAKEDPATH=$(MAKEDPATH) SRCPATH="$(SRCPATH)" PROGPATH=$(PROGPATH) \
	        CONFIGPATH=$(CONFIGPATH) PROGNAME=$(PROGNAME) \
	        clean ; \
	    done ; \
	done
	rm -rf $(addsuffix /.*.r*, $(SRCPATH))
	rm -rf $(addsuffix /.*.d*, $(SRCPATH))
	rm -rf $(addsuffix /html, $(SRCPATH))
	@if [ -f "$(DOXCONFIG)" ] ; then rm -rf $(PROGPATH)/latex ; fi
	@if [ -f "$(DOXCONFIG)" ] ; then rm -rf $(PROGPATH)/html ; fi

distclean: cleanclean

cleancheck:
	for i in $(shell ls -d $(CHECKPATH)/test* $(CHECKPATH)/check* 2> /dev/null) ; do \
	    $(MAKE) -f $(THISMAKEFILE) system=$(system) release=$(irelease) compiler=$(compiler) SRCPATH=$$i clean ; \
	done

cleantest: cleancheck

checkclean: cleancheck

testclean: cleancheck

cleancleancheck:
	for i in $(shell ls -d $(CHECKPATH)/test* $(CHECKPATH)/check* 2> /dev/null) ; do \
	    $(MAKE) -f $(THISMAKEFILE) system=$(system) release=$(irelease) compiler=$(compiler) SRCPATH=$$i cleanclean ; \
	done

cleancleantest: cleancleancheck

checkcleanclean: cleancleancheck

testcleanclean: cleancleancheck

check:
ifeq ($(PROGNAME),)
	$(error Error: check and test must be done with given PROGNAME.)
endif
	for i in $(shell ls -d $(CHECKPATH)/test* $(CHECKPATH)/check* 2> /dev/null) ; do \
	    rm -f "$(PROGNAME)" ; \
	    j=$$(echo $${i} | grep -E '(minpack|netcdf3|qhull)$$') ; \
	    inetcdf=$(netcdf) ; \
	    libextra= ; \
	    incextra= ; \
	    defextra= ; \
	    if [ "$${j}z" != "z" ] ; then \
	        ldir=$${i##*_} ; \
	        lname="lib$${ldir}.a" ; \
	        libextra="-L. -l$${ldir}" ; \
	        case $${i} in \
	            *minpack) true ;; \
	            *netcdf3) inetcdf= ; \
	                      incextra="-I$${i}/../../netcdf3/.$(strip $(icompiler)).$(strip $(irelease))" ; \
	                      defextra='-DNETCDF3' ;; \
	            *qhull)   true ;; \
	        esac ; \
	        $(MAKE) -f $(THISMAKEFILE) -s \
	            MAKEDPATH=$(MAKEDPATH) SRCPATH="$${i}"/../../$${ldir} PROGPATH=$(PROGPATH) \
	            CONFIGPATH=$(CONFIGPATH) PROGNAME= LIBNAME=$${lname} \
	            system=$(system) release=$(irelease) compiler=$(compiler) \
	            netcdf=$${inetcdf} static=$(static) proj=$(proj) imsl=$(imsl) mkl=$(mkl) \
	            lapack=$(lapack) openmp=$(openmp) > /dev/null ; \
	    fi ; \
	    $(MAKE) -f $(THISMAKEFILE) -s \
	        MAKEDPATH=$(MAKEDPATH) SRCPATH="$${i}" PROGPATH=$(PROGPATH) \
	        CONFIGPATH=$(CONFIGPATH) PROGNAME=$(PROGNAME) \
	        system=$(system) release=$(irelease) compiler=$(compiler) \
	        netcdf=$${inetcdf} static=$(static) proj=$(proj) imsl=$(imsl) mkl=$(mkl) \
	        lapack=$(lapack) openmp=$(openmp) \
	        EXTRA_LIBS="$${libextra}" EXTRA_DEFINES="$${defextra}" EXTRA_INCLUDES="$${incextra}" > /dev/null \
	    && { $(PROGNAME) 2>&1 | grep -E '(o\.k\.|failed)' ;} ; status=$$? ; \
	    if [ $${status} != 0 ] ; then echo "$${i} failed!" ; fi ; \
	    $(MAKE) -f $(THISMAKEFILE) -s \
	        MAKEDPATH=$(MAKEDPATH) SRCPATH="$${i}" PROGPATH=$(PROGPATH) \
	        CONFIGPATH=$(CONFIGPATH) PROGNAME=$(PROGNAME) \
	        system=$(system) release=$(irelease) compiler=$(compiler) clean ; \
	    if [ "$${j}z" != "z" ] ; then \
	        $(MAKE) -f $(THISMAKEFILE) -s \
	            MAKEDPATH=$(MAKEDPATH) SRCPATH="$${i}"/../../$${ldir} PROGPATH=$(PROGPATH) \
	            CONFIGPATH=$(CONFIGPATH) PROGNAME= LIBNAME=$${lname} \
	            system=$(system) release=$(irelease) compiler=$(compiler) clean ; \
	    fi ; \
	done

test: check

depend: dependencies

dependencies:
	@for i in $(DOBJS) ; do \
	    nobj=$$(grep -n -w -F $${i} $(DOBJSFILE) | sed 's/:.*//') ; \
	    src=$$(sed -n $${nobj}p $(SRCSFILE)) ; \
	    obj=$$(sed -n $${nobj}p $(OBJSFILE)) ; \
	    if [ $${src} -nt $${obj} ] ; then rm $${i} ; fi ; \
	done
	@for i in $(FDOBJS) ; do \
	    nobj=$$(grep -n -w -F $${i} $(FDOBJSFILE) | sed 's/:.*//') ; \
	    src=$$(sed -n $${nobj}p $(FSRCSFILE)) ; \
	    obj=$$(sed -n $${nobj}p $(FOBJSFILE)) ; \
	    if [ $${src} -nt $${obj} ] ; then rm $${i} ; fi ; \
	done
	@for i in $(CDOBJS) ; do \
	    nobj=$$(grep -n -w -F $${i} $(CDOBJSFILE) | sed 's/:.*//') ; \
	    src=$$(sed -n $${nobj}p $(CSRCSFILE)) ; \
	    obj=$$(sed -n $${nobj}p $(COBJSFILE)) ; \
	    if [ $${src} -nt $${obj} ] ; then rm $${i} ; fi ; \
	done
	@rm -f $(addsuffix /$(MAKEDSCRIPT:.py=.dict), $(OBJPATH))

doxygen:
	cat $(DOXCONFIG) | \
	    sed -e "/^PERL_PATH/s|=.*|=$(PERLPATH)|" | \
	    sed -e "/^DOT_PATH/s|=.*|=$(DOTPATH)|" | env PATH=${PATH}:$(TEXPATH) $(DOXYGEN) -

html:
ifneq ($(DOXCONFIG),)
	cat $(DOXCONFIG) | \
	    sed -e "/^PERL_PATH/s|=.*|=$(PERLPATH)|" | \
	    sed -e "/^DOT_PATH/s|=.*|=$(DOTPATH)|" | env PATH=${PATH}:$(TEXPATH) $(DOXYGEN) -
else
	for i in $(SRCPATH) ; do $(TOOLPATH)/f2html -f $(TOOLPATH)/f2html.fgenrc -d $$i/html $$i ; done
endif

latex: pdf

pdf: doxygen
	@cd latex ; env PATH=${PATH}:$(TEXPATH) make pdf

help: info

info:
	@echo "JAMS Makefile"
	@echo ""
	@echo "Config"
	@echo "system   = $(system)"
	@echo "compiler = $(compiler)"
	@echo "release  = $(irelease)"
	@echo "netcdf   = $(netcdf)"
	@echo "lapack   = $(lapack)"
	@echo "mkl      = $(mkl)"
	@echo "proj     = $(proj)"
	@echo "imsl     = $(imsl)"
	@echo "openmp   = $(openmp)"
	@echo "static   = $(static)"
	@echo ""
	@echo "Files/Paths"
	@echo "SRCPATH    = $(SRCPATH)"
	@echo "PROGPATH   = $(PROGPATH)"
	@echo "CONFIGPATH = $(CONFIGPATH)"
	@echo "MAKEDPATH  = $(MAKEDPATH)"
	@echo "CHECKPATH  = $(CHECKPATH)"
	@echo "PROGNAME   = $(basename $(PROGNAME))"
	@echo "LIBNAME    = $(basename $(LIBNAME))"
	@echo "FILES      = $(SRCS) $(FORSRCS) $(CSRCS) $(LASRCS)"
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
ifneq ($(strip $(ALIASINC)),)
	@echo ""
	@echo "Compiler aliases for $(system)"
	@sed -n '/ifneq (,$$(filter $$(compiler)/,/endif/p' $(ALIASINC) | \
	 sed -e '/endif/d' -e 's/icompiler ://' | \
	 sed -e 's/ifneq (,$$(filter $$(compiler),//' -e 's/))//' | \
	 paste - - | tr -d '\t' | tr -s ' '
endif
	@echo ""
	@echo "Targets"
	@echo "all (default)  Compile program or library"
	@echo "check          Run all checks in $(CHECKPATH)/test* and $(CHECKPATH)/check* directories"
	@echo "checkclean     alias for cleancheck"
	@echo "clean          Clean compilation of current compiler and release"
	@echo "cleancheck     Cleanclean all test directories $(CHECKPATH)/test* and $(CHECKPATH)/check*"
	@echo "cleanclean     Clean compilations of all releases and all available compilers for current system"
	@echo "cleantest      alias for cleancheck"
	@echo "depend         alias for dependencies"
	@echo "dependencies   Redo dependencies"
	@echo "distclean      alias for cleanclean"
	@echo "doxygen        Run doxygen html with $(DOXPATH)/doxygen.config"
	@echo "html           Run either doxygen html with $(DOXPATH)/doxygen.config or f2html of Jean-Marc Beroud"
	@echo "info           Prints info about current settings and possibilities"
	@echo "latex          alias for pdf"
	@echo "pdf            Run doxygen PDF with $(DOXPATH)/doxygen.config"
	@echo "test           alias for check"
	@echo "testclean      alias for cleancheck"
	@echo ""
	@echo "All possibilities"
	@echo "system      $(shell ls -1 $(CONFIGPATH) | sed -e '/"$(MAKEDSCRIPT)"/d' -e '/f2html/d' | cut -d '.' -f 1 | sort | uniq)"
	@echo "compiler    $(shell ls -1 $(CONFIGPATH) | sed -e '/"$(MAKEDSCRIPT)"/d' -e '/f2html/d' -e '/alias/d' | cut -d '.' -f 2- | sort | uniq)"
	@echo "release     debug release (=true)"
	@echo "netcdf      netcdf3 netcdf4 [anything else]"
	@echo "lapack      true [anything else]"
	@echo "mkl         mkl mkl95 [anything else]"
	@echo "proj        true [anything else]"
	@echo "imsl        vendor imsl [anything else]"
	@echo "openmp      true [anything else]"
	@echo "static      static shared (=dynamic)"

# All dependencies created by python script make.d.py
ifeq (False,$(iphonyall))
    $(info Checking dependencies ...)
    -include $(DOBJS) $(FDOBJS) $(CDOBJS)
endif
