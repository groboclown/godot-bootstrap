#!/usr/bin/python3


import sys
import os



if __name__ == "__main__":
    curdir = os.path.split(os.path.abspath(sys.argv[0]))[0]
    sys.path.append(curdir)

    project_dir = "."
    if len(sys.argv) > 1:
        projectdir = sys.argv[1]
    
    import installed_files
    copied = installed_files.read_installed_files_file(project_dir)
    installed_files.delete_installed_files(project_dir, copied)
