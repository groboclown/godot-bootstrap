
# Error code extensions and translations
# Error code names are from:
#	https://github.com/okamstudio/godot/blob/master/core/error_list.h

const ERR__CUSTOM_START = 10000


static func to_string(err):
	# The primary errors are extracted from
	# https://github.com/okamstudio/godot/blob/master/core/error_list.h
	# This just returns the string name of the Error enum (int) value.
	# This allows the translation file to convert these messages into something
	# a human can read.
	
	if err == null:
		return "null"
	
	var codes = _get_codes()
	
	if err in codes:
		return codes[err]
	
	return "ERR_UKNOWN"


static func add_code(value, text):
	_get_codes()[value] = text


# Codes are stored in the global variable space, but not stored in the
# engine config file.
static func _get_codes():
	if Globals.has("__error_codes__"):
		return Globals.get("__error_codes__")
	else:
		# Note that some of these are not added to the Godot script name space,
		# so we add their actual numerical value instead.
		var ret = {
			OK: "OK",
			
			# ///< Generic fail error
			FAILED: "FAILED",
			
			# ///< What is requested is unsupported/unavailable
			ERR_UNAVAILABLE: "ERR_UNAVAILABLE",
			
			# ///< The object being used hasnt been properly set up yet
			ERR_UNCONFIGURED: "ERR_UNCONFIGURED",
			
			# ///< Missing credentials for requested resource
			ERR_UNAUTHORIZED: "ERR_UNAUTHORIZED",
			
			# ///< Parameter given out of range (5)
			ERR_PARAMETER_RANGE_ERROR: "ERR_PARAMETER_RANGE_ERROR",
			
			# ///< Out of memory
			ERR_OUT_OF_MEMORY: "ERR_OUT_OF_MEMORY",
			
			ERR_FILE_NOT_FOUND: "ERR_FILE_NOT_FOUND",
			ERR_FILE_BAD_DRIVE: "ERR_FILE_BAD_DRIVE",
			ERR_FILE_BAD_PATH: "ERR_FILE_BAD_PATH",
			
			# // (10)
			ERR_FILE_NO_PERMISSION: "ERR_FILE_NO_PERMISSION",
			ERR_FILE_ALREADY_IN_USE: "ERR_FILE_ALREADY_IN_USE",
			ERR_FILE_CANT_OPEN: "ERR_FILE_CANT_OPEN",
			ERR_FILE_CANT_WRITE: "ERR_FILE_CANT_WRITE",
			ERR_FILE_CANT_READ: "ERR_FILE_CANT_READ",
			
			# // (15)
			ERR_FILE_UNRECOGNIZED: "ERR_FILE_UNRECOGNIZED",
			ERR_FILE_CORRUPT: "ERR_FILE_CORRUPT",
			ERR_FILE_EOF: "ERR_FILE_EOF",
			
			# ///< Can't open a resource/socket/file
			ERR_CANT_OPEN: "ERR_CANT_OPEN",
			ERR_CANT_CREATE: "ERR_CANT_CREATE",
			
			# // (20)
			ERROR_QUERY_FAILED: "ERROR_QUERY_FAILED",
			ERR_ALREADY_IN_USE: "ERR_ALREADY_IN_USE",
			
			# ///< resource is locked
			ERR_LOCKED: "ERR_LOCKED",
			ERR_TIMEOUT: "ERR_TIMEOUT",
			
			#ERR_CANT_CONNECT: "ERR_CANT_CONNECT",
			24: "ERR_CANT_CONNECT",
			
			# // (25)
			#ERR_CANT_RESOLVE: "ERR_CANT_RESOLVE",
			25: "ERR_CANT_RESOLVE",
			
			#ERR_CONNECTION_ERROR: "ERR_CONNECTION_ERROR",
			26: "ERR_CONNECTION_ERROR",
			
			ERR_CANT_AQUIRE_RESOURCE: "ERR_CANT_AQUIRE_RESOURCE",
			
			#ERR_CANT_FORK: "ERR_CANT_FORK",
			28: "ERR_CANT_FORK",
			
			# ///< Data passed is invalid
			ERR_INVALID_DATA: "ERR_INVALID_DATA",
			
			# ///< Parameter passed is invalid  (30)
			ERR_INVALID_PARAMETER: "ERR_INVALID_PARAMETER",
			
			# ///< When adding, item already exists
			ERR_ALREADY_EXISTS: "ERR_ALREADY_EXISTS",
			
			# ///< When retrieving/erasing, it item does not exist
			ERR_DOES_NOT_EXIST: "ERR_DOES_NOT_EXIST",
			
			# ///< database is full
			ERR_DATABASE_CANT_READ: "ERR_DATABASE_CANT_READ",
			
			# ///< database is full
			ERR_DATABASE_CANT_WRITE: "ERR_DATABASE_CANT_WRITE",
			
			# // (35)
			ERR_COMPILATION_FAILED: "ERR_COMPILATION_FAILED",
			ERR_METHOD_NOT_FOUND: "ERR_METHOD_NOT_FOUND",
			ERR_LINK_FAILED: "ERR_LINK_FAILED",
			ERR_SCRIPT_FAILED: "ERR_SCRIPT_FAILED",
			ERR_CYCLIC_LINK: "ERR_CYCLIC_LINK",
			
			# // (40)
			#ERR_INVALID_DECLARATION: "ERR_INVALID_DECLARATION",
			40: "ERR_INVALID_DECLARATION",
			
			#ERR_DUPLICATE_SYMBOL: "ERR_DUPLICATE_SYMBOL",
			41: "ERR_DUPLICATE_SYMBOL",
			
			#ERR_PARSE_ERROR: "ERR_PARSE_ERROR",
			42: "ERR_PARSE_ERROR",
			
			ERR_BUSY: "ERR_BUSY",
			
			#ERR_SKIP: "ERR_SKIP",
			44: "ERR_SKIP",
			
			# ///< user requested help!! (45)
			ERR_HELP: "ERR_HELP",
			
			# ///< a bug in the software certainly happened, due to a double check failing or unexpected behavior.
			ERR_BUG: "ERR_BUG",
			
			# /// the parallel port printer is engulfed in flames
			#ERR_PRINTER_ON_FIRE: "ERR_PRINTER_ON_FIRE",
			47: "ERR_PRINTER_ON_FIRE",
			
			# ///< s**t happens, has never been used: though
			#ERR_OMFG_THIS_IS_VERY_VERY_BAD: "ERR_OMFG_THIS_IS_VERY_VERY_BAD"
			# ///< short version of the above
			ERR_WTF: "ERR_OMFG_THIS_IS_VERY_VERY_BAD"
		}
		Globals.set("__error_codes__", ret)
		Globals.set_persisting("__error_codes__", false)
		return ret