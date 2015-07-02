#

"""
Process a project configuration file.
"""

import os
import types


def load_project(project_dir):
    return Project(os.path.split(project_dir)[1], project_dir, _load_project_config(project_dir))


class Project:
    def __init__(self, name, dirname, prj):
        self.__name = name
        self.__dirname = dirname
        self.__prj = prj
        if "bootstrap" not in prj:
            print("Using default 'bootstrap' directory")
            prj["bootstrap"] = "bootstrap"
        if "components" not in prj:
            prj["components"] = []
        if "dirmap" not in prj:
            prj["dirmap"] = {}
        if "symlinks" not in prj:
            prj["symlinks"] = True

    @property
    def name(self):
        return self.__name
    
    @property
    def basedir(self):
        return self.__dirname

    @property
    def use_symlinks(self):
        return self.__prj["symlinks"] == True
        
    @property
    def bootstrap_dir(self):
        return os.path.join(self.__dirname, self.__prj["bootstrap"])

    @property
    def component_names(self):
        return self.__prj["components"]
    
    def map_category_to_dir(self, category):
        if category in self.__prj["dirmap"]:
            return os.path.join(self.bootstrap_dir, self.__prj["dirmap"][category])
        return os.path.join(self.bootstrap_dir, category)



def _load_project_config(project_dir):
    project_file = os.path.join(project_dir, "bootstrap.config")
    with open(project_file, "r") as f:
        text = f.read() + "\n"
    prj = compile(text, project_file, "exec", dont_inherit=True)
    if "config" in prj.co_names:
        prj_module = types.ModuleType(os.path.basename(project_dir), os.path.basename(project_dir))
        exec(prj, prj_module.__dict__)
        if "config" in dir(prj_module) and type(prj_module.config) == dict:
            return prj_module.config
    raise Exception("bad project file " + project_file)
