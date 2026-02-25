note
	description: "STREAM test suite application."
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
			io.put_string ("STREAM Test Suite%N")
			io.put_string ("==============%N")
		end

note
	copyright: "2026, Jocelyn Fiat and Eiffel Software"
	license: "MIT License"
end
