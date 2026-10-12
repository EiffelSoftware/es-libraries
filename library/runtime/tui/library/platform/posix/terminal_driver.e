note
	description: "[
		Default console driver for the host platform (POSIX build).
		The ECF selects this cluster on every platform except Windows; the Windows
		cluster provides a TERMINAL_DRIVER of the same name inheriting WIN32_CONSOLE_DRIVER.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TERMINAL_DRIVER

inherit
	POSIX_CONSOLE_DRIVER

create
	default_create

end
