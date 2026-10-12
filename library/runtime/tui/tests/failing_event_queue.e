note
	description: "[
		SYNCHRONIZED_EVENT_QUEUE whose next `push' fails while it holds the lock
		(see FAILING_ARRAYED_QUEUE), for tests of review finding C6.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	FAILING_EVENT_QUEUE

inherit
	SYNCHRONIZED_EVENT_QUEUE
		redefine
			make,
			queue
		end

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize an empty queue whose pushes succeed until `fail_next_push`.
		do
			create queue.make (32)
			create mutex.make
			create not_empty.make
			max_count := Default_max_count
			is_coalescing := True
		end

feature -- Settings

	fail_next_push
			-- Make the next `push` raise while the lock is held.
		do
			queue.fail_next_extend
		end

feature {NONE} -- Implementation

	queue: FAILING_ARRAYED_QUEUE [EVENT]
			-- Underlying FIFO event buffer

end
