note
	description: "[
		Monotonic millisecond clock (Windows build, GetTickCount64).
		Used for event-loop tick deadlines and bounded waits; never goes backwards.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	MONOTONIC_CLOCK

feature -- Access

	milliseconds: INTEGER_64
			-- Milliseconds elapsed since an arbitrary fixed origin.
		external
			"C inline use <windows.h>"
		alias
			"return (EIF_INTEGER_64) GetTickCount64 ();"
		ensure
			instance_free: class
		end

end
