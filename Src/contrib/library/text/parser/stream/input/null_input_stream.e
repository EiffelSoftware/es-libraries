note
	description: "Summary description for {NULL_INPUT_STREAM}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	NULL_INPUT_STREAM

inherit
	INPUT_STREAM

feature -- Access		

	name: IMMUTABLE_STRING_32 = "VOID"

feature -- Status report

	end_of_input: BOOLEAN = True
			-- Has the end of input stream been reached?
			-- i.e: cursor is out of stream range.

	is_open_read: BOOLEAN = True
			-- Can items be read from input stream?

	valid_index (i: INTEGER): BOOLEAN
		do
			Result := False
		end

feature -- Access

	index: INTEGER = 0
			-- Current position in the input stream

	line: INTEGER = 0
			-- Current line number

	column: INTEGER = 0
			-- Current column number

feature -- Basic operation

	start
		do
		end

	next
			-- Read a character's code
			-- and keep it in `last_character_code'
		do
		end

end
