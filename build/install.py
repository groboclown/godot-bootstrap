#!/usr/bin/python3


import sys
import os



if __name__ == "__main__":
    curdir = os.path.split(os.path.abspath(sys.argv[0]))[0]
    sys.path.append(curdir)

    import copy_components
    import installed_files
    project_dir = "."
    if len(sys.argv) > 1:
        projectdir = sys.argv[1]
    copied = installed_files.read_installed_files_file(project_dir)
    installed_files.delete_installed_files(project_dir, copied)
    
    bootstrap_dir = os.path.split(curdir)[0]
    print("Installing from " + bootstrap_dir + " into " + project_dir)
    copied = copy_components.copy_components(project_dir, bootstrap_dir)

    installed_files.create_installed_files_file(project_dir, copied)
