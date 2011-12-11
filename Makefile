#
# Makefile for CHS projects on eve.ufz.de
#
# Usage
#    make [option=option] [all] [clean] [clean]
# Options can be set as command line input or in the --- SWITCHES --- section below
#
# Targets: all, clean, cleanclean
# 
# Options: see individual options in switch section below
#          options can be empty (same as any garbage value)
#          e.g. do not use IMSL:  imsl=  or  imsl=no
#
# Links providing documentation:
#    GNU Make:       http://www.gnu.org/software/make/
#    NETCDF:         http://www.unidata.ucar.edu/software/netcdf/
#    PROJ4:          http://trac.osgeo.org/proj/
#    IMSL:           http://www.roguewave.com/products/imsl-numerical-libraries.aspx
#    MKL:            http://software.intel.com/en-us/articles/intel-mkl/
#    LAPACK:         http://www.netlib.org/lapack/
#    INTEL Compiler: http://software.intel.com/en-us/articles/intel-parallel-studio-xe/
#    CDI:            https://code.zmaw.de/projects/cdi/
#
# Written Matthias Cuntz & Juliane Mai, UFZ Leipzig, Germany, Aug. 2011 - matthias.cuntz@ufz.de

export
SHELL = /bin/bash

# --- SWITCHES -------------------------------------------------------
MAKEPATH = . # where are the make files (. is current directory, .. is parent directory)
#SRCPATH  = . # where are the source files; use test_??? to run a test directory
SRCPATH  = ./test_mkl
PROGPATH = . # where shall be the executable
#
PROGNAME = Prog # Name of executable
#
# check for files
ifeq (,$(wildcard $(strip $(SRCPATH))/*.f90 ) $(wildcard $(strip $(SRCPATH))/*.for ))
        $(error Error: no fortran files in source path: $(SRCPATH))
endif
#
# Options
# Releases: debug, release
release  = release
# Netcdf versions (Network Common Data Form): netcdf3, netcdf4
netcdf   =
# Linking: static, shared, dynamic (last two are equal)
static   = static
# Proj4 (Cartographic Projections Library): true, [anything else]
proj     = 
# IMSL (IMSL Numerical Libraries): vendor, imsl, [anything else]
imsl     = vendor
# MKL (Intel's Math Kernel Library): true, [anything else]
mkl      =
# LAPACK (Linear Algebra Pack): true, [anything else]
lapack   = true
# Compiler: intel11
compiler = intel11
# Optimization: -O0, -O1, -O2, -O3, -O4, -O5
opti     = -O3
# Parallelization: -openmp, [anything else]
parallel = 
# CDI (Interface to Climate & NWP model Data): true, [anything else]
cdi      =

# --- CHECKS ---------------------------------------------------
# check input
#
ifeq (,$(findstring $(release),debug release))
    $(error Error: release '$(release)' not found; must be in 'debug release')
endif
#
ifneq ($(netcdf),)
    ifeq (,$(findstring $(netcdf),netcdf3 netcdf4))
        $(error Error: netcdf '$(netcdf)' not found; must be in 'netcdf3 netcdf4')
    endif
endif
#
ifeq (,$(findstring $(static),static shared dynamic))
    $(error Error: static '$(static)' not found; must be in 'static shared dynamic')
endif
#
ifneq (,$(findstring $(imsl),vendor imsl))
    ifneq ($(compiler),intel11)
        $(error Error: IMSL needs intel11.0.075, set 'compiler=intel11')
    endif
    ifeq ($(lapack),true)
        $(error Error: IMSL does not work with LAPACK. Use MKL instead of LAPACK. Set 'lapack=false mkl=true')
    endif
    ifeq ($(imsl),vendor)
        ifneq ($(mkl),true)
            $(error Error: IMSL vendor needs MKL, set 'mkl=true')
        endif
    endif
endif
#
ifeq (,$(findstring $(compiler),intel11))
    $(error Error: compiler '$(compiler)' not found; must be in 'intel11')
endif
#
ifeq (,$(findstring $(opti),-O0 -O1 -O2 -O3 -O4 -O5))
    $(error Error: opti '$(opti)' not found; must be in '-O0 -O1 -O2 -O3 -O4 -O5')
endif
#
ifeq ($(parallel),$(findstring $(parallel),-openmp))
    parallelit = $(parallel)
else
    parallelit =
endif
#
ifeq ($(cdi),true)
    ifeq (,$(findstring $(netcdf),netcdf4))
        $(error Error: CDI needs netcdf4. Set 'netcdf=netcdf4')
    endif
    ifeq (,$(findstring mo_cdi.f90,$(wildcard $(strip $(SRCPATH))/*.f90)))
         $(error Error: The file mo_cdi.f90 must be in source path: $(SRCPATH))
    endif
endif
#
# --- PATHS ------------------------------------------------

# Progs include absolute paths
ifeq ($(findstring '//','/'$(PROGPATH)),)
    PROG = $(CURDIR)/$(strip $(PROGPATH))/$(strip $(PROGNAME))
else
    PROG = $(strip $(PROGPATH))/$(strip $(PROGNAME))
endif
ifeq ($(findstring '//','/'$(MAKEPATH)),)
    MAKEPROG     = $(CURDIR)/$(strip $(MAKEPATH))/Makefile2
    MAKEDEPSPROG = $(CURDIR)/$(strip $(MAKEPATH))/makedeps.pl
else
    MAKEPROG     = $(strip $(MAKEPATH))/Makefile2
    MAKEDEPSPROG = $(strip $(MAKEPATH))/makedeps.pl
endif
# Make source path absolute
ifeq ($(findstring '//','/'$(SRCPATH)),)
    SOURCEPATH = $(CURDIR)/$(strip $(SRCPATH))
else
    SOURCEPATH = $(strip $(SRCPATH))
endif

OBJPATH = $(SOURCEPATH)/.$(strip $(release))

# --- DEFAULTS ---------------------------------------------------
# These variables will be used to compile
FC       =
FCFLAGS  =
F90      =
F90FLAGS =
DEFINES  =
INCLUDES =
# and link, and therefore set below
LD       =
LDFLAGS  =
LIBS     =

# --- COMPILER ---------------------------------------------------
ifeq (intel11,$(compiler))
    # v12
    # INTEL = /usr/local/intel/composerxe-2011.4.191
    # INTELLIB = $(INTEL)/compiler/lib/intel64
    # v11
    INTEL    = /opt/intel/Compiler/11.1/075
    INTELBIN = $(INTEL)/bin/intel64
    INTELLIB = /usr/local/intel/11.1.075
    #
    F90 = $(INTELBIN)/ifort
    FC  = $(F90)
    ifeq ($(release),debug)
        F90FLAGS = -check all -warn all -g -debug -traceback -fp-stack-check -O0 -debug
        FCFLAGS  = -g -debug -traceback -fp-stack-check -O0 -debug
    else
        # -vec-report1 to see vectorized loops; -vec-report2 to see also non-vectorized loops
        F90FLAGS  = $(opti) -vec-report0 -override-limits
        FCFLAGS   = $(opti) -vec-report0 -override-limits
    endif
    F90FLAGS += -assume byterecl -cpp -fp-model precise $(parallelit) -m64 -module "$(OBJPATH)"
    FCFLAGS  += -assume byterecl -cpp -fp-model precise $(parallelit) -m64 -module "$(OBJPATH)" -fixed
    ifeq ($(parallelit),-openmp)
        LDFLAGS  += -openmp
    else
        ifneq (,$(findstring $(imsl),vendor imsl))
            LDFLAGS  += -openmp
        endif
    endif
    DEFINES  += -DINTEL
    #
    ifeq ($(static),static)
        LIBS += -static-intel -Bstatic -Wl,--start-group
    else
        LIBS += -Bdynamic
    endif
    #
    LIBS += -L$(INTELLIB) -limf -lm -lsvml
    #
    ifneq ($(static),static)
         LIBS += -lintlc
    endif
    RPATH += -Wl,-rpath,$(INTELLIB)
endif
#
# additional compilers to be included here, BE AWARE OF DEPENDENCIES!!!
#
# --- IMSL ---------------------------------------------------
#ifeq ($(imsl),$(findstring $(imsl),vendor imsl))
ifneq (,$(findstring $(imsl),vendor imsl))
     IMSLDIR = /usr/local/imsl/imsl/fnl700/rdhin111e64
     IMSLINC = $(IMSLDIR)/include
     IMSLLIB = $(IMSLDIR)/lib
     #
     INCLUDES += -I$(IMSLINC)
     LIBS     += -z muldefs
     #
     ifneq ($(static),static)
        LIBS += -i_dynamic
     endif
     #
     ifeq ($(imsl),imsl)
         LIBS += -L$(IMSLLIB) -limsl -limslscalar -limsllapack_imsl -limslblas_imsl -limsls_err -limslmpistub -limslsuperlu
     else
         LIBS  += -L$(IMSLLIB) -limsl -limslscalar -limsllapack_vendor -limslblas_vendor -limsls_err -limslmpistub -limslsuperlu -limslhpc_l
     endif
     #
     RPATH += -Wl,-rpath,$(IMSLLIB)
endif

# --- MKL ---------------------------------------------------
ifeq ($(mkl),true)
    MKLDIR    = /usr/local/intel/composerxe-2011.4.191/mkl
    MKLINC    = $(MKLDIR)/include/intel64/lp64
    MKLLIB    = $(MKLDIR)/lib/intel64
    #
    INCLUDES += -I$(MKLINC)
    #
    # according to MKL Link-Line Advisor: http://software.intel.com/en-us/articles/intel-mkl-link-line-advisor/
    #
    LIBS += -L$(MKLLIB) -lmkl_blas95_lp64 -lmkl_lapack95_lp64 -lmkl_intel_lp64 -lmkl_core #-lpthread
    ifneq (,$(findstring $(imsl),vendor imsl))
       # imsl needs threading
       LIBS += -lmkl_intel_thread #-lpthread
    else
       ifneq (,$(findstring $(parallel),-openmp))
           # -openmp needs threading
           LIBS += -lmkl_intel_thread #-lpthread
       else
           # all others use sequential version of MKL
           LIBS += -lmkl_sequential #-lpthread
       endif
    endif
    
    RPATH    += -Wl,-rpath,$(MKLLIB)
endif

# --- NETCDF ---------------------------------------------------
ifneq ($(netcdf),)
    ifneq (,$(findstring $(netcdf),netcdf3 netcdf4))
        NCDIR =
        ifeq ($(netcdf),netcdf3)
            #NCDIR = /usr/local/netcdf/3.6.3_intel_12.0.4
            NCDIR = /usr/local/netcdf/3.6.3_intel11.1.075
        else
            #NCDIR = /usr/local/netcdf/4.1.1_intel_12.0.4
            NCDIR = /usr/local/netcdf/4.1.1_intel11.1.075
        endif
        NCINC = $(strip $(NCDIR))/include
        NCLIB = $(strip $(NCDIR))/lib

        INCLUDES += -I$(NCINC)
        LIBS     += -L$(NCLIB) -lnetcdf -lnetcdff
        RPATH    += -Wl,-rpath,$(NCLIB)

        # libraries for netcdf4, ignored for netcdf3
        ifeq ($(netcdf),netcdf4)
            SZLIB     = /usr/local/szip/2.1/lib
            HDF5LIB   = /usr/local/hdf5/1.8.6/lib
            LIBS     += -lz -L$(SZLIB) -lsz -L$(HDF5LIB) -lhdf5 -lhdf5_hl
            RPATH    += -Wl,-rpath,$(SZLIB) -Wl,-rpath,$(HDF5LIB)
        endif
    endif
endif

# --- PROJ --------------------------------------------------
ifeq ($(proj),true)
    PROJ4    = /usr/local/proj/4.7.0/lib
    LIBS     += -L$(PROJ4) -lproj    
    RPATH    += -Wl,-rpath=$(PROJ4)
    #
    FPROJDIR = /usr/local/fproj/4.7.0_intel11.1.075
    FPROJINC = $(FPROJDIR)/include
    FPROJLIB = $(FPROJDIR)/lib
    #
    INCLUDES += -I$(FPROJINC)
    LIBS     += -L$(FPROJLIB) -lfproj4 $(FPROJLIB)/proj4.o
    RPATH    += -Wl,-rpath,$(FPROJLIB)
endif

# --- CDI ----------------------------------------------------
ifeq ($(cdi),true)
    CDIDIR   = /usr/local/src/sci-libs/cdo-1.4.7/libcdi/src/.libs
    LIBS  += -L$(CDIDIR) -lcdi
endif

# --- LAPACK ---------------------------------------------------
ifeq ($(lapack),true)
    LAPACK    = /usr
    LAPACKLIB = $(LAPACK)/lib64
    LIBS     += -L$(LAPACKLIB) -lblas -llapack
    RPATH    += -Wl,-rpath,$(LAPACKLIB)
    GFORTRAN    = /usr
    GFORTRANLIB = $(GFORTRAN)/lib64
    LIBS       += -L$(GFORTRANLIB) -lgfortran
    RPATH    += -Wl,-rpath,$(GFORTRANLIB)
endif

# --- FINISH SETUP ---------------------------------------------------
ifeq ($(release),debug)
    DEFINES += -DDEBUG
endif

ifeq ($(static),static)
    LIBS += -Wl,--end-group
else
    LIBS += $(RPATH)
endif

# --- TARGETS ---------------------------------------------------
LD       := $(F90)
# A vars contain source dir informations
ASRCS := $(wildcard $(SOURCEPATH)/*.f90)
SRCS  := $(notdir $(ASRCS))
AOBJS := $(SRCS:.f90=.o)
FORASRCS := $(wildcard $(SOURCEPATH)/*.for)
FORSRCS  := $(notdir $(FORASRCS))
FORAOBJS := $(FORSRCS:.for=.o)
# 
# main driver routines can be excluded and added at targets in $(MAKEPROG)
EXCL     := 
#
FAOBJS   := $(filter-out $(EXCL), $(AOBJS))
OBJS     := $(addprefix $(OBJPATH)/, $(FAOBJS))
#
FFORAOBJS := $(filter-out $(EXCL), $(FORAOBJS))
FOROBJS   := $(addprefix $(OBJPATH)/, $(FFORAOBJS))

.SUFFIXES: .f90 .for .o

# targets for executables
all: makedirs makedeps
	cd "$(SOURCEPATH)" ; $(MAKE) -f "$(MAKEPROG)"

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
	rm -rf "$(SOURCEPATH)"/.release "$(SOURCEPATH)"/.debug "$(PROG)".dSYM
