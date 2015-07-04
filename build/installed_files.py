#

"""
Create a file that stores all the files installed by this process, and also
reads that file.
"""


import os


def create_installed_files_file(project_dir, copied_files):
    copied_files.sort()
    copied_files.reverse()
    with open(os.path.join(project_dir, ".bootstrap.installed-files"), "w") as f:
        for cf in copied_files:
            if cf.startswith(project_dir):
                cf = cf[len(project_dir):]
            while len(cf) > 0 and (cf.startswith("/") or cf.startswith(os.sep)):
                cf = cf[1:]
            if len(cf) > 0:
                f.write(cf + "\n")


def read_installed_files_file(project_dir):
    fname = os.path.join(project_dir, ".bootstrap.installed-files")
    if not os.path.exists(fname):
        return []
    ret = {}
    with open(fname, "r") as f:
        for line in f.readlines():
            ret[line.strip()] = True
    ret = list(ret.keys())
    ret.sort()
    ret.reverse()
    return ret


def delete_installed_files(project_dir, files, fail_on_error = False):
    dirs = []
    for cf in files:
        while len(cf) > 0 and (cf.startswith("/") or cf.startswith(os.sep)):
            cf = cf[1:]
        if len(cf) > 0:
            fname = os.path.join(project_dir, cf)
            if os.path.isdir(fname):
                dirs.append(fname)
            elif os.path.exists(fname):
                try:
                    os.unlink(fname)
                except:
                    if fail_on_error:
                        raise
                    else:
                        print("Problem removing " + fname)
    
    dirs.sort()
    dirs.reverse()
    for d in dirs:
        try:
            os.rmdir(d)
        except:
            # Always ignore directory removal failures
            pass

    fname = os.path.join(project_dir, ".bootstrap.installed-files")
    if os.path.exists(fname):
        try:
            os.unlink(fname)
        except:
            # Don't error out if we can't remove it
            pass
