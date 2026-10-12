note
	description: "[
		Default console driver for the host platform (Windows build).
		The ECF selects this cluster only on Windows; the POSIX cluster provides
		a TERMINAL_DRIVER of the same name inheriting POSIX_CONSOLE_DRIVER.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TERMINAL_DRIVER

inherit
	WIN32_CONSOLE_DRIVER

create
	default_create

end
