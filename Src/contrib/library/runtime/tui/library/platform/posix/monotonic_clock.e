note
	description: "[
		Monotonic millisecond clock (POSIX build, clock_gettime (CLOCK_MONOTONIC)).
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
			"C inline use <time.h>"
		alias
			"[
				struct timespec ts;
				clock_gettime (CLOCK_MONOTONIC, &ts);
				return (EIF_INTEGER_64) ts.tv_sec * 1000 + (EIF_INTEGER_64) (ts.tv_nsec / 1000000);
			]"
		ensure
			instance_free: class
		end

end
