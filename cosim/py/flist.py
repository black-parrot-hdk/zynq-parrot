
import os

def vincludes_from_flist(filename):
    incdirs = ""
    with open(filename, 'r') as f:
        for l in f.readlines():
            if '#' in l:
                continue
            elif '+incdir+' in l:
                incdirs += os.path.expandvars(l.replace('+incdir+',' '))
                
    return incdirs

def vsources_from_flist(filename):
    files = ""
    with open(filename, 'r') as f:
        for l in f.readlines():
            if '#' in l:
                continue
            elif '+incdir+' in l:
                continue
            else:
                files += os.path.expandvars(l)
                
    return files

def to_flist(filename, files="", includes=""):
    with open(filename, 'w') as fp:
        for i in files.split():
            fp.write('+incdir+'+i+'\n')
        for f in files.split():
            fp.write(f+'\n')

