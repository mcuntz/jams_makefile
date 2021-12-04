#!/usr/bin/env python
from __future__ import print_function
"""
usage: make.d.py [-h] [-f OriginalFortranFile] InputFile OutputPath FilesWithSourceFileList

Make dependency files for Fortran90 projects.

positional arguments:
  InputFile OutputPath FilesWithSourceFileList
      Preprocessed input file, relative output directory
      (script assumes compilation into dirname(InputFile)/OutputPath),
      file(s) with list(s) of all source files.

optional arguments:
  -h, --help            show this help message and exit
  -f OriginalFortranFile, --ffile OriginalFortranFile
      Not preprocessed Fortran source filename. If missing
      InputFile is used.


History
-------
    * Written Mar 2016,Matthias Cuntz
    * Use read/write 'r'/'w' instead of 'rb'/'wb' for Python3,
      Nov 2016, Matthias Cuntz
    * Read list of source file names from file instead of command line,
      Nov 2016, Matthias Cuntz
    * Use codecs module to ignore non-ascii characters in input files,
      Dec 2019, Matthias Cuntz
    * Allow UTF-8 in path and file names, Dec 2019, Matthias Cuntz
    * Rectified that UTF-8 path and file names worked only for Python2
      Mar 2020, Matthias Cuntz
    * numpydoc and flake8, Dec 2021
    * numpydoc and flake8, Dec 2021

"""


__all__ = ['make_d']


def make_dict(modfile, srcfiles):
    """
    List of files and the modules they provide

    Makes a file that lists all Fortran90 source files and the modules they
    provide in the form
    .. code-block::

       FortranFile: mo_mod1 mo_mod2

    Parameters
    ----------
    modfile : str
        Output filename with list entries
    srcfiles : list of str
        List with Fortran90 files

    Returns
    -------
    modfile with entries such as
    .. code-block::

       FortranFile: mo_mod1 mo_mod2


    Notes
    -----
    Script assumes that the keyword 'module' and the module name are on the
    same line in the Fortran files. That means it does not allow to start a
    Fortran90 module like this:
    .. code-block:: f90

        module &
            mo_name ! this is a weird coding style

    """
    import os
    import re
    import codecs

    if not os.path.exists(os.path.dirname(modfile)):
        os.mkdir(os.path.dirname(modfile))
    of = codecs.open(modfile, 'w', encoding='utf-8')
    for ff in srcfiles:
        # Go through line by line,
        # remove comments and strings because the latter can include ';'.
        # Then split at at ';', if given.
        # The stripped line should start with 'module ' and there should
        # be nothing after the module name,
        # as for example in lines such as 'module procedure ...'
        olist = list()
        fi = codecs.open(ff, 'r', encoding='ascii', errors='ignore')
        for line in fi:
            ll = line.rstrip().lower()    # everything lower case
            ll = re.sub('!.*$', '', ll)   # remove F90 comment
            ll = re.sub('^c.*$', '', ll)  # remove F77 comments
            ll = re.sub('".*?"', '', ll)  # remove "string"
            ll = re.sub("'.*?'", '', ll)  # remove 'string'
            # check if several commands are on one line
            if ';' in ll:
                lll = ll.split(';')
            else:
                lll = [ll]
                for il in lll:
                    iil = il.strip()
                    # Line should start with 'module ' and there should be
                    # nothing after the module name
                    if iil.startswith('module '):
                        imod = iil[7:].strip()      # remove 'module '
                        if len(imod.split()) == 1:  # not 'module procedure'
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
    Return dictionary from file produced by make_dict

    It return dictionary with module names as keys and filenames as values.

    Parameters
    ----------
    modfile : str
        File with entries such as
        .. code-block::

           FortranFile: mo_mod1 mo_mod2

    Returns
    -------
    dict
        Dictionary with module names as keys and filenames as values,
        e.g. dict['mo_kind'] = '/path/mo_kind.f90'

    """
    import codecs

    odict = dict()
    of = codecs.open(modfile, 'r', encoding='utf-8')
    for line in of:
        # Dictionary lines should be like:
        # /path/filename.suffix: mo_mod1 mo_mod2
        ll = line.rstrip().split(':')
        fname = ll[0]
        mods = ll[1].strip().split(' ')
        for m in mods:
            odict[m] = fname
    of.close()

    return odict


def used_mods(ffile):
    """
    List of modules used in one Fortran90 file

    Parameters
    ----------
    ffile : str
        Fortran90 file name

    Returns
    -------
    List of modules used in `ffile`

    """
    import re
    import codecs

    # Go through line by line,
    # remove comments and strings because the latter can include ';'.
    # Then split at at ';', if given.
    # The stripped line should start with 'use '
    # and after module name should only be ', only: ...'
    olist = list()
    of = codecs.open(ffile, 'r', encoding='ascii', errors='ignore')
    for line in of:
        ll = line.rstrip().lower()    # everything lower case
        ll = re.sub('!.*$', '', ll)   # remove F90 comment
        ll = re.sub('^c.*$', '', ll)  # remove F77 comments
        ll = re.sub('".*?"', '', ll)  # remove "string"
        ll = re.sub("'.*?'", '', ll)  # remove 'string'
        # check if several commands are on one line
        if ';' in ll:
            lll = ll.split(';')
        else:
            lll = [ll]
        for il in lll:
            iil = il.strip()
            # Line should start with 'use '
            # and after module name should only be ', only: ...'
            if iil.startswith('use '):
                imod = iil[4:]                   # remove 'use '
                # remove after ',' if: use mod, only: func
                imod = re.sub(',.*$', '', imod)
                olist.append(imod.strip())
    of.close()

    return olist


def f2suff(forfile, opath, suff):
    """
    Construct output filename in opath with new suffix

    Parameters
    ----------
    forfile : str
        Fortran90 file name
    opath : str
        Relative output path.
        Script assumes output path: dirname(forfile)/opath
    suff : str
        Suffix of input file will be replaced by suff

    Returns
    -------
    Name of output file in opath having new suffix

    """
    import os

    idir  = os.path.dirname(forfile)
    ifile = os.path.basename(forfile)
    odir  = idir + '/' + opath
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
    Make dependency files for Fortran90 projects

    Parameters
    ----------
    prefile : str
        Preprocessed Fortran input file
    opath : str
        Relative output directory.
        Script assumes compilation into dirname(prefile)/opath
    srcfilelist : list of str
        File(s) with list(s) of all source files
    ffile : str, optional
        Not-preprocessed Fortran file name.
        If not given prefile will be used.

    Returns
    -------
    modules file, dependency file
        file with list of modules used in source files
        dirname(srcfilelist[0])/opath/make.d.dict,
        dependency file dirname(ffile)/opath/basename(ffile).d

    """
    import os
    import codecs

    # If original Fortran source file ffile not given, use prefile.
    try:
        if ffile:
            forfile = ffile.decode('utf-8')
        else:
            forfile = prefile.decode('utf-8')
    except AttributeError:
        if ffile:
            forfile = ffile
        else:
            forfile = prefile

    # Get source file names from file list
    srcfiles = []
    for ff in srcfilelist:
        fs = codecs.open(ff, 'r', encoding='utf-8')
        srcfiles.extend(fs.read().split('\n'))
        fs.close()
    srcfiles = [ ss for ss in srcfiles if ss.strip() != '' ]

    # Only one dictionary file for all files in first object directory
    firstdir = os.path.dirname(srcfiles[0])
    modfile  = firstdir + '/' + opath + '/' + 'make.d.dict'
    if not os.path.exists(modfile):
        make_dict(modfile, srcfiles)

    # Dictionary keys are module names, value is module filename.
    moddict = get_dict(modfile)

    # List of modules used in input file
    imods = used_mods(prefile)

    # Query dictionary for filenames of modules used in fortran file.
    # Remove own file name for circular dependencies if more than one
    # module in fortran file.
    if imods:
        imodfiles = list()
        for d in imods:
            if d in moddict:  # otherwise external module such as netcdf
                if moddict[d] != forfile:
                    imodfiles.append(moddict[d])
    else:
        imodfiles = []

    # Write output .d file
    dfile = f2d(forfile, opath)
    ofile = f2o(forfile, opath)
    df = codecs.open(dfile, 'w', encoding='utf-8')
    print(dfile, ':', forfile, file=df)
    print(ofile, ':', dfile, end='', file=df)
    for im in imodfiles:
        print('', f2o(im, opath), end='', file=df)
    print('', file=df)
    df.close()


if __name__ == '__main__':

    import sys

    if sys.version.split()[0] < '2.7':
        import optparse  # deprecated with Python rev 2.7

        ffile = None
        usage = ('Make dependency files for Fortran90 projects.\n'
                 'Usage: %prog [options] InputFile OutputPath'
                 ' FilesWithSourceFileList')
        parser = optparse.OptionParser(usage=usage)
        hstr = ('Original, not preprocessed Fortran source filename;'
                ' if missing, InputFile is used.')
        parser.add_option('-f', '--ffile', action='store', default=ffile,
                          dest='ffile', metavar='FortranFile', help=hstr)

        (options, args) = parser.parse_args()
        ffile = options.ffile
        allin = args
    else:
        import argparse

        ffile = None
        parser = argparse.ArgumentParser(
            formatter_class=argparse.RawDescriptionHelpFormatter,
            description='Make dependency files for Fortran90 projects.')
        hstr = ('original, not preprocessed Fortran source filename;'
                ' if missing, InputFile is used.')
        parser.add_argument(
            '-f', '--ffile', action='store', default=ffile, dest='ffile',
            metavar='FortranFile', help=hstr)
        hstr = ('preprocessed input file, relative output directory'
                ' (script assumes compilation into'
                ' dirname(FortranFile)/OutputPath),'
                ' file(s) with list(s) of all source files.')
        parser.add_argument(
            'files', nargs='*', default=None,
            metavar='InputFile OutputPath FilesWithSourceFileList',
            help=hstr)

        args  = parser.parse_args()
        ffile = args.ffile
        allin = args.files

    if len(allin) < 3:
        print('Arguments: ', allin)
        estr = 'Script needs: InputFile OutputPath FilesWithSourceFileList.'
        raise IOError(estr)

    prefile  = allin[0]
    opath    = allin[1]
    srcfilelist = allin[2:]

    del parser, args

    make_d(prefile, opath, srcfilelist, ffile=ffile)
