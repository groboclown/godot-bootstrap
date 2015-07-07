
extends Panel

var _modules
var _order = []
var _selected_child = null
var _update_obj
var _update_func

func setup(modules, update_obj, update_func, order = null):
	_modules = modules
	_update_obj = update_obj
	_update_func = update_func
	if order != null:
		_order = order
	

func get_order():
	return _order

func _ready():
	_on_Refresh_pressed()


func show_modules():
	var md
	var named = {}
	for md in _modules.get_installed_modules():
		named[md.name] = md
	
	var cn = get_node("p/v/h/s/v")
	var kid
	for kid in cn.get_children():
		cn.remove_child(kid)
	var v
	for v in _order:
		if v[0] in named:
			#print("adding " + v[0])
			var kid = preload("module_def.xscn").instance()
			kid.setup(named[v[0]], self, true)
			cn.add_child(kid)
			named.erase(v[0])
	for v in named.keys():
		#print("adding " + v)
		var kid = preload("module_def.xscn").instance()
		kid.setup(named[v], self, false)
		cn.add_child(kid)



func _on_Refresh_pressed():
	# TODO make a background process
	var progress = get_node("p/o/h/RefreshProgress")
	progress.show()
	_modules.reload_modules(null, progress)
	
	show_modules()
	
	progress.hide()



func _on_up_pressed():
	if _selected_child != null:
		# should be able to use "move_child", but that doesn't seem to work.
		var p = _selected_child.get_parent()
		var kids = p.get_children()
		var k
		var index = 0
		var pos = -1
		for k in kids:
			if k == _selected_child:
				pos = index
			p.remove_child(k)
			index += 1
		
		kids.remove(pos)
		kids.insert(max(0, pos - 1), _selected_child)
		
		for k in kids:
			p.add_child(k)


func _on_down_pressed():
	if _selected_child != null:
		# should be able to use "move_child", but that doesn't seem to work.
		var p = _selected_child.get_parent()
		var kids = p.get_children()
		var k
		var index = 0
		var pos = -1
		for k in kids:
			if k == _selected_child:
				pos = index
			p.remove_child(k)
			index += 1
		
		kids.remove(pos)
		if pos >= kids.size():
			kids.append(_selected_child)
		else:
			kids.insert(pos + 1, _selected_child)
		
		for k in kids:
			p.add_child(k)


func set_selected_module_node(node):
	_selected_child = node
	var c
	for c in get_node("p/v/h/s/v").get_children():
		c.on_module_selected(node.module)


func set_module_active_state(md, active_state):
	pass




func _on_OK_pressed():
	# Save the order state to options
	_order = []
	var cn = get_node("p/v/h/s/v")
	var kid
	for kid in cn.get_children():
		if kid.has_method("is_active_module") && kid.is_active_module():
			var md = kid.module
			_order.append([ md.name, md.version ])
	
	_update_obj.call(_update_func, _order)
	
	# remove ourself
	get_parent().remove_child(self)


func _on_Cancel_pressed():
	# just remove ourself
	get_parent().remove_child(self)
