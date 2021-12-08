#!/usr/bin/env python
from __future__ import print_function
"""


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
    * numpydoc and flake8, Dec 2021, Matthias Cuntz
    * Added make_one_d, Dec 2021, Matthias Cuntz
    * prefile optional; treat all files in srcfilelist in not given,
      Dec 2021, Matthias Cuntz
    * Need to put .f90-file as dependency of .o files now that the .d
      files are not updated every time, Dec 2021, Matthias Cuntz

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


def make_one_d(prefile, ffile, opath, moddict):
    """
    Make dependency files for Fortran90 projects

    Parameters
    ----------
    prefile : str
        (Pre-processed) Fortran input file.
    ffile : str
        Original Fortran file name.
    opath : str
        Relative output directory.
        Script assumes compilation into dirname(ffile)/opath
    moddict : dict
        Dictionary keys are module names, values are module filenames

    Returns
    -------
    dependency file written dirname(ffile)/opath/basename(ffile).d

    """
    import codecs

    # List of modules used in input file
    imods = used_mods(prefile)

    # Query dictionary for filenames of modules used in fortran file.
    # Remove own file name for circular dependencies if more than one
    # module in fortran file.
    if imods:
        imodfiles = list()
        for d in imods:
            if d in moddict:  # otherwise external module such as netcdf
                if moddict[d] != ffile:
                    imodfiles.append(moddict[d])
    else:
        imodfiles = []

    # Write output .d file
    dfile = f2d(ffile, opath)
    ofile = f2o(ffile, opath)
    df = codecs.open(dfile, 'w', encoding='utf-8')
    print(dfile, ':', ffile, file=df)
    print(ofile, ':', ffile + ' ' + dfile, end='', file=df)
    for im in imodfiles:
        print('', f2o(im, opath), end='', file=df)
    print('', file=df)
    df.close()

    return


# main
def make_d(opath, srcfilelist, prefile=None, ffile=None):
    """
    Make dependency files for Fortran90 projects

    Parameters
    ----------
    opath : str
        Relative output directory.
        Script assumes compilation into dirname(ffile)/opath
    srcfilelist : list of str
        File(s) with list(s) of all source files
    prefile : str, optional
        (Pre-processed) Fortran input file.
        If missing, all files in `srcfilelist` will be treated.
    ffile : str, optional
        Not-pre-processed Fortran file name.
        If not given, prefile will be used.
        Ignored if prefile is not given.

    Returns
    -------
    modules file, dependency file
        file with list of modules used in source files
        dirname(srcfilelist[0])/opath/make.d.dict,
        dependency file dirname(ffile)/opath/basename(ffile).d

    """
    import os
    import codecs

    # File names of source files from file list(s)
    srcfiles = []
    for ff in srcfilelist:
        fs = codecs.open(ff, 'r', encoding='utf-8')
        srcfiles.extend(fs.read().split('\n'))
        fs.close()
    srcfiles = [ ss for ss in srcfiles if ss.strip() != '' ]

    # Only one file with list of files and their modules provided
    # put into first object directory
    firstdir = os.path.dirname(srcfiles[0])
    modfile  = firstdir + '/' + opath + '/' + 'make.d.dict'
    if not os.path.exists(modfile):
        make_dict(modfile, srcfiles)

    # Dictionary keys are module names, values are module filenames.
    moddict = get_dict(modfile)

    if prefile is not None:
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

        make_one_d(prefile, forfile, opath, moddict)
    else:
        for dd in srcfiles:
            make_one_d(dd, dd, opath, moddict)

    return


if __name__ == '__main__':

    import sys

    if sys.version.split()[0] < '2.7':
        import optparse  # deprecated with Python rev 2.7

        prefile = None
        ffile   = None
        usage  = ('Make dependency files for Fortran90 projects.\n'
                  'Usage: %prog [options] InputFile OutputPath'
                  ' FilesWithSourceFileList')
        parser = optparse.OptionParser(usage=usage)
        hstr = ('(pre-processed) Fortran source filename;'
                ' if missing, all files in FilesWithSourceFileList'
                '  will be treated.')
        parser.add_option(
            '-i', '--inputfile', action='store', default=prefile,
            dest='prefile', metavar='InputFile', help=hstr)
        hstr = ('Original, not pre-processed Fortran source filename;'
                ' if missing, InputFile is used;'
                ' ignored if InputFile is not given.')
        parser.add_option('-f', '--ffile', action='store', default=ffile,
                          dest='ffile', metavar='FortranFile', help=hstr)

        (options, args) = parser.parse_args()
        prefile = options.prefile
        ffile   = options.ffile
        allin   = args
    else:
        import argparse

        prefile = None
        ffile   = None
        parser  = argparse.ArgumentParser(
            formatter_class=argparse.RawDescriptionHelpFormatter,
            description='Make dependency files for Fortran90 projects.')
        hstr = ('(pre-processed) Fortran source filename;'
                ' if missing, all files in FilesWithSourceFileList'
                '  will be treated.')
        parser.add_argument(
            '-i', '--inputfile', action='store', default=prefile,
            dest='prefile', metavar='InputFile', help=hstr)
        hstr = ('original, not pre-processed Fortran source filename;'
                ' if missing, InputFile is used;'
                ' ignored if no InputFile given.')
        parser.add_argument(
            '-f', '--ffile', action='store', default=ffile, dest='ffile',
            metavar='OriginalFortranFile', help=hstr)
        hstr = ('relative output directory (script assumes compilation into'
                ' dirname(OriginalFortranFile)/OutputPath),'
                ' file(s) with list(s) of all source files.')
        parser.add_argument(
            'files', nargs='*', default=None,
            metavar='OutputPath FilesWithSourceFileList', help=hstr)

        args    = parser.parse_args()
        prefile = args.prefile
        ffile   = args.ffile
        allin   = args.files

    if len(allin) < 2:
        print('Arguments: ', allin)
        estr = 'Script needs: OutputPath FilesWithSourceFileList.'
        raise IOError(estr)

    opath    = allin[0]
    srcfilelist = allin[1:]

    del parser, args

    make_d(opath, srcfilelist, prefile=prefile, ffile=ffile)
