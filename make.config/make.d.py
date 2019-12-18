#!/usr/bin/env python
from __future__ import print_function
"""
usage: make.d.py [-h] [-f FortranFile] InputFile OutputPath FilesWithSourceFileList

Make dependency files for Fortran90 projects.

positional arguments:
  InputFile OutputPath FilesWithSourceFileList
                        Preprocessed input file, relative output directory
                        (script assumes compilation into
                        dirname(InputFile)/opath), file(s) with list(s) of all source files.

optional arguments:
  -h, --help            show this help message and exit
  -f FortranFile, --ffile FortranFile
                        Not preprocessed Fortran source filename. If missing
                        InputFile[:-4] is assumed.


History
-------
Written,  Matthias Cuntz, Mar 2016
Modified, Matthias Cuntz, Nov 2016 - read/write 'r'/'w' instead of 'rb'/'wb' for Python3
          Matthias Cuntz, Nov 2016 - read list of source file names from file instead of command line
          Matthias Cuntz, Dec 2019 - use codecs module to ignore non-ascii characters in input files
                                   - and allow UTF-8 path and file names
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
    Written,  Matthias Cuntz, Mar 2016
    Modified, Matthias Cuntz, Nov 2016 - write 'w' instead of 'wb' for Python3
              Matthias Cuntz, Dec 2019 - use codecs module to ignore non-ascii text in files
    """
    import os
    import re
    import codecs

    if not os.path.exists(os.path.dirname(modfile)): os.mkdir(os.path.dirname(modfile))
    of = codecs.open(modfile, 'w', encoding='utf-8')
    for ff in srcfiles:
        # Go through line by line, remove comments and strings because the latter can include ';'.
        # Then split at at ';', if given.
        # The stripped line should start with 'module ' and there should be nothing after the module name,
        # as for example in lines such as 'module procedure ...'
        olist = list()
        fi = codecs.open(ff, 'r', encoding='ascii', errors='ignore')
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
    Written,  Matthias Cuntz, Mar 2016
    Modified, Matthias Cuntz, Nov 2016 - read 'r' instead of 'rb' for Python3
    """
    import codecs

    odict = dict()
    of = codecs.open(modfile, 'r', encoding='utf-8')
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
    Written,  Matthias Cuntz, Mar 2016
    Modified, Matthias Cuntz, Nov 2016 - read 'r' instead of 'rb' for Python3
              Matthias Cuntz, Dec 2019 - use codecs module to ignore non-ascii text in files
    """
    import re
    import codecs

    # Go through line by line, remove comments and strings because the latter can include ';'.
    # Then split at at ';', if given.
    # The stripped line should start with 'use ' and after module name should only be ', only: ...'
    olist = list()
    of = codecs.open(ffile, 'r', encoding='ascii', errors='ignore')
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
    Written,  Matthias Cuntz, Mar 2016
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
def make_d(prefile, opath, srcfilelist, ffile=None):
    """
    Make dependency files for Fortran90 projects.


    Definition
    ----------
    def make_d(prefile, opath, srcfilelist, ffile=None):


    Input
    -----
    prefile       Preprocessed input file
    opath         Relative output directory
                  Script assumes compilation into dirname(InputFile)/opath
    srcfilelist   File(s) with list(s) of all source files


    Optional Input
    --------------
    ffile         Not-preprocessed Fortran file name
                  If not given prefile[:-4] will be assumed.


    Output
    ------
    Dictionary file of modules found in source files: dirname(FirstFortranFile)/opath/make.d.dict
    Dependency file dirname(FortranFile)/opath/basename(FortranFile).d


    History
    -------
    Written,  Matthias Cuntz, Mar 2016
    Modified, Matthias Cuntz, Nov 2016 - write 'w' instead of 'wb' for Python3
              Matthias Cuntz, Nov 2016 - read list of source file names from file instead of command line
              Matthias Cuntz, Dec 2019 - use codecs module to allow UTF-8 path and file names
    """
    import os
    import codecs

    # If Fortran file ffile not given, assume that preprocessed file is ffile.pre,
    # or any other three letter suffix.
    if ffile:
        forfile = ffile.decode('utf-8')
    else:
        forfile = prefile[:-4].decode('utf-8')

    # Get source file names from file list
    srcfiles = []
    for ff in srcfilelist:
        fs = codecs.open(ff,'r',encoding='utf-8')
        srcfiles.extend(fs.read().split('\n'))
        fs.close()
    srcfiles = [ ss for ss in srcfiles if ss.strip() != '' ]

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
    df = codecs.open(dfile, 'w', encoding='utf-8')
    print(dfile, ':', forfile, file=df)
    print(ofile, ':', dfile, end='', file=df)
    for im in imodfiles:
        print('', f2o(im,opath), end='', file=df)
    print('', file=df)
    df.close()


if __name__ == '__main__':

    import sys

    if sys.version.split()[0] < '2.7':
        import optparse # deprecated with Python rev 2.7

        ffile = None
        usage = "Make dependency files for Fortran90 projects.\nUsage: %prog [options] InputFile OutputPath FilesWithSourceFileList"
        parser = optparse.OptionParser(usage=usage)
        parser.add_option('-f', '--ffile', action='store',
                          default=ffile, dest='ffile', metavar='FortranFile',
                          help='Not preprocessed Fortran source filename. If missing InputFile[:-4] is assumed.')

        (options, args) = parser.parse_args()
        ffile = options.ffile
        allin = args
    else:
        import argparse

        ffile = None
        parser = argparse.ArgumentParser(formatter_class=argparse.RawDescriptionHelpFormatter,
                                         description='Make dependency files for Fortran90 projects.')
        parser.add_argument('-f', '--ffile', action='store',
                            default=ffile, dest='ffile', metavar='FortranFile',
                            help='Not preprocessed Fortran source filename. If missing InputFile[:-4] is assumed.')
        parser.add_argument('files', nargs='*', default=None, metavar='InputFile OutputPath FilesWithSourceFileList',
                           help='Preprocessed input file, relative output directory (script assumes compilation into dirname(InputFile)/opath), file(s) with list(s) of all source files.')

        args  = parser.parse_args()
        ffile = args.ffile
        allin = args.files

    if len(allin) < 3:
        print('Arguments: ', allin)
        raise IOError('Script needs: InputFile OutputPath FilesWithSourceFileList.')

    prefile  = allin[0]
    opath    = allin[1]
    srcfilelist = allin[2:]

    del parser, args

    make_d(prefile, opath, srcfilelist, ffile=ffile)
