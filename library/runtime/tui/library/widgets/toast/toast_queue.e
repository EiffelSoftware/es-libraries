note
	description: "[
		State for TUI_TOAST: the toasts to show, oldest first, each with a level and a
		duration, and the time they expire, driven by the caller's clock. Ratatui has no toast
		(apps and third-party crates keep their own list); this is EiffelTUI's own.

		Clock: the queue never reads a clock. Its time is the last one given to `expire`
		(or `make_at`), `now_ms`. The application calls `expire` with
		{MONOTONIC_CLOCK}.milliseconds on each TICK_EVENT:

		    if a_event.is_tick then
		        toasts.expire ({MONOTONIC_CLOCK}.milliseconds)
		    end

		so tests pass any time they like. A toast's clock starts at the first `expire` at
		which it is visible, and the toast is expired when it has been shown for its whole
		duration from then: started at t for 3000 ms, `expire (t + 2999)` keeps it and
		`expire (t + 3000)` drops it (TOAST.is_expired_at). `push` takes no time: a toast
		pushed between two ticks starts at the next one, so it is shown for its whole
		duration, up to one tick more, never less (*decided*; the queue's last time could be
		a whole tick old, and stamping a toast with it would shorten it). An application
		that pushes and never calls `expire` keeps its toasts.

		Visible and waiting: the first `max_visible` toasts (the oldest) are visible; the
		others wait, in order, and none is dropped. A waiting toast starts when it has
		become visible (an older one expired or was dismissed, or `max_visible` was raised)
		at the next `expire`, so each toast is shown for its whole duration, however many
		arrive at once. A visible toast that has to wait again (`max_visible` lowered) stops
		its clock.

		Ids: each toast pushed gets the next `id` (`last_id` + 1), which it keeps; `has_id`,
		`index_of_id` and `dismiss_id` find it whatever changed in the queue since, so a click
		on a toast's box (TUI_TOAST registers it under its id) dismisses that toast.

		Expiry action: `expired_action`, if set, is called with each toast `expire` dropped,
		after the queue is consistent again, so the action may `push` (a follow-up message),
		`dismiss` or `clear`. A toast it pushes starts at the next `expire`. `dismiss` and
		`clear` do not call the action.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TOAST_QUEUE

inherit
	WIDGET_STATE
		redefine
			default_create,
			copy,
			is_equal
		end

create
	default_create,
	make_at

feature {NONE} -- Initialization

	default_create
			-- Empty queue showing at most `Default_max_visible` toasts, with no time yet.
		do
			create items.make (Default_max_visible)
			create last_expired.make (0)
			max_visible := Default_max_visible
		ensure then
			empty: is_empty
			default_bound: max_visible = Default_max_visible
			no_time: not has_time
		end

	make_at (a_now_ms: INTEGER_64)
			-- Empty queue whose time is `a_now_ms`.
		do
			default_create
			now_ms := a_now_ms
			has_time := True
		ensure
			empty: is_empty
			time_set: has_time and now_ms = a_now_ms
		end

feature -- Access

	count: INTEGER
			-- Number of toasts, visible and waiting
		do
			Result := items.count
		ensure
			definition: Result = items.count
		end

	item (a_index: INTEGER): TOAST
			-- Toast number `a_index`, oldest first (the first `visible_count` are visible)
		require
			valid_index: a_index >= 1 and a_index <= count
		do
			Result := items.i_th (a_index)
		end

	max_visible: INTEGER
			-- Most toasts shown at once; the others wait

	visible_count: INTEGER
			-- Number of toasts shown
		do
			Result := count.min (max_visible)
		ensure
			definition: Result = count.min (max_visible)
		end

	waiting_count: INTEGER
			-- Number of toasts waiting for room
		do
			Result := count - visible_count
		ensure
			definition: Result = count - visible_count
		end

	now_ms: INTEGER_64
			-- The queue's time: the last time given to `expire` or `make_at`

	expired_action: detachable PROCEDURE [TOAST]
			-- Called with each toast `expire` drops, if set

	last_expired: ARRAYED_LIST [TOAST]
			-- Toasts dropped by the last `expire`, oldest first (a new list on each call)

	Default_max_visible: INTEGER = 3
			-- `max_visible` of a new queue

	last_id: INTEGER
			-- `id` of the last toast pushed (0 before the first)

	index_of_id (a_id: INTEGER): INTEGER
			-- Index of the toast whose `id` is `a_id`, 0 if none is in the queue
		local
			i: INTEGER
		do
			from i := 1 until Result > 0 or i > count loop
				if items.i_th (i).id = a_id then
					Result := i
				end
				i := i + 1
			end
		ensure
			none_or_match: Result = 0 or else item (Result).id = a_id
		end

feature -- Status report

	is_empty: BOOLEAN
			-- No toast at all?
		do
			Result := items.is_empty
		ensure
			definition: Result = (count = 0)
		end

	has_time: BOOLEAN
			-- Has the queue been given a time (`make_at` or `expire`)?

	has_id (a_id: INTEGER): BOOLEAN
			-- Is the toast `a_id` in the queue (visible or waiting)?
		do
			Result := index_of_id (a_id) > 0
		ensure
			definition: Result = (index_of_id (a_id) > 0)
		end

	is_visible (a_index: INTEGER): BOOLEAN
			-- Is toast `a_index` shown?
		require
			valid_index: a_index >= 1 and a_index <= count
		do
			Result := a_index <= visible_count
		ensure
			definition: Result = (a_index <= visible_count)
		end

feature -- Element change

	push (a_text: READABLE_STRING_GENERAL; a_level: NATURAL_8; a_duration_ms: INTEGER_64)
			-- Add a toast showing `a_text` (split on %N) at `a_level` for `a_duration_ms`.
		require
			text_not_void: a_text /= Void
			valid_level: {TOAST_LEVEL}.is_valid (a_level)
			positive_duration: a_duration_ms > 0
		do
			push_text (create {TEXT}.make_raw (a_text), a_level, a_duration_ms)
		ensure
			one_more: count = old count + 1
			last_level: item (count).level = a_level
			last_duration: item (count).duration_ms = a_duration_ms
			next_id: item (count).id = old last_id + 1 and last_id = item (count).id
			not_started: not item (count).is_started
		end

	push_text (a_text: TEXT; a_level: NATURAL_8; a_duration_ms: INTEGER_64)
			-- Add a toast showing a copy of the styled `a_text` at `a_level` for `a_duration_ms`,
			-- with the next `id`. It is visible when fewer than `max_visible` are, else it
			-- waits; either way its clock starts at the first `expire` at which it is visible.
		require
			text_not_void: a_text /= Void
			valid_level: {TOAST_LEVEL}.is_valid (a_level)
			positive_duration: a_duration_ms > 0
		do
			last_id := last_id + 1
			items.extend (create {TOAST}.make (last_id, a_text, a_level, a_duration_ms))
		ensure
			one_more: count = old count + 1
			last_text: item (count).text ~ a_text
			last_level: item (count).level = a_level
			last_duration: item (count).duration_ms = a_duration_ms
			next_id: item (count).id = old last_id + 1 and last_id = item (count).id
			not_started: not item (count).is_started
		end

	expire (a_now_ms: INTEGER_64)
			-- Set the time to `a_now_ms`, drop the started toasts shown for their whole duration
			-- by then, start the clocks of the visible toasts not started yet at `a_now_ms`,
			-- then call `expired_action` with each dropped toast.
		require
			time_forward: has_time implies a_now_ms >= now_ms
		local
			i: INTEGER
			l_toast: TOAST
			l_gone: ARRAYED_LIST [TOAST]
		do
			now_ms := a_now_ms
			has_time := True
			create l_gone.make (0)
			from
				i := 1
			until
				i > items.count
			loop
				l_toast := items.i_th (i)
				if l_toast.is_expired_at (a_now_ms) then
					items.go_i_th (i)
					items.remove
					l_gone.extend (l_toast)
				else
					i := i + 1
				end
			end
			start_visible
			last_expired := l_gone
			if attached expired_action as l_action then
				across l_gone as t loop
					l_action.call ([t])
				end
			end
		ensure
			time_set: has_time and now_ms = a_now_ms
			none_expired_left: (expired_action = Void) implies
				across 1 |..| count as j all not item (j).is_expired_at (a_now_ms) end
			dropped_were_expired: (expired_action = Void) implies
				across last_expired as t all t.is_expired_at (a_now_ms) end
			dropped_counted: (expired_action = Void) implies count = old count - last_expired.count
			visible_started: (expired_action = Void) implies
				across 1 |..| visible_count as j all item (j).is_started end
		end

	dismiss (a_index: INTEGER)
			-- Remove toast `a_index` (visible or waiting) now, without calling `expired_action`.
			-- A toast that becomes visible starts at the next `expire`.
		require
			valid_index: a_index >= 1 and a_index <= count
		do
			items.go_i_th (a_index)
			items.remove
		ensure
			one_less: count = old count - 1
		end

	dismiss_id (a_id: INTEGER)
			-- Remove the toast whose `id` is `a_id` (see `dismiss`).
		require
			in_queue: has_id (a_id)
		do
			dismiss (index_of_id (a_id))
		ensure
			one_less: count = old count - 1
			gone: not has_id (a_id)
		end

	clear
			-- Remove every toast, without calling `expired_action`.
		do
			items.wipe_out
		ensure
			empty: is_empty
		end

	set_max_visible (a_max: INTEGER)
			-- Show at most `a_max` toasts at once. Toasts that become visible start their
			-- clocks at the next `expire`; visible toasts that now wait stop theirs (and get
			-- their whole duration again when shown).
		require
			positive: a_max >= 1
		do
			max_visible := a_max
			stop_waiting
		ensure
			max_visible_set: max_visible = a_max
			count_kept: count = old count
		end

	set_expired_action (a_action: detachable PROCEDURE [TOAST])
			-- Call `a_action` with each toast `expire` drops (Void: none).
		do
			expired_action := a_action
		ensure
			expired_action_set: expired_action = a_action
		end

feature -- Fluent Builders

	with_max_visible (a_max: INTEGER): like Current
			-- Copy of Current showing at most `a_max` toasts at once.
		require
			positive: a_max >= 1
		do
			Result := twin
			Result.set_max_visible (a_max)
		ensure
			result_not_void: Result /= Void
			max_visible_set: Result.max_visible = a_max
			unchanged: max_visible = old max_visible
		end

	with_expired_action (a_action: detachable PROCEDURE [TOAST]): like Current
			-- Copy of Current calling `a_action` with each toast `expire` drops.
		do
			Result := twin
			Result.set_expired_action (a_action)
		ensure
			result_not_void: Result /= Void
			expired_action_set: Result.expired_action = a_action
		end

feature -- Duplication

	copy (a_other: like Current)
			-- Copy `a_other`, with its own list of its own toasts, so that a copy made by a
			-- `with_*` builder expires and dismisses independently of the original.
		local
			l_items: ARRAYED_LIST [TOAST]
		do
			if a_other /= Current then
				standard_copy (a_other)
				create l_items.make (a_other.items.count.max (Default_max_visible))
				across a_other.items as t loop
					l_items.extend (t.twin)
				end
				items := l_items
				last_expired := a_other.last_expired.twin
			end
		end

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Same bound, time, action and toasts (compared by value, in order)?
		local
			i: INTEGER
		do
			if a_other = Current then
				Result := True
			else
				Result := max_visible = a_other.max_visible
					and last_id = a_other.last_id
					and has_time = a_other.has_time
					and now_ms = a_other.now_ms
					and expired_action = a_other.expired_action
					and count = a_other.count
					and last_expired.count = a_other.last_expired.count
				from
					i := 1
				until
					not Result or i > count
				loop
					Result := item (i) ~ a_other.item (i)
					i := i + 1
				end
				from
					i := 1
				until
					not Result or i > last_expired.count
				loop
					Result := last_expired.i_th (i) ~ a_other.last_expired.i_th (i)
					i := i + 1
				end
			end
		end

feature {TOAST_QUEUE} -- Implementation

	items: ARRAYED_LIST [TOAST]
			-- Toasts, oldest first

feature {NONE} -- Implementation

	start_visible
			-- Start the visible toasts that are not started, at `now_ms`.
		require
			has_time: has_time
		local
			i: INTEGER
		do
			from i := 1 until i > visible_count loop
				if not items.i_th (i).is_started then
					items.i_th (i).start (now_ms)
				end
				i := i + 1
			end
		ensure
			visible_started: across 1 |..| visible_count as j all item (j).is_started end
		end

	stop_waiting
			-- Stop the clocks of the waiting toasts that are started.
		local
			i: INTEGER
		do
			from i := visible_count + 1 until i > count loop
				if items.i_th (i).is_started then
					items.i_th (i).stop
				end
				i := i + 1
			end
		ensure
			waiting_stopped: across 1 |..| count as j all item (j).is_started implies is_visible (j) end
		end

invariant
	items_not_void: items /= Void
	last_expired_not_void: last_expired /= Void
	positive_max_visible: max_visible >= 1
	non_negative_last_id: last_id >= 0
	only_shown_started: across 1 |..| count as i all item (i).is_started implies i <= visible_count end
	ids_given: across 1 |..| count as i all item (i).id <= last_id end
	started_in_the_past: across 1 |..| count as i all item (i).is_started implies item (i).started_at_ms <= now_ms end

end
