#!/usr/bin/python3


import sys
import os



if __name__ == "__main__":
    curdir = os.path.split(os.path.abspath(sys.argv[0]))[0]
    sys.path.append(curdir)

    import copy_components
    project_dir = "."
    if len(sys.argv) > 1:
        projectdir = sys.argv[1]
    bootstrap_dir = os.path.split(curdir)[0]
    print(bootstrap_dir + " -> " + project_dir)
    copy_components.copy_components(project_dir, bootstrap_dir)

