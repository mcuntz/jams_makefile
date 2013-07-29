#!/bin/bash
set -e
#
# Produces makefile dependencies of Fortran files
#
# Copyright 2013 Matthias Cuntz - mc (at) macu.de
#
# License
# This file is part of the makefile library.
#
# The UFZ bash library is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# The UFZ bash library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.

# You should have received a copy of the GNU Lesser General Public License
# along with The UFZ bash library. If not, see <http://www.gnu.org/licenses/>.

set -e
prog=$0
pprog=$(basename ${prog})
dprog=$(dirname ${prog})
isdir=${PWD}
pid=$$

# Perform a cleanup if script is interupted
trap cleanup 1 2 3 6

# --------------------------------------------------------------------------------------------------
# functions
#
function usage () {
    printf "${pprog} [-h] FortranFile Source2ObjectPath AllSrcFiles\n\n"
    printf "Produces makefile dependency files with file ending .d of Fortran files.\n"
    printf "Looks for use statement in FortranFile and gets the files in AllSrcFiles that provides the modules.\n"
    printf "\n"
    printf "Input\n"
    printf "    FortranFile         Fortran file for which dependency file will be produced.\n"
    printf "    Source2ObjectPath   Script assumes that object path is $(dirname ${FortranFile})/${Source2ObjectPath}).\n"
    printf "    AllSrcFIles         All source file of project that will be scanned for dependencies.\n"
    printf "\n"
    printf "Options\n"
    printf "    -h          Prints this help screen.\n"
    printf "\n"
    printf "Examples\n"
    printf "    ${pprog} src/main.f90 .gnu.release src/*.f90\n"
}
#
# cleanup at end wnd when interupted
function cleanup ()
{
  \rm -f *.${pid}
}

# --------------------------------------------------------------------------------------------------
# Arguments
#
# Switches
while getopts "h" Option ; do
    case ${Option} in
	h) usage; exit;;
	*) printf "Error ${pprog}: unimplemented option.\n\n" 1>&2;  usage 1>&2; exit 1;;
    esac
done
shift $((${OPTIND} - 1))

# Check that enough arguments
if [ $# -lt 3 ] ; then
    printf "Error ${pprog}: not enough input arguments.\n\n" 1>&2
    usage 1>&2
    exit 1
fi

# infile and objectpath
thisfile=$1
src2obj=$2
shift 2
# all source files
srcfiles=$@

# --------------------------------------------------------------------------------------------------
# Dependencies
#
# Get all modules
for i in ${srcfiles} ; do
    ismod=$(echo "${i}:$(sed -e 's/\!.*//' -e '/^[Cc]/d' ${i} | tr [A-Z] [a-z] | tr -s ' ' | grep -E '^[[:blank:]]*module[[:blank:]]+' | sed -e 's/module //' | sed -e 's/ .*//')")
    if [[ "${ismod}" != "${i}:" ]] ; then echo ${ismod} >> dict.${pid} ; fi
done

# modules used in input file
molist=$(sed -e 's/\!.*//' -e '/^[Cc]/d' ${thisfile} | tr [A-Z] [a-z] | tr -s ' ' | grep -E '^[[:blank:]]*use[[:blank:]]+' | sed 's/,.*//' | sed 's/.*use //' | sort | uniq)
is=$(echo ${molist} | tr ' ' '|')

# correpondant files to used modules
if [[ "${is}" != "" ]] ; then
    olist=$(cut -f 1 -d ':' dict.${pid} | sed -n $(echo $(grep -nEw "${is}" dict.${pid} | cut -f 1 -d ':') | sed -e 's/\([0-9]*\)/-e \1p/g') | tr '\n' ' ')
fi

# Write output file
s2ofile="$(dirname ${thisfile})/${src2obj}/$(basename ${thisfile})"
tmpfile=${s2ofile}.${pid}
printf "${s2ofile/\.[fF]*/.o} ${s2ofile/\.[fF]*/.d} : ${thisfile}" > ${tmpfile}
for i in ${olist} ; do
    is2ofile="$(dirname ${i})/${src2obj}/$(basename ${i})"
    printf " ${is2ofile/\.[fF]*/.o}" >> ${tmpfile}
done
printf "\n" >> ${tmpfile}

# replace .d file
outfile=${s2ofile/\.[fF]*/.d}
mv ${tmpfile} ${outfile}

# replace .d file if changed
# outfile=${s2ofile/\.[fF]*/.d}
# if [[ -f ${outfile} ]] ; then
#     set +e
#     tt=$(sdiff -s ${tmpfile} ${outfile})
#     set -e
#     if [[ "${tt}" != "" ]] ; then
# 	mv ${tmpfile} ${outfile}
#     else
# 	rm ${tmpfile}
#     fi
# else
#     mv ${tmpfile} ${outfile}
# fi

# Perform cleanup, i.e. all temporary files *.${pid} are deleted
cleanup

exit 0
