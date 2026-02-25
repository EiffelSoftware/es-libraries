note
	description: "Summary description for {NULL_NATURAL_8_INPUT_STREAM}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	NULL_NATURAL_8_INPUT_STREAM

inherit
	NULL_INPUT_STREAM

	NATURAL_8_INPUT_STREAM

feature -- Access	

	last_byte: NATURAL_8 = 0
			-- Last read byte

end
