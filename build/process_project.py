#

"""
Process a project configuration file.
"""

import os
import types
from categories import CATEGORIES

TOP_KEYWORDS = [
    "bootstrap",
    "components",
    "dirmap"
]

def load_project(project_dir, bootstrap_dir):
    components = find_component_names(bootstrap_dir)
    return Project(os.path.split(project_dir)[1], project_dir, _load_project_config(project_dir, components))
    

def find_component_names(bootstrap_dir):
    ret = []
    for name in os.listdir(os.path.join(bootstrap_dir, "components")):
        fname = os.path.join(bootstrap_dir, "components", name, "component.config")
        if os.path.exists(fname):
            ret.append(name)
    return ret


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
        
        # Sets the bootstrap path as a "res://" directory.  It will include
        # a trailing "/" character.
        bdir = os.path.abspath(self.bootstrap_dir)
        path = []
        while True:
            # Find the engine.cfg up the directory path
            fname = os.path.join(bdir, "engine.cfg")
            if os.path.isfile(fname):
                # found engine directory
                ret = "res://"
                path.reverse()
                for p in path:
                    ret += p + "/"
                self.__bootstrap_res = ret
                break
            parts = os.path.split(bdir)
            newdir = parts[0]
            if newdir == bdir or newdir == "" or newdir is None:
                # root
                raise Exception("Could not find engine directory under bootstrap directory " + self.bootstrap_dir)
            bdir = newdir
            path.append(parts[1])
        

    @property
    def name(self):
        return self.__name
    
    @property
    def basedir(self):
        return self.__dirname
        
    @property
    def bootstrap_dir(self):
        return os.path.join(self.__dirname, self.__prj["bootstrap"])

    @property
    def component_names(self):
        return self.__prj["components"]
    
    def map_category_to_res(self, category):
        base = self.__bootstrap_res
        if category in self.__prj["dirmap"]:
            return base + self.__prj["dirmap"][category] + "/"
        return base + category + "/"
        
    
    def map_category_to_dir(self, category):
        if category in self.__prj["dirmap"]:
            return os.path.join(self.bootstrap_dir, self.__prj["dirmap"][category])
        return os.path.join(self.bootstrap_dir, category)



def _load_project_config(project_dir, component_names):
    project_file = os.path.join(project_dir, "bootstrap.config")
    with open(project_file, "r") as f:
        text = f.read() + "\n"
    prj = compile(text, project_file, "exec", dont_inherit=True)
    if "config" in prj.co_names:
        prj_module = types.ModuleType(os.path.basename(project_dir), os.path.basename(project_dir))
        for name in component_names:
            setattr(prj_module, name, name)
        for cat in CATEGORIES:
            setattr(prj_module, cat, cat)
        for key in TOP_KEYWORDS:
            setattr(prj_module, key, key)
        exec(prj, prj_module.__dict__)
        if "config" in dir(prj_module) and type(prj_module.config) == dict:
            return prj_module.config
    raise Exception("bad project file " + project_file)
