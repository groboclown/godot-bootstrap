# Run as "godot -s main.gd"

extends SceneTree

const TEST_SOURCES = "res://tests/"
var BASE_TEST_CLASS = load(TEST_SOURCES + "base.gd")

func _init():
	var tests = find_tests_from_dir(TEST_SOURCES)
	run_tests(tests)
	quit()


func find_tests_from_dir(path):
	#print("Finding in " + path)
	var ret = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		var name = path + file_name
		if dir.current_is_dir():
			#print("Checking dir " + file_name + " [" +  file_name.right(file_name.length() - 6)+ "]")
			if file_name.right(file_name.length() - 6) == "_tests":
				for f in find_tests_from_dir(name + "/"):
					ret.append(f)
		else:
			var f = File.new()
			#print("Checking file " + name)
			if name.right(name.length() - 3) == ".gd" && f.file_exists(name):
				#print("added " + name)
				ret.append(name)
		file_name = dir.get_next()
	dir.list_dir_end()
	return ret


func run_tests(tests):
	for test in tests:
		var test_instance = create_test(test)
		if test_instance != null:
			run_test(test, test_instance)



func run_test(test_file, test_instance):
	print("Running " + test_file)
	test_instance.filename = test_file.get_file()
	test_instance.filename = test_instance.filename.left(test_instance.filename.length() - 3)
	test_instance.run()


func create_test(test_file):
	if test_file.to_lower().find("/test_") < 0:
		# don't even report it.
		#print("ignoring " + test_file)
		return null
	var test_class = load(test_file)
	if test_class != null:
		var test_instance = test_class.new()
		if test_instance != null && test_instance extends BASE_TEST_CLASS:
			return test_instance
		print("*** SETUP ERROR: Not a valid test instance: " + test_file)
	else:
		print("*** SETUP ERROR: Could not load file " + test_file)
	return null
