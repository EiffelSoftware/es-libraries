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
		terminal set up, or waits for it (see `is_waiting_for_terminal'), the driver's handler
		only records them (see {CONSOLE_DRIVER}.is_deferring_termination). The loop then
		stops, restores the terminal like any other exit (if it was set up), and ends the
		process as the request's default action would. So the handler never writes to the
		terminal while a frame is being written.

		Started in the background (`app &' under a job-control shell), `run' sets nothing up
		until the process owns the terminal (`is_start_pending', review finding M10).

		Background work: an application that starts worker threads stops and joins them in
		a redefined `stop_background_work', which `run' calls on every exit path before it
		returns (P2 B2).

		Clipboard read (OSC 52, P2b K3): `read_clipboard' (or `read_selection') asks the
		terminal for its clipboard, and `process' always receives exactly one CLIPBOARD_EVENT
		for it: the text, or `Status_unavailable' once `clipboard_timeout_ms' (3 s by default)
		has passed with no answer. One read is pending at a time: a read asked for while one
		is pending is ignored (`is_clipboard_read_pending'). A reply that comes with nothing
		pending (after the timeout, or not asked for by `read_clipboard'), before the frame
		that writes the read's request, or for another selection never reaches `process'
		(`late_clipboard_replies'). OSC 52 replies carry no id: a late reply to an earlier
		read that comes after a new read's request was written is taken for the new read's
		answer. A stop (Ctrl+Z) ends a pending read with
		`Status_unavailable', since the terminal may answer into the shell; while the process
		waits for its terminal nothing is asked, and the answer is `Status_unavailable'
		(`Unsent_clipboard_answer_ms' after the read). When
		`run' returns with a read pending, nothing is sent after the stop: the
		`Status_unavailable' answer is given at the start of the next `run'.
		What to expect, from each project's documentation (not yet checked by eye):
		  * xterm answers only when `allowWindowOps' is set (or `disallowedWindowOps' changed).
		  * kitty asks the user first by default (`clipboard_control').
		  * Alacritty's default allows copy only: no answer.
		  * Windows Terminal does not implement the read, and conhost has no OSC 52: no answer.
		  * tmux and GNU screen pass OSC 52 on only when told to, as for the copy.
		So a read that gets no answer is the normal case. Offer bracketed paste (the
		terminal's own paste key, a PASTE_EVENT) as the main way in, and treat
		`read_clipboard' as best effort. On Linux an application may also run `wl-paste' or
		`xclip' itself, in a worker that posts a CUSTOM_EVENT (`post_event'); the library
		starts no process.
		Windows (P2b K4): a driver that reads the system clipboard itself
		({CONSOLE_DRIVER}.provides_clipboard_read, True for WIN32_CONSOLE_DRIVER) is asked
		instead of the terminal: the read is made at once (it may wait about 100 ms while
		another program holds the clipboard), nothing is written to the terminal, and the
		answer is queued (`post_event') and reaches `process' by the same path as a
		terminal's reply, within the same rules (one answer per read, the timeout, a stop
		ends the read). Only that queued answer ends the read: an OSC 52 reply that comes
		meanwhile is late. Windows has no primary selection: `read_selection' reads the
		clipboard too (the answer's selection is still `p'). Text is passed on as read, CR LF
		line breaks included; text longer than the input thread's `max_osc_size' UTF-16 code
		units gives `Status_too_large', and a clipboard that cannot be opened
		`Status_unavailable'. The native read is the wrong clipboard for an application run
		on a Windows host over SSH (it reads the host's clipboard, not the client's).
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
			create last_hit_map.make
			is_running := False
			tick_rate_ms := 50
			event_budget_ms := Default_event_budget_ms
			is_suspend_on_ctrl_z := True
			clipboard_timeout_ms := Default_clipboard_timeout_ms
			clipboard_read_selection := {TERMINAL_BACKEND}.Clipboard_selection
		ensure
			terminal_set: terminal = a_terminal
			not_running: not is_running
			no_hit_regions: last_hit_map.is_empty
			suspends_on_ctrl_z: is_suspend_on_ctrl_z
			default_clipboard_timeout: clipboard_timeout_ms = Default_clipboard_timeout_ms
			no_clipboard_read: not is_clipboard_read_pending
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

feature -- Hit testing

	last_hit_map: HIT_MAP
			-- Hit regions registered while rendering the frame now on screen, in frame
			-- (viewport-relative) coordinates; replaced after every frame, empty before the first

	is_hit_map_on_screen: BOOLEAN
			-- Does the screen still show the frame whose regions are in `last_hit_map`, where
			-- it was drawn? Not before the first frame, nor between a resize event (or
			-- anything that erased, scrolled or moved the viewport, see {TERMINAL}.shown_area)
			-- and the next frame.
		do
			Result := terminal.shown_area /= Void and not is_resized_since_draw
		ensure
			definition: Result = (terminal.shown_area /= Void and not is_resized_since_draw)
		end

	is_in_viewport (a_mouse: MOUSE_EVENT): BOOLEAN
			-- Is the screen position of `a_mouse` on the frame now on screen, in the screen
			-- area where that frame was drawn?
		require
			mouse_attached: a_mouse /= Void
		do
			Result := is_hit_map_on_screen and then attached terminal.shown_area as l_shown
				and then l_shown.contains_point (a_mouse.column, a_mouse.row)
		ensure
			definition: Result = (is_hit_map_on_screen and then attached terminal.shown_area as l_shown
				and then l_shown.contains_point (a_mouse.column, a_mouse.row))
		end

	hit_test (a_mouse: MOUSE_EVENT): detachable WIDGET_ID
			-- Id of the control under `a_mouse` in the frame now on screen, or Void.
			-- Mouse events use screen coordinates and hit regions use the frame's, so the
			-- screen origin the frame was drawn at is subtracted first (inline and fixed
			-- viewports). That origin is the one recorded by the draw, not the viewport's
			-- current one, which `insert_before` or a resize may have moved since. A position
			-- outside that frame, or any position while the frame is not on screen (see
			-- `is_hit_map_on_screen`), hits nothing.
		require
			mouse_attached: a_mouse /= Void
		do
			if is_in_viewport (a_mouse) and then attached terminal.shown_area as l_shown then
				Result := last_hit_map.hit (a_mouse.column - l_shown.x, a_mouse.row - l_shown.y)
			end
		ensure
			outside_frame_hits_nothing: not is_in_viewport (a_mouse) implies Result = Void
			frame_coordinates: (is_in_viewport (a_mouse) and then attached terminal.shown_area as l_shown)
				implies Result = last_hit_map.hit (a_mouse.column - l_shown.x, a_mouse.row - l_shown.y)
		end

	is_resized_since_draw: BOOLEAN
			-- Was a RESIZE_EVENT processed since the last frame was drawn? The terminal may
			-- have reflowed or moved the screen contents, so `last_hit_map` is out of date.

feature -- Status report

	is_running: BOOLEAN
			-- Is main application loop currently active?

	is_terminal_set_up: BOOLEAN
			-- Has `run` changed the terminal state (raw mode, screen) without restoring it yet?

	is_resume_pending: BOOLEAN
			-- Was the process continued in the background (`bg`, `kill -CONT`) after a stop
			-- (Ctrl+Z, `suspend`, `kill -TSTP`)? The terminal is restored, and the loop sets it
			-- up again once the process owns it (review finding M9).

	is_start_pending: BOOLEAN
			-- Did `run` start in the background (`hello_tui &`), with the terminal not set up
			-- yet? The loop sets it up for the first time once the process owns it (`fg`;
			-- review finding M10).

	is_waiting_for_terminal: BOOLEAN
			-- Did `run` start in the background, or was the process stopped and then continued,
			-- and is its terminal not set up (again) yet? Until the loop sets it up (when the
			-- process owns the terminal), nothing is drawn and no input is read: in the
			-- background, the terminal belongs to the shell. Events and ticks are still processed.
		do
			Result := is_start_pending or is_resume_pending or backend.driver.has_resume_request
		end

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

	is_keyboard_enhancement_if_supported_requested: BOOLEAN
			-- Should `run` ask the terminal whether it speaks the Kitty keyboard protocol, and
			-- push the enhancement flags only if it does (`keyboard_enhancement_support`)?

	set_keyboard_enhancement_if_supported (a_enabled: BOOLEAN)
			-- Request (or not), for the next `run`, keyboard enhancement on terminals that
			-- support it: `run` asks once, as crossterm's `supports_keyboard_enhancement`, then
			-- pushes the flags only when the answer is "supported". The question costs a round
			-- trip at start-up (keys typed meanwhile are delivered after it, and replies that
			-- come after the wait are dropped, not passed to `process`); without this setting
			-- nothing is asked. `set_keyboard_enhancement (True)` pushes the flags whatever the
			-- answer. On Windows the driver builds the release and repeat events itself
			-- ({CONSOLE_DRIVER}.provides_keyboard_enhancement), so nothing is asked there and
			-- the answer is "supported".
		require
			not_while_set_up: not is_terminal_set_up
		do
			is_keyboard_enhancement_if_supported_requested := a_enabled
		ensure
			set: is_keyboard_enhancement_if_supported_requested = a_enabled
		end

	keyboard_enhancement_support: INTEGER
			-- Answer of the terminal (or of a driver that provides the events itself,
			-- {CONSOLE_DRIVER}.provides_keyboard_enhancement) to the keyboard support query of the last `run` (see
			-- `set_keyboard_enhancement_if_supported`): `Keyboard_enhancement_unknown` (not
			-- asked, or no answer), `Keyboard_enhancement_supported` or
			-- `Keyboard_enhancement_unsupported`. Asked once per `run`, when the terminal is
			-- first set up; a resume after a stop keeps the answer.

	is_keyboard_enhancement_supported: BOOLEAN
			-- Did the terminal answer that it speaks the Kitty keyboard protocol?
		do
			Result := keyboard_enhancement_support = Keyboard_enhancement_supported
		ensure
			definition: Result = (keyboard_enhancement_support = Keyboard_enhancement_supported)
		end

	Keyboard_enhancement_unknown: INTEGER = 0
	Keyboard_enhancement_supported: INTEGER = 1
	Keyboard_enhancement_unsupported: INTEGER = 2
			-- Values of `keyboard_enhancement_support`

	is_mouse_capture_requested: BOOLEAN
			-- Should `run` enable mouse capture reporting?

	set_mouse_capture (a_enabled: BOOLEAN)
			-- Request (or not) mouse capture for the next `run`. Without capture there is no
			-- motion reporting either (`set_mouse_motion`).
		require
			not_while_set_up: not is_terminal_set_up
		do
			is_mouse_capture_requested := a_enabled
			if not a_enabled then
				is_mouse_motion_requested := False
			end
		ensure
			set: is_mouse_capture_requested = a_enabled
			no_motion_without_capture: not a_enabled implies not is_mouse_motion_requested
			motion_kept: a_enabled implies is_mouse_motion_requested = old is_mouse_motion_requested
		end

	is_mouse_motion_requested: BOOLEAN
			-- Should `run` also report motion with no button held (mode 1003), for hover?

	set_mouse_motion (a_enabled: BOOLEAN)
			-- Request (or not) motion reporting with no button held (any-event tracking,
			-- `CSI ? 1003 h`, on top of mouse capture): moves arrive as MOUSE_EVENTs with
			-- `is_move` (crossterm `MouseEventKind::Moved`). Opt-in, because the terminal then
			-- sends an event for every cell the pointer crosses; consecutive moves are merged
			-- while the application falls behind (`set_event_coalescing`). Before `run` it
			-- applies from the setup; while running it is written at once (an application
			-- may turn hover on only on the screens that use it), except while the process
			-- waits for its terminal, when the next setup writes it. Turned off with mouse
			-- capture on every exit path and before a stop, and on again on resume.
		require
			capture_requested: a_enabled implies is_mouse_capture_requested
		do
			is_mouse_motion_requested := a_enabled
			if is_terminal_set_up and not is_waiting_for_terminal and backend.is_mouse_captured
				and a_enabled /= backend.is_mouse_motion_enabled
			then
				if a_enabled then
					terminal.enable_mouse_motion
				else
					terminal.disable_mouse_motion
				end
			end
		ensure
			set: is_mouse_motion_requested = a_enabled
			applied: (is_terminal_set_up and not is_waiting_for_terminal and backend.is_mouse_captured)
				implies backend.is_mouse_motion_enabled = a_enabled
		end

	window_title: detachable STRING_32
			-- Window title shown while `run` has the terminal set up, sanitized
			-- ({WINDOW_TITLE}.sanitized); Void (the default) leaves the terminal's title alone.
			-- Kept by `terminal` alone, so `{TERMINAL}.set_title` sets the same title. Not
			-- named `title`, which applications use for their own (a screen's, a block's).
		do
			Result := terminal.title
		end

	set_window_title (a_title: READABLE_STRING_GENERAL)
			-- Show `a_title`, without its control characters, as the terminal's window title
			-- (crossterm `SetTitle`), from the next frame. Before `run`, or while the process
			-- waits for its terminal (`is_waiting_for_terminal`), nothing is written: the next
			-- setup writes it, once the process owns the terminal (review finding M10). The
			-- terminal's own title is saved first and given back on every exit and while the
			-- process is stopped ({TERMINAL}.set_title, `show_title`, `restore_title`).
		require
			title_attached: a_title /= Void
		do
			terminal.set_title (a_title)
		ensure
			title_set: attached window_title as t and then t.same_string ({WINDOW_TITLE}.sanitized (a_title))
		end

	is_suspend_on_ctrl_z: BOOLEAN
			-- Does `run` suspend the application when Ctrl+Z is pressed, where the platform
			-- supports it (POSIX)? True by default, as in a shell. When False, Ctrl+Z reaches
			-- `process` like any other key; the application can still call `suspend`.

	set_suspend_on_ctrl_z (a_enabled: BOOLEAN)
			-- Suspend (or not) on Ctrl+Z; when not, Ctrl+Z is passed to `process`.
		do
			is_suspend_on_ctrl_z := a_enabled
		ensure
			set: is_suspend_on_ctrl_z = a_enabled
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

feature -- Clipboard read

	clipboard_timeout_ms: INTEGER
			-- Time a read (`read_clipboard`) waits for the terminal's answer before `process`
			-- receives `Status_unavailable`

	Default_clipboard_timeout_ms: INTEGER = 3_000
			-- Default `clipboard_timeout_ms`: long enough for a quick click on a terminal that
			-- asks the user (kitty), short enough for "unavailable" not to feel broken

	Unsent_clipboard_answer_ms: INTEGER = 25
			-- Delay before a read that could not be asked of the terminal (before `run`,
			-- while waiting for the terminal) is answered `Status_unavailable`

	set_clipboard_timeout (a_ms: INTEGER)
			-- Wait `a_ms` milliseconds for each clipboard answer, from the next read on.
		require
			positive_ms: a_ms > 0
		do
			clipboard_timeout_ms := a_ms
		ensure
			set: clipboard_timeout_ms = a_ms
		end

	is_clipboard_read_pending: BOOLEAN
			-- Was a read asked for (`read_clipboard`, `read_selection`) whose answer has not
			-- reached `process` yet? Then a new read is ignored.

	is_clipboard_request_queued: BOOLEAN
			-- Is the pending read's request held by `terminal`, to be written by the next
			-- frame? A reply that comes before then is not its answer (it answers an earlier
			-- request, or one nobody here made) and is dropped as late.

	is_clipboard_request_sent: BOOLEAN
			-- Was the pending read's request written to the terminal, so that its reply ends
			-- it? Only from the frame that writes it on (`is_clipboard_request_queued` until
			-- then). With a driver that reads the clipboard itself
			-- ({CONSOLE_DRIVER}.provides_clipboard_read), from the read on: its answer is
			-- queued at once. False when it was asked while the terminal was not the
			-- application's (before `run`, while waiting for the terminal), or ended by a stop
			-- or the end of `run`: then `Status_unavailable` is its answer, and a reply that
			-- still comes is late.

	is_native_clipboard_answer_queued: BOOLEAN
			-- Is the pending read answered by the driver ({CONSOLE_DRIVER}.provides_clipboard_read),
			-- its answer queued and not yet taken from the queue? Then only that answer ends
			-- the read.
		do
			Result := native_clipboard_answer /= Void
		ensure
			only_when_sent: Result implies is_clipboard_request_sent
		end

	clipboard_read_selection: CHARACTER_8
			-- Selection of the pending read, or of the last one: `c` (`read_clipboard`) or
			-- `p` (`read_selection`); `c` before the first

	clipboard_read_deadline: INTEGER_64
			-- {MONOTONIC_CLOCK}.milliseconds at which the pending read is answered with
			-- `Status_unavailable` if no reply has come

	late_clipboard_replies: INTEGER
			-- Clipboard replies dropped before `process` because no request of a pending read
			-- had been written (a reply after the timeout or a stop, one that came before the
			-- frame that writes the request, or one nobody asked for), or because the reply's
			-- selection is not the read's, since the application was created

	read_clipboard
			-- Ask for the clipboard's text. `process` then receives exactly one
			-- CLIPBOARD_EVENT for it, within `clipboard_timeout_ms`: the terminal's answer,
			-- or `Status_unavailable` when none comes. Ignored while a read is pending. The
			-- request (OSC 52 `?`) goes out with the next frame; a driver that reads the
			-- clipboard itself (Windows) reads it now and queues its answer instead (see the
			-- class note). Asked while the terminal is
			-- not the application's (before `run`, while it waits for its terminal), nothing
			-- is sent, and the answer is `Status_unavailable` at the first loop iteration
			-- `Unsent_clipboard_answer_ms` after the read (so that an application that reads
			-- again on that answer does not keep the loop from sleeping).
			-- Most terminals never answer: see the class note.
		do
			ask_clipboard ({TERMINAL_BACKEND}.Clipboard_selection)
		ensure
			pending: is_clipboard_read_pending
			ignored_while_pending: old is_clipboard_read_pending implies
				(clipboard_read_selection = old clipboard_read_selection
				and clipboard_read_deadline = old clipboard_read_deadline
				and is_clipboard_request_queued = old is_clipboard_request_queued
				and is_clipboard_request_sent = old is_clipboard_request_sent)
			new_read: not old is_clipboard_read_pending implies clipboard_read_selection = {TERMINAL_BACKEND}.Clipboard_selection
		end

	read_selection
			-- Ask for the primary selection's text (X11 terminals), as `read_clipboard` does
			-- for the clipboard. Ignored while a read is pending. Windows has no primary
			-- selection: there the clipboard is read (the answer's selection is `p`).
		do
			ask_clipboard ({TERMINAL_BACKEND}.Primary_selection)
		ensure
			pending: is_clipboard_read_pending
			ignored_while_pending: old is_clipboard_read_pending implies
				(clipboard_read_selection = old clipboard_read_selection
				and clipboard_read_deadline = old clipboard_read_deadline
				and is_clipboard_request_queued = old is_clipboard_request_queued
				and is_clipboard_request_sent = old is_clipboard_request_sent)
			new_read: not old is_clipboard_read_pending implies clipboard_read_selection = {TERMINAL_BACKEND}.Primary_selection
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

	suspend
			-- Suspend the application as Ctrl+Z does in a shell: restore the terminal, stop
			-- the process until the shell continues it (`fg`), then set the terminal up again
			-- and redraw everything. Continued in the background (`bg`), the process sets the
			-- terminal up only once it owns it again (`is_resume_pending`). Call from
			-- `process` while `run` is active. Does nothing where the platform cannot suspend
			-- (Windows), or while the process waits for its terminal: after a stop, or after
			-- starting in the background (nothing is set up to restore).
		do
			if is_running and is_terminal_set_up and not is_waiting_for_terminal
				and backend.driver.supports_suspend_resume
			then
				perform_suspend
			end
		end

	post_event (a_event: EVENT)
			-- Enqueue `a_event` for the main loop (thread-safe).
			-- Worker threads use this to deliver typed results via CUSTOM_EVENT.
		require
			event_attached: a_event /= Void
		do
			event_queue.push (a_event)
		end

	run
			-- Set up the terminal, launch the input thread and run the event loop until `stop`.
			-- The terminal is always restored; an exception is re-raised after restoration.
			-- Started in the background (`hello_tui &`), where the terminal is the shell's, the
			-- loop does all of this only once `fg` gives the process the terminal
			-- (`is_start_pending`); until then it processes events and ticks but neither
			-- reads input nor draws, and quitting meanwhile leaves the terminal alone.
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
			l_wait: INTEGER
		do
			if not event_thread.is_launchable then
				-- A THREAD runs only once: read this run's input on a new one
				event_thread := event_thread.renewed
				event_queue.wipe_out
			end
			input_thread_timed_out := False
			is_running := True
			if backend.driver.is_foreground then
				start_terminal
				terminal.draw (agent draw_frame)
			else
				-- Started in the background: the terminal is the shell's. The Eiffel runtime
				-- ignores SIGTTOU, so a setup now would not stop the process but take the
				-- terminal, and bash would set the raw modes it finds at `fg` back once the
				-- job ends (review finding M10). Wait for `fg` as after a stop (M9); the loop
				-- handles termination requests meanwhile, and nothing is written on exit
				is_start_pending := True
				backend.driver.set_deferring_termination (True)
			end

			from
				l_next_tick := {MONOTONIC_CLOCK}.milliseconds + tick_rate_ms
			until
				not is_running
			loop
				-- Wait for the next event, but never past the next tick deadline
				l_wait := (l_next_tick - {MONOTONIC_CLOCK}.milliseconds).max (0).to_integer_32
				if is_clipboard_read_pending then
					-- Nor past the deadline of a clipboard read, whatever the tick rate
					l_wait := l_wait.min ((clipboard_read_deadline - {MONOTONIC_CLOCK}.milliseconds).max (0).to_integer_32)
				end
				if is_waiting_for_terminal then
					-- `fg` on a job that runs sends no signal: look for it often enough
					l_wait := l_wait.min (Foreground_poll_ms)
				end
				l_event := event_queue.poll_with_timeout (l_wait)
				-- Process what is waiting, but draw after `event_budget_ms` even if more is
				-- waiting: the rest is taken at once by the next iteration's poll
				from
					l_budget_end := {MONOTONIC_CLOCK}.milliseconds + event_budget_ms
				until
					l_event = Void or not is_running
				loop
					dispatch (l_event)
					if {MONOTONIC_CLOCK}.milliseconds >= l_budget_end then
						l_event := Void
					else
						l_event := event_queue.poll
					end
				end

				if is_running and then is_waiting_for_terminal then
					if not backend.driver.is_foreground then
						if is_terminal_set_up then
							-- Stopped from outside and continued in the background: wait for
							-- `fg` as after Ctrl+Z, with nothing reading the shell's terminal
							-- meanwhile
							stop_input_thread
							park_after_external_stop
						end
					elseif is_start_pending then
						-- Started in the background, and `fg` gave us the terminal: set it up
						-- for the first time (M10); the frame is drawn below. A stop and
						-- continue meanwhile had nothing to restore
						backend.driver.clear_resume_request
						is_start_pending := False
						start_terminal
					else
						-- Stopped (Ctrl+Z, `kill -TSTP`), continued, and the terminal is ours. A
						-- job continued in the background (`bg`, `kill -CONT`) waits here for
						-- `fg`: set up meanwhile, it would take the shell's terminal, and bash
						-- would set the raw modes it finds at `fg` back once the job ends (M9)
						resume_after_stop
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

				if is_running and then is_clipboard_read_pending
					and then {MONOTONIC_CLOCK}.milliseconds >= clipboard_read_deadline
				then
					-- No answer in time, or the read was ended by a stop: answer for the terminal
					answer_clipboard_unavailable
				end

				if event_thread.has_failed then
					raise_input_failure
				end

				if backend.driver.has_termination_request then
					-- Restored by `clean_up' below, which then ends the process
					is_running := False
				end

				if is_running and then not is_waiting_for_terminal then
					terminal.draw (agent draw_frame)
					-- A clipboard read's request goes out with this frame: its reply is
					-- awaited from now on
					note_clipboard_request_written
				end
			end
			clean_up
		ensure
			stopped: not is_running
			terminal_restored: not is_terminal_set_up
			no_pending_start: not is_start_pending
			clipboard_read_ended: not is_clipboard_request_sent
			no_clipboard_request_left: not terminal.has_clipboard_request
		rescue
			-- Restore the terminal, then let the exception propagate to the caller
			clean_up
		end

feature {NONE} -- Lifecycle

	dispatch (a_event: EVENT)
			-- Handle `a_event` taken from the queue: suspend on the suspend key, otherwise
			-- `process` it. A resize marks `last_hit_map` out of date until the next frame.
		require
			event_attached: a_event /= Void
		do
			if is_suspend_key (a_event) then
				if is_terminal_set_up and not is_waiting_for_terminal then
					perform_suspend
				end
				-- Otherwise a Ctrl+Z queued behind a stop, while the process waits for its
				-- terminal (`is_waiting_for_terminal`): already done. Or one posted before the
				-- terminal was first set up (`is_start_pending`): nothing to suspend
			elseif attached {CLIPBOARD_EVENT} a_event as l_clip then
				-- The request may have been written by a `draw` other than the loop's
				note_clipboard_request_written
				if is_clipboard_read_pending and is_clipboard_request_sent
					and l_clip.selection = clipboard_read_selection.to_character_32
					and (native_clipboard_answer = Void or else native_clipboard_answer = l_clip)
				then
					-- The answer to the pending read: the read is over before `process` runs,
					-- so that it may read again
					is_clipboard_read_pending := False
					is_clipboard_request_sent := False
					native_clipboard_answer := Void
					process (a_event)
				else
					-- Late (after the timeout or a stop), before this read's request was
					-- written (the answer to an earlier one), for another selection, not the
					-- driver's answer while the driver reads (P2b K4), or not asked for by
					-- `read_clipboard`. OSC 52 replies carry no id: a reply to an earlier read
					-- that comes only after this read's request was written is still taken for
					-- this read's answer
					late_clipboard_replies := late_clipboard_replies + 1
				end
			elseif is_keyboard_reply_late and then (a_event.is_keyboard_flags or a_event.is_device_attributes) then
				-- A late reply to this run's keyboard support query, not the application's:
				-- dropped, up to the DA1 reply that ends it
				if a_event.is_device_attributes then
					is_keyboard_reply_late := False
				end
			else
				if attached {RESIZE_EVENT} a_event then
					-- Until the next frame, the screen may not show the last one
					is_resized_since_draw := True
				end
				process (a_event)
			end
		ensure
			resize_noted: (attached {RESIZE_EVENT} a_event and not is_suspend_key (a_event))
				implies (is_resized_since_draw and not is_hit_map_on_screen)
		end

	is_input_thread_started: BOOLEAN
			-- Has `event_thread` been launched?

	start_terminal
			-- Set the terminal up and read input, for the first time in this `run`.
		require
			running: is_running
			not_set_up: not is_terminal_set_up
			input_stopped: not is_input_thread_started
			not_waiting: not is_start_pending
		do
			-- This run's own answer decides: `set_up_terminal` asks in this first setup only
			keyboard_enhancement_support := Keyboard_enhancement_unknown
			is_keyboard_support_asked := False
			is_keyboard_reply_late := False
			set_up_terminal

			-- The input thread starts after setup: an inline viewport reads the
			-- cursor position report, and the keyboard support query its replies, directly
			-- from the console during setup.
			-- `start` holds the console's input claim until the thread ends, so any other
			-- read (a DSR query) is refused by its precondition meanwhile.
			start_input_thread
		ensure
			set_up: is_terminal_set_up
			input_running: is_input_thread_started
			asked_only_if_requested: not is_keyboard_enhancement_if_supported_requested
				implies keyboard_enhancement_support = Keyboard_enhancement_unknown
			asked_if_requested: is_keyboard_enhancement_if_supported_requested implies is_keyboard_support_asked
		end

	is_keyboard_support_asked: BOOLEAN
			-- Has this `run` asked for `keyboard_enhancement_support`? Asked in the first setup
			-- only: on a resume the input thread holds the console (review finding M4), so
			-- the answer is kept for it.

	is_keyboard_reply_late: BOOLEAN
			-- Did this run's keyboard support query end before the DA1 reply came? Then the
			-- replies it waited for may still come, to the input thread: `dispatch` drops
			-- them instead of passing them to `process`, up to and including the DA1 reply.

	ask_keyboard_enhancement_support
			-- Set `keyboard_enhancement_support` from the terminal's answer to
			-- {ANSI_TERMINAL_BACKEND}.query_keyboard_enhancement. A driver that builds the
			-- enhanced key events itself ({CONSOLE_DRIVER}.provides_keyboard_enhancement:
			-- Win32) supports them whatever the terminal answers, so then nothing is asked.
		require
			set_up: is_terminal_set_up
			input_stopped: not is_input_thread_started
			input_not_in_use: not backend.is_input_in_use
		do
			if backend.driver.provides_keyboard_enhancement then
				keyboard_enhancement_support := Keyboard_enhancement_supported
			else
				if backend.query_keyboard_enhancement /= Void then
					keyboard_enhancement_support := Keyboard_enhancement_supported
				elseif backend.is_keyboard_query_answered then
					keyboard_enhancement_support := Keyboard_enhancement_unsupported
				else
					keyboard_enhancement_support := Keyboard_enhancement_unknown
				end
				is_keyboard_reply_late := not backend.is_keyboard_query_fenced
				-- Keys typed while the query read the console are not lost: they come first
				across backend.keyboard_query_other_events as e loop
					if not event_queue.is_full then
						event_queue.push (e)
					end
				end
			end
		end

	set_up_terminal
			-- Enter raw mode and prepare the screen for the viewport kind.
		do
			-- Set first, so that a failure half-way through still gets restored
			is_terminal_set_up := True
			-- From now on the loop, not the handler, restores the terminal on a termination request
			backend.driver.set_deferring_termination (True)
			-- Nothing of a previous run is on screen any more
			terminal.forget_shown_frame
			terminal.enter_raw_mode
			if terminal.viewport.is_fullscreen then
				terminal.enter_alternate_screen
				terminal.clear_screen
			elseif terminal.viewport.is_inline then
				terminal.setup_inline_viewport
			end
			if is_keyboard_enhancement_if_supported_requested and not is_keyboard_support_asked then
				-- Once per run, in its first setup, so that the flags are pushed at the same
				-- point of the setup as on a resume, which uses this answer
				is_keyboard_support_asked := True
				ask_keyboard_enhancement_support
			end
			if is_keyboard_enhancement_requested
				or (is_keyboard_enhancement_if_supported_requested and is_keyboard_enhancement_supported)
			then
				-- After entering the alternate screen: Kitty keeps one flag stack per screen
				backend.enable_keyboard_enhancement
			end
			if is_mouse_capture_requested then
				terminal.enable_mouse_capture
				if is_mouse_motion_requested then
					terminal.enable_mouse_motion
				end
			end
			terminal.hide_cursor
			-- Saves the terminal's own title first, also after a stop, which gave it back,
			-- then writes the title (if any), whoever set it and whenever
			terminal.show_title
		end

	clean_up
			-- Stop the input thread and restore the terminal. Safe to call more than once;
			-- never raises, so it cannot mask the exception that triggered it.
		local
			l_failed: BOOLEAN
		do
			is_running := False
			-- A pending resume has nothing to restore: the terminal was restored before the stop.
			-- Nor has a pending start: the terminal was never set up
			is_resume_pending := False
			is_start_pending := False
			-- Nothing more is asked or answered in this run: a pending read is answered at the
			-- start of the next one
			end_clipboard_request
			if not l_failed then
				if is_input_thread_started then
					is_input_thread_started := False
					event_thread.stop
					-- If the thread does not stop in time, the terminal is restored all the same
					-- (leaving it raw would be worse); the thread keeps its input claim
					input_thread_timed_out := not event_thread.join_with_timeout (Join_timeout_ms)
				end
				if is_terminal_set_up and then backend.driver.has_resume_request
					and then not backend.driver.is_foreground
				then
					-- Stopped from outside and continued in the background before the loop
					-- noticed: the handler restored the terminal, which is the shell's now
					is_terminal_set_up := False
				end
				if is_terminal_set_up then
					is_terminal_set_up := False
					restore_terminal
				end
			end
			-- Outside the guard above, so that a failed restore still stops the
			-- application's workers; after it, so that a slow worker does not keep the
			-- screen raw. Never raises
			end_background_work
			backend.driver.set_deferring_termination (False)
			if backend.driver.has_termination_request then
				-- A termination request came in while the terminal was set up: it is restored
				-- now, so let the request take its course (the platform drivers do not return)
				backend.driver.finish_termination
			end
		ensure
			stopped: not is_running
			terminal_restored: not is_terminal_set_up
			no_pending_resume: not is_resume_pending
			no_pending_start: not is_start_pending
			input_thread_stopped_or_reported: is_input_thread_available or input_thread_timed_out
			not_deferring: not backend.driver.is_deferring_termination
			clipboard_read_ended: not is_clipboard_request_sent
			no_clipboard_request_left: not terminal.has_clipboard_request
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
				-- Motion reporting (mode 1003) included
				terminal.disable_mouse_capture
			end
			if terminal.viewport.is_fullscreen then
				terminal.reset_cursor_shape
				terminal.show_cursor
				terminal.leave_alternate_screen
			else
				if terminal.viewport.is_inline then
					terminal.restore_inline_viewport
				end
				terminal.reset_cursor_shape
				terminal.show_cursor
			end
			-- The terminal's own title back, if `set_up_terminal` saved it
			terminal.restore_title
			-- Disables mouse/paste/focus reporting, flushes, then restores the original modes
			terminal.leave_raw_mode
		end

	draw_frame (a_frame: FRAME)
			-- Render `a_frame` with `render`, then keep its hit regions for `hit_test`.
		do
			render (a_frame)
			last_hit_map := a_frame.hit_map
			is_resized_since_draw := False
		ensure
			hit_map_kept: last_hit_map = a_frame.hit_map
			resize_seen: not is_resized_since_draw
		end

	is_suspend_key (a_event: EVENT): BOOLEAN
			-- Is `a_event` Ctrl+Z, with `is_suspend_on_ctrl_z`, on a platform that can suspend?
		do
			if is_suspend_on_ctrl_z and then backend.driver.supports_suspend_resume
				and then attached {KEY_EVENT} a_event as k and then k.is_press
			then
				Result := k.modifiers.is_control and then k.code.is_char
					and then (k.code.character = 'z' or k.code.character = 'Z')
			end
		end

	start_input_thread
			-- Start reading input, on a new thread if the current one has already run.
		require
			not_started: not is_input_thread_started
		do
			if not event_thread.is_launchable then
				event_thread := event_thread.renewed
			end
			event_thread.start
			is_input_thread_started := True
		ensure
			started: is_input_thread_started
		end

	stop_input_thread
			-- Stop the input thread and wait for it, so that the console is free for a
			-- setup that reads it (the DSR query of an inline viewport). Raise if it does not
			-- stop within `Join_timeout_ms`: it would race the next reader for the console.
		require
			started: is_input_thread_started
		local
			l_failure: DEVELOPER_EXCEPTION
		do
			event_thread.stop
			if event_thread.join_with_timeout (Join_timeout_ms) then
				is_input_thread_started := False
			else
				-- `clean_up` reports it: the thread is still alive and holds the console
				is_input_thread_started := False
				input_thread_timed_out := True
				create l_failure
				l_failure.set_description ("The input thread did not stop in time to suspend")
				l_failure.raise
			end
		ensure
			stopped: not is_input_thread_started
			console_free: not backend.is_input_in_use
		end

	perform_suspend
			-- Leave the TUI screen, stop the process (Ctrl+Z / SIGTSTP), then re-enter it.
			-- The input thread is stopped first: nothing reads the console while it is in
			-- cooked mode, and `resume_terminal` can query the cursor for an inline viewport.
		require
			supports: backend.driver.supports_suspend_resume
			set_up: is_terminal_set_up
		local
			l_paste, l_focus: BOOLEAN
		do
			stop_input_thread
			-- The terminal may answer a pending clipboard read into the shell: end it now
			-- (the loop answers `Status_unavailable`), and send no request not written yet
			end_clipboard_request
			-- `leave_raw_mode` turns these off: remember them for the resume
			l_paste := backend.is_bracketed_paste_enabled
			l_focus := backend.is_focus_change_enabled
			is_terminal_set_up := False
			restore_terminal
			-- Returns once continued; the SIGCONT that ends this stop is not a new request
			backend.driver.suspend_process
			if backend.driver.is_foreground then
				resume_terminal (l_paste, l_focus)
			else
				-- Continued in the background (`bg`, `kill -CONT`): the terminal is the
				-- shell's. The loop sets it up once `fg` gives it back (review finding M9)
				resume_paste := l_paste
				resume_focus := l_focus
				is_resume_pending := True
			end
		ensure
			set_up_or_pending: is_terminal_set_up /= is_resume_pending
			input_running_unless_pending: is_input_thread_started /= is_resume_pending
		end

	resume_paste, resume_focus: BOOLEAN
			-- Were bracketed paste and focus reporting on before the stop that left
			-- `is_resume_pending`?

	park_after_external_stop
			-- After SIGTSTP from outside, the process was continued in the background: the
			-- signal handler restored the terminal, which is the shell's now. Record it as
			-- restored without writing to it, so that nothing (quitting, a termination
			-- request, `suspend`) touches the shell's terminal, and wait for `fg` as after a
			-- Ctrl+Z continued in the background.
		require
			set_up: is_terminal_set_up
			input_stopped: not is_input_thread_started
		do
			resume_paste := backend.is_bracketed_paste_enabled
			resume_focus := backend.is_focus_change_enabled
			backend.driver.clear_resume_request
			-- Stopped from outside: a pending clipboard read ends as after Ctrl+Z
			end_clipboard_request
			is_terminal_set_up := False
			is_resume_pending := True
		ensure
			restored: not is_terminal_set_up
			pending: is_resume_pending
		end

	resume_after_stop
			-- Set the terminal up again after a stop, now that the process owns it. After
			-- Ctrl+Z (`is_resume_pending`), as `perform_suspend` does. After SIGTSTP from
			-- outside, the signal handler restored the tty (escape resets and cooked mode) but
			-- the Eiffel side still records the modes as on, so they are re-enabled as recorded.
		require
			running: is_running
		local
			l_paste, l_focus: BOOLEAN
		do
			backend.driver.clear_resume_request
			if is_resume_pending then
				is_resume_pending := False
				resume_terminal (resume_paste, resume_focus)
			elseif is_terminal_set_up then
				-- Stopped from outside and continued in the foreground: a pending clipboard
				-- read ends as after Ctrl+Z
				end_clipboard_request
				l_paste := backend.is_bracketed_paste_enabled
				l_focus := backend.is_focus_change_enabled
				stop_input_thread
				resume_terminal (l_paste, l_focus)
			end
		ensure
			not_pending: not is_resume_pending
		end

	resume_terminal (a_paste, a_focus: BOOLEAN)
			-- Set the terminal up as `run` does, re-enable bracketed paste (`a_paste`) and
			-- focus reporting (`a_focus`) if they were on, force a full redraw, and read input
			-- on a new thread. A fullscreen viewport is cleared; an inline one is placed again
			-- at the cursor (the shell has printed below the old one meanwhile). The first
			-- frame writes its cursor shape again ({TERMINAL}.forget_shown_frame), and the
			-- `window_title`, popped before the stop, is pushed and set again.
		require
			input_stopped: not is_input_thread_started
		do
			set_up_terminal
			if a_paste then
				terminal.enable_bracketed_paste
			end
			if a_focus then
				terminal.enable_focus_change
			end
			terminal.force_full_redraw
			start_input_thread
		ensure
			set_up: is_terminal_set_up
			input_running: is_input_thread_started
			paste_restored: a_paste implies backend.is_bracketed_paste_enabled
			focus_restored: a_focus implies backend.is_focus_change_enabled
		end

	ask_clipboard (a_selection: CHARACTER_8)
			-- Start a read of `a_selection` unless one is pending (see `read_clipboard`).
		require
			valid_selection: {ANSI_TERMINAL_BACKEND}.is_valid_selection (a_selection)
		do
			if not is_clipboard_read_pending then
				is_clipboard_read_pending := True
				clipboard_read_selection := a_selection
				is_clipboard_request_sent := False
				if is_running and is_terminal_set_up and not is_waiting_for_terminal then
					clipboard_read_deadline := {MONOTONIC_CLOCK}.milliseconds + clipboard_timeout_ms
					send_clipboard_request (a_selection)
				else
					-- The terminal is not the application's (M9 / M10): ask nothing, answer
					-- `Status_unavailable` a little later, not at once: an application that
					-- reads again on that answer would otherwise keep the loop from sleeping
					clipboard_read_deadline := {MONOTONIC_CLOCK}.milliseconds + Unsent_clipboard_answer_ms
					is_clipboard_request_queued := False
				end
			end
		ensure
			pending: is_clipboard_read_pending
			not_sent_yet: (not old is_clipboard_read_pending and not is_native_clipboard_answer_queued)
				implies not is_clipboard_request_sent
		end

	note_clipboard_request_written
			-- If the pending read's request was held by `terminal` and a frame has written it
			-- since, await its reply from now on.
		do
			if is_clipboard_request_queued and not terminal.has_clipboard_request then
				is_clipboard_request_queued := False
				is_clipboard_request_sent := True
			end
		ensure
			sent_when_written: (old is_clipboard_request_queued and not terminal.has_clipboard_request)
				implies is_clipboard_request_sent
		end

	send_clipboard_request (a_selection: CHARACTER_8)
			-- Ask the clipboard provider for `a_selection` for the pending read. The terminal,
			-- by OSC 52 with the next frame: the request is queued, and sent once a frame has
			-- written it (`note_clipboard_request_written`). Or a driver that reads the
			-- clipboard itself ({CONSOLE_DRIVER}.provides_clipboard_read, Windows, P2b K4):
			-- read now, the answer pushed to `event_queue` (`post_event`), where it takes the
			-- same path as the terminal's reply (`dispatch`); the request counts as sent, and
			-- the deadline starts after the read, which may wait for another program to free
			-- the clipboard.
		require
			valid_selection: {ANSI_TERMINAL_BACKEND}.is_valid_selection (a_selection)
			pending: is_clipboard_read_pending
			not_asked_yet: not is_clipboard_request_queued and not is_clipboard_request_sent
		local
			l_answer: CLIPBOARD_EVENT
		do
			if backend.driver.provides_clipboard_read then
				l_answer := backend.driver.clipboard_answer (a_selection.to_character_32, event_thread.max_osc_size)
				native_clipboard_answer := l_answer
				is_clipboard_request_sent := True
				clipboard_read_deadline := {MONOTONIC_CLOCK}.milliseconds + clipboard_timeout_ms
				post_event (l_answer)
			else
				if a_selection = {TERMINAL_BACKEND}.Primary_selection then
					terminal.request_selection
				else
					terminal.request_clipboard
				end
				is_clipboard_request_queued := True
			end
		ensure
			asked_once: is_clipboard_request_queued /= is_clipboard_request_sent
			native_answer_queued: is_native_clipboard_answer_queued = backend.driver.provides_clipboard_read
			terminal_asked: not backend.driver.provides_clipboard_read implies terminal.has_clipboard_request
		end

	native_clipboard_answer: detachable CLIPBOARD_EVENT
			-- The driver's answer to the pending read, queued and not yet dispatched (P2b K4)

	end_clipboard_request
			-- End the asking part of a pending read: take back a request not written yet, and
			-- make `Status_unavailable` its answer from the next loop iteration on (a reply
			-- that still comes is late). Never raises.
		do
			terminal.discard_clipboard_requests
			is_clipboard_request_queued := False
			-- A driver's answer still queued is late from now on
			native_clipboard_answer := Void
			if is_clipboard_read_pending then
				is_clipboard_request_sent := False
				clipboard_read_deadline := {MONOTONIC_CLOCK}.milliseconds
			end
		ensure
			not_queued: not is_clipboard_request_queued
			not_sent: not is_clipboard_request_sent
			no_native_answer: not is_native_clipboard_answer_queued
			no_request_left: not terminal.has_clipboard_request
			still_pending: is_clipboard_read_pending = old is_clipboard_read_pending
		end

	answer_clipboard_unavailable
			-- End the pending read and give `process` its `Status_unavailable` answer. The
			-- read is over before `process` runs, so that it may read again.
		require
			pending: is_clipboard_read_pending
		do
			terminal.discard_clipboard_requests
			is_clipboard_read_pending := False
			is_clipboard_request_queued := False
			is_clipboard_request_sent := False
			native_clipboard_answer := Void
			process (create {CLIPBOARD_EVENT}.make (clipboard_read_selection, {CLIPBOARD_EVENT}.Status_unavailable))
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

	Foreground_poll_ms: INTEGER = 100
			-- Longest wait between two looks at `is_foreground` while `is_waiting_for_terminal`

	end_background_work
			-- Call `stop_background_work`, and drop any exception it raises: `clean_up` must
			-- not raise, nor mask the exception that ended `run`.
		require
			not_running: not is_running
		local
			l_failed: BOOLEAN
		do
			if not l_failed then
				stop_background_work
			end
		rescue
			l_failed := True
			retry
		end

feature {NONE} -- Background work

	stop_background_work
			-- Stop the threads the application started (workers that `post_event`), and wait
			-- for them, so that none is left running, or posting to the stopped loop, once
			-- `run` has returned. Nothing by default.
			-- Called once each time `run` ends, on every exit path (`stop`, an exception, a
			-- termination request): after the input thread has stopped and the terminal is
			-- restored, and before a termination request ends the process. A redefinition
			-- asks its workers to stop (a flag they read, behind a MUTEX), then joins each
			-- with a timeout ({THREAD}.join_with_timeout, as `clean_up` joins the input
			-- thread) rather than waiting for ever. An exception it raises is dropped.
		require
			not_running: not is_running
		do
		end

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
	last_hit_map_attached: last_hit_map /= Void
	pending_resume_restored: is_resume_pending implies not is_terminal_set_up
	pending_start_not_set_up: is_start_pending implies (not is_terminal_set_up and not is_input_thread_started)
	one_pending: not (is_start_pending and is_resume_pending)
	motion_needs_capture: is_mouse_motion_requested implies is_mouse_capture_requested
	positive_clipboard_timeout: clipboard_timeout_ms > 0
	sent_only_while_pending: is_clipboard_request_sent implies is_clipboard_read_pending
	queued_only_while_pending: is_clipboard_request_queued implies is_clipboard_read_pending
	queued_not_sent: not (is_clipboard_request_queued and is_clipboard_request_sent)
	native_answer_only_while_sent: native_clipboard_answer /= Void implies is_clipboard_request_sent
	valid_clipboard_read_selection: {ANSI_TERMINAL_BACKEND}.is_valid_selection (clipboard_read_selection)

end
