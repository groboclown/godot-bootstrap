#

"""
Copy components into the project directory.
"""


import os
import shutil
import process_project
import process_component


def copy_components(project_dir, bootstrap_dir):
    """
    Copies the components from the bootstrap directory
    into the project directory.  Returns a list of all the files
    that were installed.
    """
    project = process_project.load_project(project_dir)
    components = process_component.load_components(os.path.join(bootstrap_dir, "components"), project.component_names)

    # Copy all the components returned, not just the requested ones.
    to_copy = {}
    for component in components:
        for cat in component.provides_categories:
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
                copied.update(_copy_struct(src, dest, project.use_symlinks))
    return list(copied.keys())


def _copy_struct(src, dest, use_symlinks):
    print(src + " -> " + dest)
    ret = {}

    # Ensure the parent destination path exists
    parent = os.path.split(dest)[0]
    if not os.path.isdir(parent):
        os.makedirs(parent)
        ret[parent] = True

    # Recursive copy using symlinks if possible
    if os.path.isdir(src):
        if os.path.islink(dest):
            os.remove(dest)
        success = False
        if use_symlinks:
            try:
                os.symlink(src, dest, target_is_directory=True)
                ret[dest] = True
                success = True
                print("  --- symlink dir")
            except (NotImplementedError, OSError):
                success = False
        if not success:
            # symlinks not supported
            # Custom recursive copy.
            for name in os.listdir(src):
                srcname = os.path.join(src, name)
                destname = os.path.join(dest, name)
                ret.update(_copy_struct(srcname, destname, use_symlinks))
    else:
        if os.path.islink(dest):
            os.unlink(dest)
        elif os.path.isdir(dest):
            shutil.rmtree(dest)
        elif os.path.exists(dest):
            os.unlink(dest)

        success = False
        if use_symlinks:
            try:
                os.symlink(src, dest, target_is_directory=False)
                ret[dest] = True
                success = True
                print("  --- symlink file")
            except (NotImplementedError, OSError):
                # Could not make symlink
                success = False
        if not success:
            shutil.copy(src, dest, follow_symlinks = True)
            ret[dest] = True
    return ret
