note
	description: "[
		ARRAYED_QUEUE whose next `extend' can be made to raise, as an out-of-memory would,
		for tests of the lock discipline of SYNCHRONIZED_EVENT_QUEUE (review finding C6).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	FAILING_ARRAYED_QUEUE [G]

inherit
	ARRAYED_QUEUE [G]
		redefine
			extend
		end

create
	make

feature -- Settings

	fail_next_extend
			-- Make the next `extend` raise instead of adding its item.
		do
			is_next_extend_failing := True
		end

	is_next_extend_failing: BOOLEAN
			-- Will the next `extend` raise?

feature -- Element change

	extend (v: G)
			-- Add `v` as newest item, or raise if `fail_next_extend` was called.
		do
			if is_next_extend_failing then
				is_next_extend_failing := False
				(create {DEVELOPER_EXCEPTION}).raise
			else
				Precursor (v)
			end
		end

end
