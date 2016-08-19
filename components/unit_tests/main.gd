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
				# print("TEST ADDED " + name)
				ret.append(name)
		file_name = dir.get_next()
	dir.list_dir_end()
	return ret


func run_tests(tests):
	var results = ResultCollector.new()
	for test in tests:
		var test_instance = create_test(test)
		if test_instance != null:
			run_test(test, test_instance, results)
	results._end()



func run_test(test_file, test_instance, results):
	# print("Running " + test_file)
	test_instance.filename = test_file.get_file()
	test_instance.filename = test_instance.filename.left(test_instance.filename.length() - 3)
	test_instance.run(results)


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


class ResultCollector:
	# This can be replaced or modified to allow for different kinds of output.
	# For example, a version could output the test results as a JSON object.

	# Results for all suites
	var suites = []

	# Current suite data
	var suite_name = null
	var test_stack = []
	var current_suite = null
	var current_test = null

	func start_suite(name):
		if suite_name != null:
			end_suite()
		suite_name = name

		# The start and end of the suite should be the suite-wide setup/teardown
		current_test = {
			"name": "<<class>>",
			"errors": []
		}
		test_stack = [ current_test ]
		current_suite = {
			"name": suite_name,
			"tests": [ current_test ],
			"error_count": 0
		}
		suites.append(current_suite)

	func end_suite():
		if suite_name == null:
			return
		if current_suite["error_count"] <= 0:
			print(suite_name + ": Success (" + str(current_suite["tests"].size()) + " tests)")
		else:
			print(suite_name + ": Failed (" + str(current_suite["error_count"]) + " errors, " + str(current_suite["tests"].size()) + " tests)")
		suite_name = null
		current_suite = null
		current_test = null

	func start_test(test_name):
		current_test = { "name": test_name, "errors": [] }
		test_stack.append(current_test)
		current_suite["tests"].append(current_test)

	func end_test():
		if test_stack.size() > 0:
			current_test = test_stack[test_stack.size() - 1]
			test_stack.pop_back()
		else:
			current_test = null

	func add_error(text):
		if current_suite == null || current_test == null:
			# We're outside the context of a suite or test.  Shouldn't happen.
			printerr("<<unknown test>> Failed: " + text)
		else:
			current_test["errors"].append(text)
			current_suite["error_count"] += 1
			printerr(suite_name + "::" + current_test["name"] + ": " + text)

		# It would be nice if we could capture the stack, so that the errors
		# could be assembled in a better form.  But, currently, Godot does not
		# support this.
		print_stack()

	func has_error():
		if current_test == null:
			return false
		return current_test["errors"].size() > 0


	func _end():
		# All test results are displayed during execution.
		# But we'll post a final summary
		var test_count = 0
		var error_count = 0
		var result
		for result in suites:
			test_count += result["tests"].size()
			error_count += result["error_count"]
		print("==============================")
		if error_count > 0:
			printerr("**** Test Failures ****")
		else:
			printerr("**** Success ****")
		printerr("Total Tests Ran: " + str(test_count))
		printerr("Total Errors: " + str(error_count))
