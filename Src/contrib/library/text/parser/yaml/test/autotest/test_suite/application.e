note
	description: "Test application for YAML library."
	date: "$Date$"
	revision: "$Revision$"

class
	APPLICATION

create
	make

feature {NONE} -- Initialization

	make
			-- Run tests.
		do
			io.put_string ("YAML Library Test Suite%N")
			io.put_string ("Run with autotest for full test execution.%N")
		end

end
