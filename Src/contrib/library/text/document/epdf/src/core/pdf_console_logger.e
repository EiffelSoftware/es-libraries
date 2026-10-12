note
	description: "[
		Console implementation of PDF_LOGGER.
		Writes log messages to standard output.
	]"
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_CONSOLE_LOGGER

inherit
	PDF_LOGGER

feature -- Logging

	info (m: READABLE_STRING_GENERAL)
		do
			io.put_string_32 (m.to_string_32)
			if not m.ends_with ("%N") then
				io.put_new_line
			end
		ensure then
			class
		end

	failure (m: READABLE_STRING_GENERAL)
		do
			io.error.put_string_32 (m.to_string_32)
			if not m.ends_with ("%N") then
				io.error.put_new_line
			end
		ensure then
			class
		end

end
