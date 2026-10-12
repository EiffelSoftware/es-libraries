note
	description: "[
		Application runner managing the event loop, background input thread,
		frame rendering pipeline via TERMINAL and FRAME, and terminal restoration.

		Loop: wait for an event or the next tick deadline, process every pending event,
		emit a TICK_EVENT whenever `tick_rate_ms' has elapsed (even under a steady
		stream of input), then redraw. Diffing keeps unchanged frames cheap.

		Failures: any exception (from `process', `render', or a failed input thread)
		restores the terminal first and is then propagated to the caller.

		Termination requests (Ctrl+Break, closing the console, SIGINT, ...): while `run' has the
		terminal set up, the driver's handler only records them (see
		{CONSOLE_DRIVER}.is_deferring_termination). The loop then stops, restores the terminal
		like any other exit, and ends the process as the request's default action would. So
		the handler never writes to the terminal while a frame is being written.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	TUI_APPLICATION

feature -- Initialization

	make
			-- Initialize application in fullscreen (alternate screen) mode.
		do
			make_with_viewport (create {VIEWPORT}.make_fullscreen)
		ensure
			terminal_attached: terminal /= Void
			event_queue_attached: event_queue /= Void
			event_thread_attached: event_thread /= Void
			not_running: not is_running
		end

	make_with_viewport (a_viewport: VIEWPORT)
			-- Initialize application drawing into `a_viewport` on the platform console.
		require
			viewport_attached: a_viewport /= Void
		local
			l_backend: ANSI_TERMINAL_BACKEND
		do
			create l_backend.make
			make_with_terminal (create {TERMINAL [ANSI_TERMINAL_BACKEND]}.make_with_viewport (l_backend, a_viewport))
		ensure
			viewport_set: terminal.viewport = a_viewport
			not_running: not is_running
		end

	make_with_terminal (a_terminal: TERMINAL [ANSI_TERMINAL_BACKEND])
			-- Initialize application with custom `a_terminal`.
		require
			terminal_attached: a_terminal /= Void
		do
			terminal := a_terminal
			create event_queue.make
			create event_thread.make (event_queue, a_terminal.backend.driver)
			is_running := False
			tick_rate_ms := 50
			event_budget_ms := Default_event_budget_ms
		ensure
			terminal_set: terminal = a_terminal
			not_running: not is_running
		end

feature -- Access

	terminal: TERMINAL [ANSI_TERMINAL_BACKEND]
			-- Unified terminal coordinator and dual framebuffer manager

	backend: ANSI_TERMINAL_BACKEND
			-- Terminal output backend
		do
			Result := terminal.backend
		ensure
			backend_attached: Result /= Void
		end

	event_queue: SYNCHRONIZED_EVENT_QUEUE
			-- Thread-safe input event queue

	event_thread: EVENT_THREAD
			-- Background input reader thread (a new one for each `run` after the first,
			-- with the same settings: see `run`)

	tick_rate_ms: INTEGER
			-- Heartbeat timer interval in milliseconds

	event_budget_ms: INTEGER
			-- Time after which the loop stops processing waiting events and draws, even if more
			-- are waiting (so a flood of input, or slow handlers, cannot hold back the screen)

	Default_event_budget_ms: INTEGER = 50
			-- Default `event_budget_ms`

feature -- Status report

	is_running: BOOLEAN
			-- Is main application loop currently active?

	is_terminal_set_up: BOOLEAN
			-- Has `run` changed the terminal state (raw mode, screen) without restoring it yet?

	is_input_thread_available: BOOLEAN
			-- Can `run` start reading input? False only while an input thread from an earlier
			-- `run` is still alive because it did not stop within `Join_timeout_ms`: a second
			-- reader would race it for the console.
		do
			Result := event_thread.is_launchable or event_thread.terminated
		end

	input_thread_timed_out: BOOLEAN
			-- Did the last `run` return while its input thread was still running, because the
			-- thread did not stop within `Join_timeout_ms` (its read was blocked)? The terminal
			-- was restored anyway; the thread still holds the console input, so no other reader
			-- can start (see `is_input_thread_available`) until it ends. It ends as soon as its
			-- read returns: call `wait_for_input_thread` to wait for that.

feature -- Settings

	is_keyboard_enhancement_requested: BOOLEAN
			-- Should `run` push the Kitty keyboard enhancement flags (key release and repeat
			-- events, unambiguous escape codes)? Terminals without the protocol ignore it.

	set_keyboard_enhancement (a_enabled: BOOLEAN)
			-- Request (or not) keyboard enhancement for the next `run`
			-- (crossterm `PushKeyboardEnhancementFlags`).
		require
			not_while_set_up: not is_terminal_set_up
		do
			is_keyboard_enhancement_requested := a_enabled
		ensure
			set: is_keyboard_enhancement_requested = a_enabled
		end

	is_mouse_capture_requested: BOOLEAN
			-- Should `run` enable mouse capture reporting?

	set_mouse_capture (a_enabled: BOOLEAN)
			-- Request (or not) mouse capture for the next `run`.
		require
			not_while_set_up: not is_terminal_set_up
		do
			is_mouse_capture_requested := a_enabled
		ensure
			set: is_mouse_capture_requested = a_enabled
		end

	set_event_budget (a_ms: INTEGER)
			-- Draw at least every `a_ms` milliseconds while events keep arriving.
		require
			positive_ms: a_ms > 0
		do
			event_budget_ms := a_ms
		ensure
			set: event_budget_ms = a_ms
		end

	set_max_queued_events (a_count: INTEGER)
			-- Let the input thread wait once `a_count` events are waiting (see
			-- {SYNCHRONIZED_EVENT_QUEUE}.max_count).
		require
			positive: a_count > 0
		do
			event_queue.set_max_count (a_count)
		ensure
			set: event_queue.max_count = a_count
		end

	set_event_coalescing (a_on: BOOLEAN)
			-- Merge consecutive drag, move and resize events that are waiting into the newest
			-- (`a_on`, the default), or deliver each of them (see
			-- {SYNCHRONIZED_EVENT_QUEUE}.is_coalescing).
		do
			event_queue.set_coalescing (a_on)
		ensure
			set: event_queue.is_coalescing = a_on
		end

	set_tick_rate (a_ms: INTEGER)
			-- Set heartbeat timer tick rate in milliseconds.
		require
			positive_ms: a_ms > 0
		do
			tick_rate_ms := a_ms
		ensure
			tick_rate_set: tick_rate_ms = a_ms
		end

feature -- Commands

	wait_for_input_thread (a_timeout_ms: NATURAL_64)
			-- Wait up to `a_timeout_ms` milliseconds for the input thread of the last `run` to end,
			-- if it had not stopped when `run` returned.
		require
			not_running: not is_running
		do
			if input_thread_timed_out and then event_thread.join_with_timeout (a_timeout_ms) then
				input_thread_timed_out := False
			end
		ensure
			stopped_unless_timed_out: not input_thread_timed_out implies is_input_thread_available
		end

	stop
			-- Request application loop termination.
		do
			is_running := False
		ensure
			stopped: not is_running
		end

	run
			-- Set up the terminal, launch the input thread and run the event loop until `stop`.
			-- The terminal is always restored; an exception is re-raised after restoration.
			-- May be called again once it has returned (or raised): each run reads input on a
			-- new thread (see {EVENT_THREAD}.renewed), and events left over from the earlier
			-- run are discarded.
		require
			not_running: not is_running
			input_thread_available: is_input_thread_available
			input_not_in_use: not backend.is_input_in_use
		local
			l_event: detachable EVENT
			l_next_tick, l_now, l_budget_end: INTEGER_64
		do
			if not event_thread.is_launchable then
				-- A THREAD runs only once: read this run's input on a new one
				event_thread := event_thread.renewed
				event_queue.wipe_out
			end
			input_thread_timed_out := False
			is_running := True
			set_up_terminal

			-- The input thread starts after setup: an inline viewport reads the
			-- cursor position report directly from the console during setup.
			-- `start` holds the console's input claim until the thread ends, so any other
			-- read (a DSR query) is refused by its precondition meanwhile.
			event_thread.start
			is_input_thread_started := True

			terminal.draw (agent render)

			from
				l_next_tick := {MONOTONIC_CLOCK}.milliseconds + tick_rate_ms
			until
				not is_running
			loop
				-- Wait for the next event, but never past the next tick deadline
				l_event := event_queue.poll_with_timeout ((l_next_tick - {MONOTONIC_CLOCK}.milliseconds).max (0).to_integer_32)
				-- Process what is waiting, but draw after `event_budget_ms` even if more is
				-- waiting: the rest is taken at once by the next iteration's poll
				from
					l_budget_end := {MONOTONIC_CLOCK}.milliseconds + event_budget_ms
				until
					l_event = Void or not is_running
				loop
					process (l_event)
					if {MONOTONIC_CLOCK}.milliseconds >= l_budget_end then
						l_event := Void
					else
						l_event := event_queue.poll
					end
				end

				l_now := {MONOTONIC_CLOCK}.milliseconds
				if is_running and l_now >= l_next_tick then
					process (create {TICK_EVENT}.default_create)
					l_next_tick := l_next_tick + tick_rate_ms
					if l_next_tick <= l_now then
						-- Fell behind (slow frame): skip missed ticks instead of bursting them
						l_next_tick := l_now + tick_rate_ms
					end
				end

				if event_thread.has_failed then
					raise_input_failure
				end

				if backend.driver.has_termination_request then
					-- Restored by `clean_up' below, which then ends the process
					is_running := False
				end

				if is_running then
					terminal.draw (agent render)
				end
			end
			clean_up
		ensure
			stopped: not is_running
			terminal_restored: not is_terminal_set_up
		rescue
			-- Restore the terminal, then let the exception propagate to the caller
			clean_up
		end

feature {NONE} -- Lifecycle

	is_input_thread_started: BOOLEAN
			-- Has `event_thread` been launched?

	set_up_terminal
			-- Enter raw mode and prepare the screen for the viewport kind.
		do
			-- Set first, so that a failure half-way through still gets restored
			is_terminal_set_up := True
			-- From now on the loop, not the handler, restores the terminal on a termination request
			backend.driver.set_deferring_termination (True)
			terminal.enter_raw_mode
			if terminal.viewport.is_fullscreen then
				terminal.enter_alternate_screen
				terminal.clear_screen
			elseif terminal.viewport.is_inline then
				terminal.setup_inline_viewport
			end
			if is_keyboard_enhancement_requested then
				-- After entering the alternate screen: Kitty keeps one flag stack per screen
				backend.enable_keyboard_enhancement
			end
			if is_mouse_capture_requested then
				terminal.enable_mouse_capture
			end
			terminal.hide_cursor
		end

	clean_up
			-- Stop the input thread and restore the terminal. Safe to call more than once;
			-- never raises, so it cannot mask the exception that triggered it.
		local
			l_failed: BOOLEAN
		do
			is_running := False
			if not l_failed then
				if is_input_thread_started then
					is_input_thread_started := False
					event_thread.stop
					-- If the thread does not stop in time, the terminal is restored all the same
					-- (leaving it raw would be worse); the thread keeps its input claim
					input_thread_timed_out := not event_thread.join_with_timeout (Join_timeout_ms)
				end
				if is_terminal_set_up then
					is_terminal_set_up := False
					restore_terminal
				end
			end
			backend.driver.set_deferring_termination (False)
			if backend.driver.has_termination_request then
				-- A termination request came in while the terminal was set up: it is restored
				-- now, so let the request take its course (the platform drivers do not return)
				backend.driver.finish_termination
			end
		ensure
			stopped: not is_running
			terminal_restored: not is_terminal_set_up
			input_thread_stopped_or_reported: is_input_thread_available or input_thread_timed_out
			not_deferring: not backend.driver.is_deferring_termination
		rescue
			l_failed := True
			is_terminal_set_up := False
			-- Stopping the thread may be what failed: report it if it is still alive
			input_thread_timed_out := not is_input_thread_available
			retry
		end

	restore_terminal
			-- Undo `set_up_terminal`: escape sequences first, then the console modes.
		do
			if backend.is_keyboard_enhancement_enabled then
				-- Pop the flags while still on the screen they were pushed on
				backend.disable_keyboard_enhancement
			end
			if backend.is_mouse_captured then
				terminal.disable_mouse_capture
			end
			if terminal.viewport.is_fullscreen then
				terminal.show_cursor
				terminal.leave_alternate_screen
			else
				if terminal.viewport.is_inline then
					terminal.restore_inline_viewport
				end
				terminal.show_cursor
			end
			-- Disables mouse/paste/focus reporting, flushes, then restores the original modes
			terminal.leave_raw_mode
		end

	raise_input_failure
			-- Raise an exception describing why the input thread stopped.
		local
			l_exception: DEVELOPER_EXCEPTION
		do
			create l_exception
			l_exception.set_description (event_thread.failure_description)
			l_exception.raise
		end

	Join_timeout_ms: NATURAL_64 = 500
			-- Maximum wait for the input thread to finish its current poll

feature {NONE} -- Abstract hooks

	process (a_event: EVENT)
			-- Handle incoming user or system event.
		deferred
		end

	render (a_frame: FRAME)
			-- Draw current application view into `a_frame`.
		require
			frame_attached: a_frame /= Void
		deferred
		end

invariant
	terminal_attached: terminal /= Void
	event_queue_attached: event_queue /= Void
	event_thread_attached: event_thread /= Void
	event_thread_uses_queue: event_thread.queue = event_queue
	positive_tick_rate: tick_rate_ms > 0

end
