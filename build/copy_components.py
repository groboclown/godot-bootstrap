#

"""
Copy components into the project directory.
"""


import os
import shutil
import process_project
import process_component
from categories import CATEGORIES


def copy_components(project_dir, bootstrap_dir):
    """
    Copies the components from the bootstrap directory
    into the project directory.  Returns a list of all the files
    that were installed.
    """
    project = process_project.load_project(project_dir, bootstrap_dir)
    components = process_component.load_components(os.path.join(bootstrap_dir, "components"), project.component_names)

    # Copy all the components returned, not just the requested ones.
    to_copy = {}
    for component in components:
        for cat in component.provides_categories:
            if cat not in CATEGORIES:
                print("*** Found un-registered category " + cat)
                CATEGORIES.append(cat)
            if cat not in to_copy:
                to_copy[cat] = []
            to_copy[cat].append(component.provides(cat, components))

    generated = {}
    copied = {}
    for (cat, name_paths) in to_copy.items():
        outdir = project.map_category_to_dir(cat)
        for name_path_map in name_paths:
            for (outname, src) in name_path_map.items():
                dest = os.path.join(outdir, outname)
                if dest in generated:
                    raise Exception("two or more components write to the same place (" + dest + ")")
                generated[dest] = True
                copied.update(_copy_struct(src, dest, project))
    return list(copied.keys())


def _copy_struct(src, dest, project):
    #print(src + " -> " + dest)
    ret = {}

    # Ensure the parent destination path exists
    # Note that this may miss some directories that
    # should be put into the returned list.
    parent = os.path.split(dest)[0]
    if not os.path.isdir(parent):
        os.makedirs(parent)
        ret[parent] = True

    if os.path.isdir(src):
        # We can't use symlinks, because we may need custom copy for
        # resource files.  We'll need a custom recursive copy.
        for name in os.listdir(src):
            srcname = os.path.join(src, name)
            destname = os.path.join(dest, name)
            ret.update(_copy_struct(srcname, destname, project))
    else:
        if os.path.isdir(dest):
            shutil.rmtree(dest)
        elif os.path.exists(dest):
            os.unlink(dest)

        ext = os.path.splitext(dest)[1]
        if ext.startswith(".x") or ext == ".gd":
            # XML formatted resource and GDScript files
            _remap_res(src, dest, project)
        else:
            shutil.copy(src, dest, follow_symlinks = True)
        ret[dest] = True
    return ret


def _remap_res(src, dest, project):
    with open(src, "r") as inp:
        with open(dest, "w") as out:
            for line in inp.readlines():
                for cat in CATEGORIES:
                    in_res = '"res://bootstrap/' + cat + '/'
                    out_res = '"' + project.map_category_to_res(cat)
                    line = line.replace(in_res, out_res)
                out.write(line)
    
