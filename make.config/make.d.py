#!/usr/bin/env python
from __future__ import print_function
"""
usage: make.d.py [-h] [-f FortranFile] InputFile OutputPath SourceFiles

Make dependency files for Fortran90 projects.

positional arguments:
  InputFile OutputPath SourceFiles
                        Preprocessed input file, relative output directory
                        (script assumes compilation into
                        dirname(InputFile)/opath), all source files.

optional arguments:
  -h, --help            show this help message and exit
  -f FortranFile, --ffile FortranFile
                        Not preprocessed Fortran source filename. If missing
                        prefile[:-4] is assumed.


History
-------
Written,  MC, Mar 2016
"""

__all__ = ['make_d']

def make_dict(modfile, srcfiles):
    """
    Makes module dictionary file from Fortran90 source files with entries such as
    FortranFile: mo_mod1 mo_mod2


    Definition
    ----------
    def make_dict(modfile, srcfiles):


    Input
    -----
    modfile   dictionary filename
    srcfiles  list with Fortran90 files


    Output
    ------
    dictionary file with entries such as
    FortranFile: mo_mod1 mo_mod2


    Restrictions
    ------------
    Script assumes that the keyword 'module' and the module name are on the same line.
    That means it does not allow to start a Fortran90 module like this:
        module &
            mo_name ! this is weird coding style


    History
    -------
    Written,  MC, Mar 2016
    """
    import os
    import re
    
    if not os.path.exists(os.path.dirname(modfile)): os.mkdir(os.path.dirname(modfile))
    of = open(modfile, 'wb')
    for ff in srcfiles:
        # Go through line by line, remove comments and strings because the latter can include ';'.
        # Then split at at ';', if given.
        # The stripped line should start with 'module ' and there should be nothing after the module name,
        # as for example in lines such as 'module procedure ...'
        olist = list()
        fi = open(ff, 'rb')
        for line in fi:
            ll = line.rstrip().lower()   # everything lower case
            ll = re.sub('!.*$', '', ll)  # remove F90 comment
            ll = re.sub('^c.*$', '', ll) # remove F77 comments
            ll = re.sub('".*?"', '', ll) # remove "string"
            ll = re.sub("'.*?'", '', ll) # remove 'string'
            # check if several commands are on one line
            if ';' in ll:
                lll = ll.split(';')
            else:
                lll = [ll]
                for il in lll:
                    iil = il.strip()
                    # Line should start with 'module ' and there should be nothing after the module name
                    if iil.startswith('module '):
                        imod = iil[7:].strip()     # remove 'module '
                        if len(imod.split()) == 1: # not 'module procedure'
                            olist.append(imod)
        fi.close()
        # Line into dictionary file
        if olist:
            print(ff, ':', end='', sep='', file=of)
            for ll in olist:
                print('', ll, end='', file=of)
            print('', file=of)
    of.close()
    
    return


def get_dict(modfile):
    """
    Return dictionary from dictionary file produced by make_dict
    with module names as keys and filenames as values.


    Definition
    ----------
    def get_dict(modfile):


    Input
    -----
    modfile   dictionary input file with entries such as
              FortranFile: mo_mod1 mo_mod2


    Output
    ------
    Dictionary with module names as keys and filenames as values,
    e.g. dict['mo_kind'] = '/path/mo_kind.f90'


    History
    -------
    Written,  MC, Mar 2016
    """
    odict = dict()
    of = open(modfile, 'rb')
    for line in of:
        # Dictionary lines should be like: /path/filename.suffix: mo_mod1 mo_mod2
        ll = line.rstrip().split(':')
        fname = ll[0]
        mods = ll[1].strip().split(' ')
        for m in mods:
            odict[m] = fname
    of.close()
    
    return odict


def used_mods(ffile):
    """
    Get list of modules used in one Fortran90 file.


    Definition
    ----------
    def used_mods(ffile):


    Input
    -----
    ffile   Fortran90 file name


    Output
    ------
    List of modules used


    History
    -------
    Written,  MC, Mar 2016
    """
    import re

    # Go through line by line, remove comments and strings because the latter can include ';'.
    # Then split at at ';', if given.
    # The stripped line should start with 'use ' and after module name should only be ', only: ...'
    olist = list()
    of = open(ffile, 'rb')
    for line in of:
        ll = line.rstrip().lower()   # everything lower case
        ll = re.sub('!.*$', '', ll)  # remove F90 comment
        ll = re.sub('^c.*$', '', ll) # remove F77 comments
        ll = re.sub('".*?"', '', ll) # remove "string"
        ll = re.sub("'.*?'", '', ll) # remove 'string'
        # check if several commands are on one line
        if ';' in ll:
            lll = ll.split(';')
        else:
            lll = [ll]
        for il in lll:
            iil = il.strip()
            # Line should start with 'use ' and after module name should only be ', only: ...'
            if iil.startswith('use '):
                imod = iil[4:]                  # remove 'use '
                imod = re.sub(',.*$', '', imod) # remove after , if: use mod, only: func
                olist.append(imod.strip())
    of.close()
    
    return olist


def f2suff(forfile, opath, suff):
    """
    Construct outputfile in opath with new suffix.


    Definition
    ----------
    def f2suff(forfile, opath, suff):


    Input
    -----
    forfile   Fortran90 file name
    opath     relative output path
              Script assumes output path: dirname(forfile)/opath
    suff      Input file sufix will be replaced by suff


    Output
    ------
    Name of output file in opath and new suffix


    History
    -------
    Written,  MC, Mar 2016
    """
    import os
    
    idir  = os.path.dirname(forfile)
    ifile = os.path.basename(forfile)
    odir  = idir +'/' + opath
    ofile = ifile[0:ifile.rfind('.')] + '.' + suff
    
    return odir + '/' + ofile


def f2d(forfile, opath):
    """
    Shortcut for f2suff(forfile, opath, 'd')
    """
    return f2suff(forfile, opath, 'd')


def f2o(forfile, opath):
    """
    Shortcut for f2suff(forfile, opath, 'o')
    """
    return f2suff(forfile, opath, 'o')


# main
def make_d(prefile, opath, srcfiles, ffile=None):
    """
    Make dependency files for Fortran90 projects.


    Definition
    ----------
    def make_d(prefile, opath, srcfiles, ffile=None):


    Input
    -----
    prefile     Preprocessed input file
    opath       Relative output directory
                Script assumes compilation into dirname(InputFile)/opath
    srcfiles    All source files


    Optional Input
    --------------
    ffile       Not-preprocessed Fortran file name
                If not given prefile[:-4] will be assumed.


    Output
    ------
    Dictionary file of modules found in source files: dirname(FirstFortranFile)/opath/make.d.dict
    Dependency file dirname(FortranFile)/opath/basename(FortranFile).d

    
    History
    -------
    Written,  MC, Mar 2016
    """
    import os
    
    # If Fortran file ffile not given, assume that preprocessed file is ffile.pre,
    # or any other three letter suffix.
    if ffile:
        forfile = ffile
    else:
        forfile = prefile[:-4]

    # Only one dictionary file for all files in first object directory
    firstdir = os.path.dirname(srcfiles[0])
    modfile  = firstdir + '/' + opath + '/' + 'make.d.dict'
    if not os.path.exists(modfile): make_dict(modfile, srcfiles)

    # Dictionary keys are module names, value is module filename.
    moddict = get_dict(modfile)

    # List of modules used in input file
    imods = used_mods(prefile)
    
    # Query dictionary for filenames of modules used in fortran file.
    # Remove own file name for circular dependencies if more than one module in fortran file.
    if imods:
        imodfiles = list()
        for d in imods:
            if d in moddict: # otherwise external module such as netcdf
                if moddict[d] != forfile: imodfiles.append(moddict[d])
    else:
        imodfiles = []

    # Write output .d file
    dfile = f2d(forfile,opath)
    ofile = f2o(forfile,opath)
    df = open(dfile, 'wb')
    print(dfile, ':', forfile, file=df)
    print(ofile, ':', dfile, end='', file=df)
    for im in imodfiles:
        print('', f2o(im,opath), end='', file=df)
    print('', file=df)
    df.close()


if __name__ == '__main__':

    import argparse

    ffile = None
    parser = argparse.ArgumentParser(formatter_class=argparse.RawDescriptionHelpFormatter,
                                     description='Make dependency files for Fortran90 projects.')
    parser.add_argument('-f', '--ffile', action='store',
                        default=ffile, dest='ffile', metavar='FortranFile',
                        help='Not preprocessed Fortran source filename. If missing prefile[:-4] is assumed.')
    parser.add_argument('files', nargs='*', default=None, metavar='InputFile OutputPath SourceFiles',
                       help='Preprocessed input file, relative output directory (script assumes compilation into dirname(InputFile)/opath), all source files.')

    args  = parser.parse_args()
    ffile = args.ffile
    allin = args.files

    del parser, args

    if len(allin) < 3:
        print('Arguments: ', allin)
        raise IOError('Script needs: InputFile OutputPath SourceFiles.')

    prefile  = allin[0]
    opath    = allin[1]
    srcfiles = allin[2:]

    make_d(prefile, opath, srcfiles, ffile=ffile)
