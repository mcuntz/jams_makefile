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
#     targets    all (default), clean, cleanclean
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
#         system      eve, mcimac
#         release     debug, release
#         netcdf      netcdf3, netcdf4
#         static      static, shared, dynamic (last two are equal)
#         proj        true, [anything else]
#         imsl        vendor, imsl, [anything else]
#         mkl         mkl, mkl95, [anything else]
#         lapack      true, [anything else]
#         compiler    intel11, intel12, gnu41, gnu44, gnu45, absoft
#                     alternative names are:
#                     intel, ifort, ifort11=intel11
#                     ifort12=intel12
#                     gnu, gfortran, gcc, gfortran44, gcc44=gnu44 for eve
#                     gnu, gfortran, gcc, gfortran45, gcc44=gnu45 for mcimac
#                     gfortran41, gcc41=gnu41
#         opti        -O, -O0, -O1, -O2, -O3, -O4, -O5, [anything else]
#         openmp      true, [anything else]
#
# DEPENDENCIES
#    This make file uses the following files:
#        Makefile2, makedeps.pl, make.inc.$(system).$(compiler) 
#
# RESTRICTIONS
#    Not all packages work with or are compiled for all compilers.
#    The script does checksome but not all of these dependencies.
#
# EXAMPLE
#    make release=debug compiler=intel11 imsl=imsl mkl=mkl95
#
# LITERATURE
#    The following links provide documentation:
#        GNU Make:       http://www.gnu.org/software/make/
#        INTEL Compiler: http://software.intel.com/en-us/articles/intel-parallel-studio-xe/
#        MKL:            http://software.intel.com/en-us/articles/intel-mkl/
#        IMSL:           http://www.roguewave.com/products/imsl-numerical-libraries.aspx
#        NETCDF:         http://www.unidata.ucar.edu/software/netcdf/
#        PROJ4:          http://trac.osgeo.org/proj/
#        LAPACK:         http://www.netlib.org/lapack/
#
# Written Matthias Cuntz & Juliane Mai, UFZ Leipzig, Germany, Aug. 2011 - matthias.cuntz@ufz.de

SHELL = /bin/bash

#
# --- SWITCHES -------------------------------------------------------
#

MAKEPATH := . # where are the make files (. is current directory, .. is parent directory)
#SRCPATH  := . # where are the source files; use test_??? to run a test directory
SRCPATH  := ./test_imsl_mkl
PROGPATH := . # where shall be the executable
#
PROGNAME := Prog # Name of executable
#
# check f77 files
ifeq (,$(wildcard $(SRCPATH)/*.f90) $(wildcard $(SRCPATH)/*.for) $(wildcard $(SRCPATH)/*.f))
        $(error Error: no fortran files in source path: $(SRCPATH))
endif
#
# Options
# Systems: eve, mcimac
system   := eve
# Releases: debug, release
release  := release
# Netcdf versions (Network Common Data Form): netcdf3, netcdf4
netcdf   :=
# Linking: static, shared, dynamic (last two are equal)
static   := shared
# Proj4 (Cartographic Projections Library): true, [anything else]
proj     :=
# IMSL (IMSL Numerical Libraries): vendor, imsl, [anything else]
imsl     := vendor
# MKL (Intel's Math Kernel Library): mkl, mkl95, [anything else]
mkl      := mkl
# LAPACK (Linear Algebra Pack): true, [anything else]
lapack   :=
# Compiler: intel11, intel12, gnu41, gnu44, gnu45, absoft
compiler := ifort
# Optimization: -O, -O0, -O1, -O2, -O3, -O4, -O5
opti     := -O3
# OpenMP parallelization: true, [anything else]
openmp   := 

#
# --- DEFAULTS ---------------------------------------------------
#

icompiler := $(compiler)
ifeq ($(system),eve)
    ifneq (,$(findstring $(compiler),intel ifort ifort11))
        icompiler := intel11
    endif
    ifeq ($(compiler),ifort12)
        icompiler := intel12
    endif
    ifneq (,$(findstring $(compiler),gnu gfortran gcc gfortran44 gcc44))
        icompiler := gnu44
    endif
    ifneq (,$(findstring $(compiler),gfortran41 gcc41))
        icompiler := gnu41
    endif
endif
ifeq ($(system),mcimac)
    ifneq (,$(findstring $(compiler),intel ifort ifort12))
        icompiler := intel12
    endif
    ifneq (,$(findstring $(compiler),gnu gfortran gcc gfortran45 gcc45))
        icompiler := gnu45
    endif
endif

#
# --- CHECKS ---------------------------------------------------
#

ifeq (,$(findstring $(system),eve mcimac))
    $(error Error: system '$(system)' not found; must be in 'eve mcimac')
endif

ifeq (,$(findstring $(release),debug release))
    $(error Error: release '$(release)' not found; must be in 'debug release')
endif

ifneq ($(netcdf),)
    ifeq (,$(findstring $(netcdf),netcdf3 netcdf4))
        $(error Error: netcdf '$(netcdf)' not found; must be in 'netcdf3 netcdf4')
    endif
endif

ifeq (,$(findstring $(static),static shared dynamic))
    $(error Error: static '$(static)' not found; must be in 'static shared dynamic')
endif

ifneq (,$(findstring $(imsl),vendor imsl))
    ifneq ($(icompiler),intel11)
        $(error Error: IMSL needs intel11.0.075, set 'compiler=intel11')
    endif
    ifeq ($(lapack),true)
        $(error Error: IMSL does not work with LAPACK. Use MKL instead of LAPACK. Set 'lapack=false mkl=mkl')
    endif
    ifeq ($(imsl),vendor)
        ifeq (,$(findstring $(mkl),mkl mkl95))
            $(error Error: IMSL vendor needs MKL, set 'mkl=mkl' or 'mkl=mkl95')
        endif
    endif
endif

ifeq (,$(findstring $(icompiler),intel11 intel12 gnu41 gnu44 gnu45 absoft))
    $(error Error: compiler '$(icompiler)' not found; must be in 'intel11 intel12 gnu41 gnu44 gnu45 absoft')
endif

ifeq ($(openmp),true)
    iopenmp := -openmp
else
    iopenmp :=
endif

#
# --- PATHS ------------------------------------------------
#

# Make absolute pathes
ifeq ($(findstring '//','/'$(PROGPATH)),)
    PROG := $(CURDIR)/$(strip $(PROGPATH))/$(strip $(PROGNAME))
else
    PROG := $(strip $(PROGPATH))/$(strip $(PROGNAME))
endif

ifeq ($(findstring '//','/'$(MAKEPATH)),)
    MAKEPROG     := $(CURDIR)/$(strip $(MAKEPATH))/Makefile2
    MAKEDEPSPROG := $(CURDIR)/$(strip $(MAKEPATH))/makedeps.pl
else
    MAKEPROG     := $(strip $(MAKEPATH))/Makefile2
    MAKEDEPSPROG := $(strip $(MAKEPATH))/makedeps.pl
endif
ifneq (exists, $(shell if [ -f $(MAKEPROG) ] ; then echo 'exists' ; fi))
    $(error Error: '$(MAKEPROG)' not found.)
endif
ifneq (exists, $(shell if [ -f $(MAKEDEPSPROG) ] ; then echo 'exists' ; fi))
    $(error Error: '$(MAKEDEPSPROG)' not found.)
endif

ifeq ($(findstring '//','/'$(SRCPATH)),)
    SOURCEPATH := $(CURDIR)/$(strip $(SRCPATH))
else
    SOURCEPATH := $(strip $(SRCPATH))
endif
ifneq (exists, $(shell if [ -d $(SOURCEPATH) ] ; then echo 'exists' ; fi))
    $(error Error: path '$(SOURCEPATH)' not found.)
endif

OBJPATH := $(SOURCEPATH)/.$(strip $(icompiler)).$(strip $(release))

#
# --- DEFAULTS ---------------------------------------------------
#

# These variables will be used to compile
FC       :=
FCFLAGS  :=
F90      :=
F90FLAGS :=
DEFINES  :=
INCLUDES :=
# and link, and therefore set below
LD       :=
LDFLAGS  :=
LIBS     :=

#
# --- COMPILER / MACHINE SPECIFIC --------------------------------
#
istatic := $(static)
ifeq ($(system),mcimac)
    istatic := dynamic
endif
ifeq ($(istatic),static)
    LIBS += -Bstatic -Wl,--start-group
else
    ifeq ($(system),mcimac)
        LIBS += -Wl,-dynamic
    else
        LIBS += -Bdynamic
    endif
endif
MAKEINC := make.inc.$(system).$(icompiler)
ifneq (exists, $(shell if [ -f $(MAKEINC) ] ; then echo 'exists' ; fi))
    $(error Error: '$(MAKEINC)' not found.)
endif
include $(MAKEINC)

# --- COMPILER ---------------------------------------------------
ifneq (,$(findstring $(icompiler),gnu41 gnu44 gnu45))
    ifneq (exists, $(shell if [ -d $(GFORTRANDIR) ] ; then echo 'exists' ; fi))
        $(error Error: '$(GFORTRANDIR)' not found.)
    endif
    GFORTRANLIB ?= $(GFORTRANDIR)/lib
    LIBS        += -L$(GFORTRANLIB) -lgfortran
    RPATH       += -Wl,-rpath,$(GFORTRANLIB)
endif

# --- OPENMP -----------------------------------------------------
ifeq ($(openmp),true)
    LDFLAGS  += $(iopenmp)
else
    ifneq (,$(findstring $(imsl),vendor imsl))
        LDFLAGS  += -openmp
    endif
endif

# --- IMSL ---------------------------------------------------
ifneq (,$(findstring $(imsl),vendor imsl))
    ifneq (exists, $(shell if [ -d $(IMSLDIR) ] ; then echo 'exists' ; fi))
        $(error Error: '$(IMSLDIR)' not found.)
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
        ifneq (exists, $(shell if [ -d $(MKL95DIR) ] ; then echo 'exists' ; fi))
            $(error Error: '$(MKL95DIR)' not found.)
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

    ifneq (exists, $(shell if [ -d $(MKLDIR) ] ; then echo 'exists' ; fi))
        $(error Error: '$(MKLDIR)' not found.)
    endif
    MKLINC ?= $(MKLDIR)/include
    MKLLIB ?= $(MKLDIR)/lib

    INCLUDES += -I$(MKLINC)
    DEFINES  += -DMKL

    LIBS += -L$(MKLLIB) -lmkl_intel_lp64 -lmkl_core #-lpthread
    ifneq (,$(findstring $(imsl),vendor imsl))
       LIBS += -lmkl_intel_thread #-lpthread
    else ifeq ($(openmp),true)
       LIBS += -lmkl_intel_thread #-lpthread
    else
       LIBS += -lmkl_sequential #-lpthread
    endif
    RPATH += -Wl,-rpath,$(MKLLIB)
endif

# --- NETCDF ---------------------------------------------------
ifneq (,$(findstring $(netcdf),netcdf3 netcdf4))
    ifneq (exists, $(shell if [ -d $(NCDIR) ] ; then echo 'exists' ; fi))
        $(error Error: '$(NCDIR)' not found.)
    endif
    NCINC ?= $(strip $(NCDIR))/include
    NCLIB ?= $(strip $(NCDIR))/lib

    INCLUDES += -I$(NCINC)
    DEFINES  += -DNETCDF

    LIBS     += -L$(NCLIB) -lnetcdf -lnetcdff
    RPATH    += -Wl,-rpath,$(NCLIB)

    # libraries for netcdf4, ignored for netcdf3
    ifeq ($(netcdf),netcdf4)
        LIBS  += -lz -L$(SZLIB) -lsz -L$(HDF5LIB) -lhdf5 -lhdf5_hl
        RPATH += -Wl,-rpath,$(SZLIB) -Wl,-rpath,$(HDF5LIB)
        ifneq ($(CURLLIB),)
            LIBS     += -L$(CURLLIB) -lcurl
            LIBS     += -Wl,-rpath,$(CURLLIB)
        endif
   endif
endif

# --- PROJ --------------------------------------------------
ifeq ($(proj),true)
    ifneq (exists, $(shell if [ -d $(PROJ4DIR) ] ; then echo 'exists' ; fi))
        $(error Error: '$(PROJ4DIR)' not found.)
    endif
    PROJ4LIB ?= $(PROJ4DIR)/lib
    LIBS     += -L$(PROJ4LIB) -lproj    
    RPATH    += -Wl,-rpath=$(PROJ4LIB)

    ifneq (exists, $(shell if [ -d $(FPROJDIR) ] ; then echo 'exists' ; fi))
        $(error Error: '$(FPROJDIR)' not found.)
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
    ifneq (,$(findstring $(system),mcimac))
        LIBS += -framework veclib
    else
        ifneq (exists, $(shell if [ -d $(LAPACKDIR) ] ; then echo 'exists' ; fi))
            $(error Error: '$(LAPACKDIR)' not found.)
        endif
        LAPACKLIB ?= $(LAPACKDIR)/lib
        LIBS      += -L$(LAPACKLIB) -lblas -llapack
        RPATH     += -Wl,-rpath,$(LAPACKLIB)
    endif
    DEFINES += -DLAPACK

    ifneq (,$(findstring $(system),eve))
        ifeq (,$(findstring $(icompiler),gnu41 gnu44 gnu45))
            ifneq (exists, $(shell if [ -d $(GFORTRANDIR) ] ; then echo 'exists' ; fi))
                $(error Error: '$(GFORTRANDIR)' not found.)
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

ifeq ($(istatic),static)
    LIBS += -Wl,--end-group
else
    ifneq ($(system),mcimac)
        LIBS += $(RPATH)
    endif
endif

LD := $(F90)

# ASRCS contain source dir informations
ASRCS     := $(wildcard $(SOURCEPATH)/*.f90)
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

FORASRCS  := $(wildcard $(SOURCEPATH)/*.for)
FORSRCS   := $(notdir $(FORASRCS))
FORAOBJS  := $(FORSRCS:.for=.o)
FOREXCL   :=
OFORAOBJS := $(filter-out $(FOREXCL), $(FORAOBJS))
FOROBJS   := $(addprefix $(OBJPATH)/, $(OFORAOBJS))

FASRCS    := $(wildcard $(SOURCEPATH)/*.f)
FSRCS     := $(notdir $(FASRCS))
FAOBJS    := $(FSRCS:.f=.o)
FEXCL     :=
OFAOBJS   := $(filter-out $(FEXCL), $(FAOBJS))
FOBJS     := $(addprefix $(OBJPATH)/, $(OFAOBJS))

export PROG
export OBJS 
export FOROBJS
export FOBJS
export LD
export LDFLAGS
export LIBS
export OBJPATH
export F90
export DEFINES
export INCLUDES
export F90FLAGS
export FC
export FCFLAGS
ifneq ($(ABSOFT),)
    export ABSOFT
endif

#
# --- TARGETS ---------------------------------------------------
#

# targets for executables
all: makedirs makedeps
	cd "$(SOURCEPATH)" ; $(MAKE) -f "$(MAKEPROG)"
        ifeq ($(system),mcimac)
            ifeq (${DYLD_LIBRARY_PATH},)
	        @echo
                ifeq ($(static),static)
	            @echo "WARNING: MAC OS X does only link dynamically and does not work with -rpath"
                else
	            @echo "WARNING: MAC OS X does not work with -rpath"
                endif
	        @echo "         Set DYLD_LIBRARY_PATH."
	        @echo
            endif
        endif

# helper targets
makedeps:
	rm -f "$(OBJPATH)"/make.deps
	rm -f tmp.gf3.*
	$(MAKEDEPSPROG) "$(OBJPATH)" "$(SOURCEPATH)"

makedirs:
	if [ ! -d "$(OBJPATH)" ] ; then mkdir "$(OBJPATH)" ; fi

clean:
	rm -f "$(OBJPATH)"/*.o "$(OBJPATH)"/*.mod "$(OBJPATH)"/make.deps "$(PROG)"
        ifeq ($(findstring test_netcdf_imsl_proj, $(SRCPATH)),test_netcdf_imsl_proj)
	    if [ -f ./test_netcdf_imsl_proj/test.nc ] ; then rm ./test_netcdf_imsl_proj/test.nc ; fi
        endif

cleanclean: clean
	rm -rf "$(SOURCEPATH)"/.*.r* "$(SOURCEPATH)"/.*.d* $(PROG).dSYM
