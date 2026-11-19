note
	description: "[
		One message of a TOAST_QUEUE: its `id`, its text, its level (TOAST_LEVEL) and how long
		it is shown (`duration_ms`). A toast is made by the queue (`TOAST_QUEUE.push`), which
		starts its clock at the first `TOAST_QUEUE.expire` at which it is visible
		(`started_at_ms`); a toast that waits behind `TOAST_QUEUE.max_visible` others is not
		started.

		`id` is given by the queue, one more than the last one it gave, and stays the
		toast's while it is in the queue, whatever expires or is dismissed before it: a
		hit region registered under it (TUI_TOAST) dismisses the right toast
		(`TOAST_QUEUE.dismiss_id`) even when the queue changed between the frame and the click.

		Expiry: a started toast is expired at `a_now_ms` when `a_now_ms - started_at_ms >=
		duration_ms`, so a toast of 3000 ms started at t is still shown at t + 2999 and gone
		at t + 3000. The difference is taken as a NATURAL_64, so any two INTEGER_64 times of a
		monotonic clock work without overflow.

		Only the queue starts and stops a toast (the commands are exported to TOAST_QUEUE),
		so nothing can break the queue's invariant from outside.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TOAST

inherit
	ANY
		redefine
			copy,
			is_equal
		end

create {TOAST_QUEUE}
	make

feature {NONE} -- Initialization

	make (a_id: INTEGER; a_text: TEXT; a_level: NATURAL_8; a_duration_ms: INTEGER_64)
			-- Toast `a_id` showing a copy of `a_text` at `a_level` for `a_duration_ms`, not
			-- started.
		require
			positive_id: a_id >= 1
			text_not_void: a_text /= Void
			valid_level: {TOAST_LEVEL}.is_valid (a_level)
			positive_duration: a_duration_ms > 0
		do
			id := a_id
			text := a_text.twin
			level := a_level
			duration_ms := a_duration_ms
		ensure
			id_set: id = a_id
			text_copied: text ~ a_text and text /= a_text
			level_set: level = a_level
			duration_set: duration_ms = a_duration_ms
			not_started: not is_started
		end

feature -- Access

	id: INTEGER
			-- Number given by the queue, unique in it

	text: TEXT
			-- Message, one or more lines (the toast's own copy)

	level: NATURAL_8
			-- Severity (TOAST_LEVEL)

	duration_ms: INTEGER_64
			-- How long the toast is shown once started, in milliseconds

	started_at_ms: INTEGER_64
			-- Time at which the toast became visible; 0 when not started

feature -- Status report

	is_started: BOOLEAN
			-- Is the toast visible, its clock running?

	is_expired_at (a_now_ms: INTEGER_64): BOOLEAN
			-- Has a started toast been shown for `duration_ms` at `a_now_ms`?
		require
			not_before_start: is_started implies a_now_ms >= started_at_ms
		do
			if is_started then
				Result := a_now_ms.as_natural_64 - started_at_ms.as_natural_64 >= duration_ms.as_natural_64
			end
		ensure
			not_started_never_expires: not is_started implies not Result
		end

feature {TOAST_QUEUE} -- Element change

	start (a_now_ms: INTEGER_64)
			-- Start the toast's clock at `a_now_ms`.
		do
			started_at_ms := a_now_ms
			is_started := True
		ensure
			started: is_started
			started_at_set: started_at_ms = a_now_ms
		end

	stop
			-- Stop the toast's clock: it waits again, and gets its whole duration when shown.
		do
			started_at_ms := 0
			is_started := False
		ensure
			not_started: not is_started
		end

feature -- Duplication

	copy (a_other: like Current)
			-- Copy `a_other`, with its own copy of the text.
		do
			if a_other /= Current then
				standard_copy (a_other)
				text := a_other.text.twin
			end
		end

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Same id, text, level, duration and clock?
		do
			if a_other = Current then
				Result := True
			else
				Result := id = a_other.id
					and text ~ a_other.text
					and level = a_other.level
					and duration_ms = a_other.duration_ms
					and is_started = a_other.is_started
					and started_at_ms = a_other.started_at_ms
			end
		end

invariant
	positive_id: id >= 1
	text_not_void: text /= Void
	valid_level: {TOAST_LEVEL}.is_valid (level)
	positive_duration: duration_ms > 0
	not_started_at_zero: not is_started implies started_at_ms = 0

end
