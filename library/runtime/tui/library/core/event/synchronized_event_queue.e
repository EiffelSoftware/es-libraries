note
	description: "[
		Thread-safe FIFO queue for delivering EVENT objects from background
		input / timer threads to the main application render thread.
		Uses an Eiffel MUTEX and CONDITION_VARIABLE, so a consumer blocked in
		`poll_with_timeout' wakes as soon as an event is pushed, on every platform,
		or when `wake' is called.

		Lock discipline: a routine that can raise while `mutex' is held (`push' may allocate,
		`poll_with_timeout' waits) unlocks it in its rescue clause, so an exception there
		cannot leave the queue locked and the consumer deadlocked. The other locked regions
		do not allocate.

		Floods (review finding M5):
		  * Coalescing (`is_coalescing', on by default): when the consumer takes a drag, move or
		    resize event and the next waiting event is of the same sort (same kind, button and
		    modifiers for the mouse), only the newest is delivered. A consumer that keeps up never
		    sees a difference; one that falls behind skips the intermediate positions and sizes.
		  * Bound (`max_count'): `is_full' tells a producer to stop reading input for a while,
		    which EVENT_THREAD does. The input then waits in the operating system's buffer: no
		    event is dropped, and the queue holds at most `max_count' plus the few events of
		    one input byte.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	SYNCHRONIZED_EVENT_QUEUE

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize synchronized queue and its condition variable.
		do
			create queue.make (32)
			create mutex.make
			create not_empty.make
			max_count := Default_max_count
			is_coalescing := True
		ensure
			empty: is_empty
			default_max_count: max_count = Default_max_count
			coalescing: is_coalescing
		end

feature -- Settings

	max_count: INTEGER
			-- Number of waiting events at which `is_full` holds

	Default_max_count: INTEGER = 4096
			-- Default `max_count`

	set_max_count (a_count: INTEGER)
			-- Set `max_count` to `a_count`.
		require
			positive: a_count > 0
		do
			mutex.lock
			max_count := a_count
			mutex.unlock
		ensure
			set: max_count = a_count
		end

	is_coalescing: BOOLEAN
			-- Are consecutive drag, move and resize events of the same sort merged into the newest?

	set_coalescing (a_on: BOOLEAN)
			-- Merge (`a_on`) or deliver every drag, move and resize event.
		do
			mutex.lock
			is_coalescing := a_on
			mutex.unlock
		ensure
			set: is_coalescing = a_on
		end

feature -- Operations

	push (a_event: EVENT)
			-- Thread-safe push of `a_event` into queue and wake a waiting consumer.
		require
			event_attached: a_event /= Void
		local
			l_locked: BOOLEAN
		do
			mutex.lock
			l_locked := True
			queue.extend (a_event)
			not_empty.signal
			l_locked := False
			mutex.unlock
		rescue
			if l_locked then
				l_locked := False
				mutex.unlock
			end
		end

	wake
			-- Make a consumer waiting in `poll_with_timeout` (now or next) return at once, even
			-- with no event. For a producer that needs the consumer to look at something else,
			-- such as a pending termination request.
		do
			mutex.lock
			is_woken := True
			not_empty.signal
			mutex.unlock
		end

	poll: detachable EVENT
			-- Thread-safe dequeue of next event (see `is_coalescing`), or Void if queue is empty.
		do
			mutex.lock
			if not queue.is_empty then
				Result := oldest_event
			end
			mutex.unlock
		end

	poll_with_timeout (a_timeout_ms: INTEGER): detachable EVENT
			-- Wait up to `a_timeout_ms` milliseconds for an event to arrive.
			-- Returns next event, or Void if the timeout elapsed with the queue still empty,
			-- or if `wake` was called since the last `poll_with_timeout`.
		require
			non_negative_timeout: a_timeout_ms >= 0
		local
			l_deadline, l_remaining: INTEGER_64
			l_timed_out: BOOLEAN
			l_locked: BOOLEAN
		do
			mutex.lock
			l_locked := True
			if queue.is_empty and a_timeout_ms > 0 then
				from
					l_deadline := {MONOTONIC_CLOCK}.milliseconds + a_timeout_ms
					l_remaining := a_timeout_ms
				until
					not queue.is_empty or l_timed_out or is_woken
				loop
					-- The wait may also end spuriously: re-check the queue and the deadline.
					l_timed_out := not not_empty.wait_with_timeout (mutex, l_remaining.to_integer_32)
					l_remaining := l_deadline - {MONOTONIC_CLOCK}.milliseconds
					if l_remaining <= 0 then
						l_timed_out := True
					end
				end
			end
			is_woken := False
			if not queue.is_empty then
				Result := oldest_event
			end
			l_locked := False
			mutex.unlock
		rescue
			-- A failed wait returns with `mutex` locked again
			if l_locked then
				l_locked := False
				mutex.unlock
			end
		end

	wipe_out
			-- Remove all queued events.
		do
			mutex.lock
			queue.wipe_out
			mutex.unlock
		ensure
			empty: is_empty
		end

feature -- Status report

	is_empty: BOOLEAN
			-- Is queue currently empty?
		do
			mutex.lock
			Result := queue.is_empty
			mutex.unlock
		end

	is_full: BOOLEAN
			-- Are `max_count` or more events waiting? (A producer should wait before adding more.)
		do
			mutex.lock
			Result := queue.count >= max_count
			mutex.unlock
		end

	coalesced_count: INTEGER
			-- Number of events dropped so far because a newer one of the same sort followed
		do
			mutex.lock
			Result := internal_coalesced_count
			mutex.unlock
		end

	count: INTEGER
			-- Number of events currently waiting in queue
		do
			mutex.lock
			Result := queue.count
			mutex.unlock
		ensure
			non_negative: Result >= 0
		end

feature {NONE} -- Implementation

	oldest_event: EVENT
			-- Remove and return the oldest event, or with `is_coalescing` the newest of the run
			-- of events it starts that `supersedes` merges. Call with `mutex` held.
		require
			not_empty: not queue.is_empty
		do
			Result := queue.item
			queue.remove
			if is_coalescing then
				from
				until
					queue.is_empty or else not supersedes (queue.item, Result)
				loop
					Result := queue.item
					queue.remove
					internal_coalesced_count := internal_coalesced_count + 1
				end
			end
		end

	supersedes (a_next, a_previous: EVENT): BOOLEAN
			-- Does `a_next`, coming right after `a_previous`, make it obsolete? True for two
			-- resizes, and for two drags or two moves with the same button and modifiers.
		do
			if attached {RESIZE_EVENT} a_next and attached {RESIZE_EVENT} a_previous then
				Result := True
			elseif attached {MOUSE_EVENT} a_next as l_next and then attached {MOUSE_EVENT} a_previous as l_previous then
				Result := (l_next.is_drag or l_next.is_move) and l_next.kind = l_previous.kind and
					l_next.button = l_previous.button and l_next.modifiers ~ l_previous.modifiers
			end
		end

	internal_coalesced_count: INTEGER
			-- Backing store of `coalesced_count` (guarded by `mutex`)

	queue: ARRAYED_QUEUE [EVENT]
			-- Underlying FIFO event buffer

	mutex: MUTEX
			-- Lock guarding `queue`

	not_empty: CONDITION_VARIABLE
			-- Signalled whenever an event is pushed, and by `wake`

	is_woken: BOOLEAN
			-- Was `wake` called since the last `poll_with_timeout`? (Guarded by `mutex`.)

end
