#


"""
Processes a component directory.
"""

import os
import types

def load_components(component_dir, component_names):
    """Return a list of Component objects that fulfil the component
    names and their dependent components."""
    configs = {}
    _load_components(component_dir, configs, component_names)
    return configs.values()


class Component:
    def __init__(self, name, basedir, config):
        self.__name = name
        self.__config = config
        self.__basedir = basedir
        self.__depends = []
        self.__init = False
        assert basedir is not None

    @property
    def name(self):
        return self.__name

    @property
    def basedir(self):
        return self.__basedir

    @property
    def required_component_names(self):
        if "requires" in self.__config:
            ret = {}
            for v in self.__config["requires"]:
                if type(v) == str:
                    ret[v] = True
            return tuple(ret.keys())
        return tuple()

    @property
    def required_components(self):
        if not __init:
            raise Exception("not initialized")
        return tuple(self.__depends)

    @property
    def provides_categories(self):
        if "provides" in self.__config:
            return tuple(self.__config["provides"].keys())
        return tuple()


    def provides(self, category, project_components):
        filenames = []
        if "provides" in self.__config and category in self.__config["provides"]:
            names = self.__config["provides"][category]
            if type(names) == str:
                names = [ names ]
            filenames.extend(names)
        
        if "optional" in self.__config:
            for cat in project_components:
                if cat.name in self.__config["optional"] and category in self.__config["optional"][cat.name]:
                    names = self.__config["optional"][cat.name][category]
                if type(names) == str:
                    names = [ names ]
                filenames.extend(names)
        files = {}
        for name in filenames:
            d = os.path.join(self.basedir, name)
            if name[-1] == "*":
                for kid in os.listdir(d):
                    files[name + "/" + kid] = os.path.join(d, kid)
            else:
                files[name] = d

        return files


    def _initialize(self, component_dir, component_map):
        if self.__init:
            return
        self.__init = True
        unspecified = self.required_component_names
        while len(unspecified) > 0:
            names = unspecified
            unspecified = []
            for name in names:
                if name in component_map:
                    self.__depends.append(component_map[name])
                else:
                    unspecified.append(name)
            _load_components(component_dir, component_map, unspecified)



def _load_components(component_base_dir, config_map, component_names):
    loaded = []
    for name in component_names:
        if name in config_map:
            continue
        basedir = os.path.join(component_base_dir, name)
        config = _load_component_config(basedir)
        config_map[name] = Component(name, basedir, config)
        loaded.append(config_map[name])
    for component in loaded:
        component._initialize(component_base_dir, config_map)




def _load_component_config(component_dir):
    component_file = os.path.join(component_dir, "component.py")
    with open(component_file, "r") as f:
        text = f.read() + "\n"
    component = compile(text, component_file, "exec", dont_inherit=True)
    if "config" in component.co_names:
        component_module = types.ModuleType(os.path.basename(component_dir), os.path.basename(component_dir))
        exec(component, component_module.__dict__)
        if "config" in dir(component_module) and type(component_module.config) == dict:
            return component_module.config
    raise Exception("bad component file " + component_file)

