note
	description: "[
		Scriptable CONSOLE_DRIVER for headless tests of EVENT_THREAD, ANSI_TERMINAL_BACKEND
		and TUI_APPLICATION. Input bytes are queued with `script', optionally followed by a
		steady stream (`set_steady_input'). Mode calls are counted, and `restore_modes'
		records how much output the watched sink held at that moment, so tests can check
		that escape sequences were written before the console modes were restored.
		Reads happen on the input thread, so all script state is guarded by `lock'.
		Clipboard (P2b K4): no clipboard read of its own by default, as on Linux;
		`set_clipboard_provider' makes it read a scripted clipboard as WIN32_CONSOLE_DRIVER
		reads the system's (on the main thread, so not guarded).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	FAKE_CONSOLE_DRIVER

inherit
	CONSOLE_DRIVER
		redefine
			default_create,
			supports_suspend_resume,
			provides_keyboard_enhancement,
			has_resume_request,
			is_foreground,
			clear_resume_request,
			suspend_process,
			writes_output,
			write_output,
			provides_clipboard_read,
			read_clipboard_text
		end

create
	default_create

feature {NONE} -- Initialization

	default_create
			-- Create an 80x24 driver with an empty script.
		do
			create lock.make
			create script_bytes.make (16)
			fake_width := Default_width
			fake_height := Default_height
		end

feature -- Scripting

	script (a_text: READABLE_STRING_8)
			-- Queue the bytes of `a_text` as upcoming input.
		local
			i: INTEGER
		do
			lock.lock
			from
				i := 1
			until
				i > a_text.count
			loop
				script_bytes.extend (a_text.code (i).to_integer_32)
				i := i + 1
			end
			lock.unlock
		end

	set_steady_input (a_byte, a_count, a_interval_ms: INTEGER; a_final: CHARACTER_8)
			-- After the script, deliver `a_byte` `a_count` times, one every `a_interval_ms`,
			-- then deliver `a_final` once.
		require
			valid_byte: a_byte >= 0 and a_byte <= 255
			positive_interval: a_interval_ms > 0
		do
			lock.lock
			steady_byte := a_byte
			steady_remaining := a_count
			steady_interval_ms := a_interval_ms
			steady_final := a_final.code
			has_steady_final := True
			lock.unlock
		end

	set_failing_reads (a_failing: BOOLEAN)
			-- Make every read raise an exception (simulates a broken console).
		do
			lock.lock
			is_failing := a_failing
			lock.unlock
		end

	set_failing_read (a_read: INTEGER)
			-- Make read number `a_read` (counted from the first read) raise an exception, without
			-- consuming a byte (simulates one failing iteration of the input thread).
		require
			positive_read: a_read > 0
		do
			lock.lock
			failing_read := a_read
			lock.unlock
		end

	set_idle_read_ms (a_ms: INTEGER)
			-- Make a read with no input wait `a_ms` milliseconds, even when its timeout is shorter
			-- (simulates a console whose read blocks: a hung terminal, a driver without timeout).
		require
			non_negative: a_ms >= 0
		do
			lock.lock
			idle_read_ms := a_ms
			lock.unlock
		end

	set_size (a_width, a_height: INTEGER)
			-- Simulate a console resize.
		require
			positive: a_width > 0 and a_height > 0
		do
			lock.lock
			fake_width := a_width
			fake_height := a_height
			lock.unlock
		end

	set_request_on_read (a_code, a_read: INTEGER)
			-- On read number `a_read`, act as a platform handler receiving termination request
			-- `a_code` (see `simulate_termination_request`), on the input thread.
		require
			positive_code: a_code > 0
			positive_read: a_read > 0
		do
			lock.lock
			request_on_read_code := a_code
			request_on_read := a_read
			lock.unlock
		end

	watch_sink (a_sink: STRING_32)
			-- Record `a_sink`'s content when `restore_modes` is called.
		do
			watched_sink := a_sink
		end

feature -- Observations

	vt_enable_count: INTEGER
	raw_enable_count: INTEGER
	raw_disable_count: INTEGER
	restore_count: INTEGER

	output_at_restore: detachable STRING_32
			-- Copy of the watched sink when `restore_modes` was last called

	read_count: INTEGER
			-- Number of `read_char_with_timeout` calls so far
		do
			lock.lock
			Result := internal_read_count
			lock.unlock
		end

	resize_poll_count: INTEGER
			-- Number of `poll_resize` calls so far
		do
			lock.lock
			Result := internal_resize_poll_count
			lock.unlock
		end

feature -- Queries

	blocked_read_count: INTEGER
			-- Number of reads that started waiting longer than their timeout (`set_idle_read_ms`)
		do
			lock.lock
			Result := internal_blocked_read_count
			lock.unlock
		end

	console_width: INTEGER
		do
			lock.lock
			Result := fake_width
			lock.unlock
		end

	console_height: INTEGER
		do
			lock.lock
			Result := fake_height
			lock.unlock
		end

	is_raw: BOOLEAN

	is_vt_enabled: BOOLEAN = True

	is_mouse_enabled: BOOLEAN

feature -- Mode Commands

	enable_vt_mode: BOOLEAN
		do
			vt_enable_count := vt_enable_count + 1
			Result := True
		end

	enable_raw_mode: BOOLEAN
		do
			raw_enable_count := raw_enable_count + 1
			log_mark ("raw-on")
			is_raw := True
			Result := True
			if attached watched_sink as l_sink then
				output_at_raw_enable := l_sink.twin
			end
			if attached raw_enable_hook as h then
				h.call
			end
		end

	output_at_raw_enable: detachable STRING_32
			-- Copy of the watched sink when `enable_raw_mode` was last called

	raw_enable_hook: detachable PROCEDURE
			-- Called at the end of every `enable_raw_mode`

	set_raw_enable_hook (a_hook: like raw_enable_hook)
			-- Set `raw_enable_hook` to `a_hook`.
		do
			raw_enable_hook := a_hook
		end

	disable_raw_mode: BOOLEAN
		do
			raw_disable_count := raw_disable_count + 1
			log_mark ("raw-off")
			is_raw := False
			Result := True
		end

	enable_mouse: BOOLEAN
		do
			is_mouse_enabled := True
			Result := True
		end

	disable_mouse: BOOLEAN
		do
			is_mouse_enabled := False
			Result := True
		end

	is_keyboard_enhancement_enabled: BOOLEAN

	provides_keyboard_enhancement: BOOLEAN
			-- As a platform driver that builds the enhanced key events itself (Win32), when set

	set_provides_keyboard_enhancement (a_value: BOOLEAN)
			-- Set `provides_keyboard_enhancement` to `a_value`.
		do
			provides_keyboard_enhancement := a_value
		ensure
			set: provides_keyboard_enhancement = a_value
		end

	enable_keyboard_enhancement
		do
			is_keyboard_enhancement_enabled := True
		end

	disable_keyboard_enhancement
		do
			is_keyboard_enhancement_enabled := False
		end

	restore_modes
		do
			restore_count := restore_count + 1
			log_mark ("restore")
			if attached watched_sink as l_sink then
				output_at_restore := l_sink.twin
			end
			is_raw := False
			is_mouse_enabled := False
			is_keyboard_enhancement_enabled := False
		end

feature -- Mode log

	mode_log: ARRAYED_LIST [TUPLE [name: STRING_8; position: INTEGER]]
			-- Console mode calls ("raw-on", "raw-off", "restore", "stop") and the marks of
			-- `log_mark`, in call order, each with the length of the watched sink at that
			-- moment, so that a test can place them among the escape sequences written
		attribute
			create Result.make (16)
		end

	log_mark (a_name: STRING_8)
			-- Append `a_name` to `mode_log` at the current length of the watched sink.
		require
			name_attached: a_name /= Void
		do
			if attached watched_sink as l_sink then
				mode_log.extend ([a_name, l_sink.count])
			else
				mode_log.extend ([a_name, 0])
			end
		ensure
			one_more: mode_log.count = old mode_log.count + 1
		end

feature -- Suspend / resume

	supports_suspend_resume: BOOLEAN
			-- Off by default, so that Ctrl+Z reaches `process` in the other tests

	set_supports_suspend_resume (a_on: BOOLEAN)
			-- Act as a platform that can (or cannot) suspend.
		do
			supports_suspend_resume := a_on
		ensure
			set: supports_suspend_resume = a_on
		end

	set_suspend_hook (a_hook: like suspend_hook)
			-- Call `a_hook` while "stopped" in `suspend_process` (e.g. to script the
			-- cursor report the resume will ask for).
		do
			suspend_hook := a_hook
		end

	suspend_hook: detachable PROCEDURE

	set_late_continue (a_on: BOOLEAN)
			-- Deliver the continue that ends a `suspend_process` only once it has returned,
			-- at the next `has_resume_request` (as a SIGCONT handler running on another thread
			-- after the stopped thread went on).
		do
			is_late_continue := a_on
		end

	is_late_continue: BOOLEAN

	suspend_process
			-- Record the call and the state of the console, as POSIX would when stopping.
			-- Like the POSIX driver, account in advance for the continue that ends the stop.
		do
			suspend_count := suspend_count + 1
			log_mark ("stop")
			raw_at_suspend := is_raw
			input_claimed_at_suspend := is_input_claimed
			if attached watched_sink as l_sink then
				output_at_suspend := l_sink.twin
			end
			handled_continue_count := continue_count + 1
			if attached suspend_hook as h then
				h.call
			end
			if is_late_continue then
				has_late_continue := True
			else
				continue_count := continue_count + 1
			end
		end

	simulate_external_stop
			-- Act as SIGTSTP from outside followed by SIGCONT: the handler restored the tty
			-- behind the application's back, and a resume is requested. The handler also
			-- pops a pushed window title (P2 T2), counted in `external_title_pop_count`.
		do
			external_stop_count := external_stop_count + 1
			if is_title_pushed then
				external_title_pop_count := external_title_pop_count + 1
				set_title_pushed (False)
			end
			is_raw := False
			if attached watched_sink as l_sink then
				output_at_external_stop := l_sink.twin
			end
			continue_count := continue_count + 1
		end

	output_at_external_stop: detachable STRING_32
			-- Copy of the watched sink when `simulate_external_stop` was last called

	has_resume_request: BOOLEAN
		do
			if has_late_continue then
				has_late_continue := False
				continue_count := continue_count + 1
			end
			Result := continue_count - handled_continue_count > 0
		end

	clear_resume_request
		do
			handled_continue_count := continue_count
		end

	suspend_count: INTEGER
			-- Number of `suspend_process` calls

	external_stop_count: INTEGER
			-- Number of `simulate_external_stop` calls

	external_title_pop_count: INTEGER
			-- Number of window titles popped by `simulate_external_stop`

	raw_at_suspend: BOOLEAN
			-- Was the console raw when `suspend_process` was last called?

	input_claimed_at_suspend: BOOLEAN
			-- Was a reader reading the console when `suspend_process` was last called?

	output_at_suspend: detachable STRING_32
			-- Copy of the watched sink when `suspend_process` was last called

feature -- Clipboard read

	provides_clipboard_read: BOOLEAN
			-- Does the driver read a scripted clipboard (`set_clipboard_provider`)? False by
			-- default, as on Linux.
		do
			Result := is_clipboard_provider
		end

	set_clipboard_provider (a_text: detachable READABLE_STRING_GENERAL; a_status: INTEGER)
			-- Read the clipboard from now on, as the Windows driver does: `a_text` (Void: empty)
			-- with `a_status` (`Status_text`, `Status_unavailable`); a text longer than the
			-- read's cap gives `Status_too_large`.
		require
			valid_status: a_status = {CLIPBOARD_EVENT}.Status_text or a_status = {CLIPBOARD_EVENT}.Status_unavailable
			text_only_with_status_text: a_text /= Void implies a_status = {CLIPBOARD_EVENT}.Status_text
		do
			is_clipboard_provider := True
			if attached a_text then
				clipboard_text := a_text.as_string_32.twin
			else
				clipboard_text := Void
			end
			clipboard_status := a_status
		ensure
			provides: provides_clipboard_read
		end

	set_clipboard_read_delay (a_ms: INTEGER)
			-- Make each clipboard read take `a_ms` milliseconds (another program holding the
			-- clipboard).
		require
			non_negative: a_ms >= 0
		do
			clipboard_read_delay_ms := a_ms
		end

	read_clipboard_text (a_max_count: INTEGER): detachable STRING_32
			-- The scripted clipboard text (see `set_clipboard_provider`).
		do
			clipboard_read_count := clipboard_read_count + 1
			last_clipboard_max_count := a_max_count
			if clipboard_read_delay_ms > 0 then
				(create {EXECUTION_ENVIRONMENT}).sleep (clipboard_read_delay_ms.to_integer_64 * 1_000_000)
			end
			last_clipboard_status := clipboard_status
			if clipboard_status = {CLIPBOARD_EVENT}.Status_text and then attached clipboard_text as t
				and then not t.is_empty
			then
				if t.count > a_max_count then
					last_clipboard_status := {CLIPBOARD_EVENT}.Status_too_large
				else
					Result := t.twin
				end
			end
		end

	clipboard_read_count: INTEGER
			-- Number of `read_clipboard_text` calls

	last_clipboard_max_count: INTEGER
			-- Cap given to the last `read_clipboard_text`

feature {NONE} -- Clipboard implementation

	is_clipboard_provider: BOOLEAN
	clipboard_text: detachable STRING_32
	clipboard_status: INTEGER
	clipboard_read_delay_ms: INTEGER

feature -- Foreground

	set_background_for (a_queries: INTEGER)
			-- Leave the terminal to "the shell" for the next `a_queries` queries of
			-- `is_foreground`, then give it back without a continue, as `fg` does for a job
			-- that `kill -CONT` or `bg` continued in the background.
		require
			positive: a_queries > 0
		do
			background_queries := a_queries
			is_in_background := True
		ensure
			in_background: is_in_background
		end

	is_foreground: BOOLEAN
		do
			if background_queries > 0 then
				background_queries := background_queries - 1
				background_query_count := background_query_count + 1
			else
				if is_in_background then
					is_in_background := False
					raw_enable_count_at_foreground := raw_enable_count
					read_count_at_foreground := read_count
					if attached watched_sink as l_sink then
						output_at_foreground := l_sink.twin
					end
				end
				Result := True
			end
		end

	is_in_background: BOOLEAN
			-- Does "the shell" own the terminal (see `set_background_for`)? Unlike
			-- `is_foreground`, querying this changes nothing.

	background_query_count: INTEGER
			-- Number of `is_foreground` queries answered False

	raw_enable_count_at_foreground: INTEGER
			-- `raw_enable_count` when the terminal was last given back

	output_at_foreground: detachable STRING_32
			-- Copy of the watched sink when the terminal was last given back

	read_count_at_foreground: INTEGER
			-- `read_count` when the terminal was last given back

feature -- Output

	writes_output: BOOLEAN
			-- Does the backend hand its output to `write_output` (see `set_writes_output`)?

	set_writes_output (a_on: BOOLEAN)
			-- Take the backend's output in `write_output` (`a_on`), as the POSIX driver does.
		do
			writes_output := a_on
		ensure
			set: writes_output = a_on
		end

	write_output (a_bytes: STRING_8)
			-- Record `a_bytes` in `written_output`.
		do
			write_output_count := write_output_count + 1
			written_output.append (a_bytes)
		end

	written_output: STRING_8
			-- All bytes passed to `write_output`
		attribute
			create Result.make_empty
		end

	write_output_count: INTEGER
			-- Number of `write_output` calls

feature {NONE} -- Foreground implementation

	background_queries: INTEGER
			-- Number of `is_foreground` queries still to answer False

feature {NONE} -- Suspend / resume implementation

	continue_count, handled_continue_count: INTEGER
			-- Continues received, and accounted for (see POSIX_CONSOLE_DRIVER)

	has_late_continue: BOOLEAN
			-- Is the continue of the last stop still to be delivered?

feature -- Input & Resize

	read_char_with_timeout (a_timeout_ms: INTEGER): INTEGER
		local
			l_wait_ms: INTEGER
			l_failing: BOOLEAN
		do
			lock.lock
			internal_read_count := internal_read_count + 1
			if internal_read_count = request_on_read then
				record_termination_request (request_on_read_code)
			end
			l_failing := is_failing or internal_read_count = failing_read
			if l_failing then
				-- raise below, outside the lock
			elseif not script_bytes.is_empty then
				Result := script_bytes.first
				script_bytes.start
				script_bytes.remove
			elseif steady_remaining > 0 then
				steady_remaining := steady_remaining - 1
				Result := steady_byte
				l_wait_ms := steady_interval_ms
			elseif has_steady_final then
				has_steady_final := False
				Result := steady_final
				l_wait_ms := steady_interval_ms
			else
				Result := -1
				l_wait_ms := a_timeout_ms.max (idle_read_ms)
				if idle_read_ms > a_timeout_ms then
					internal_blocked_read_count := internal_blocked_read_count + 1
				end
			end
			lock.unlock
			if l_failing then
				(create {DEVELOPER_EXCEPTION}).raise
			end
			if l_wait_ms > 0 then
				(create {EXECUTION_ENVIRONMENT}).sleep (l_wait_ms.to_integer_64 * 1_000_000)
			end
		end

	poll_resize (a_cols, a_rows: TYPED_POINTER [INTEGER]): BOOLEAN
		do
			lock.lock
			internal_resize_poll_count := internal_resize_poll_count + 1
			lock.unlock
			Result := False
		end

	install_ctrl_handler
		do
		end

feature -- Termination requests

	is_deferring_termination: BOOLEAN
			-- Are simulated termination requests recorded for the application loop?

	set_deferring_termination (a_on: BOOLEAN)
		do
			lock.lock
			is_deferring_termination := a_on
			lock.unlock
		end

	has_termination_request: BOOLEAN
		do
			lock.lock
			Result := pending_request /= 0
			lock.unlock
		end

	termination_request_code: INTEGER
		do
			lock.lock
			Result := pending_request
			lock.unlock
		end

	discard_termination_request
		do
			lock.lock
			pending_request := 0
			lock.unlock
		end

	finish_termination
			-- Record the call instead of ending the process.
		do
			lock.lock
			finish_count := finish_count + 1
			restore_count_at_finish := restore_count
			if attached watched_sink as l_sink then
				sink_count_at_finish := l_sink.count
			end
			lock.unlock
		end

	simulate_termination_request (a_code: INTEGER)
			-- Act as a platform handler receiving request `a_code`: record it while deferring and
			-- nothing is pending, otherwise handle it at once (counted in `immediate_request_count`).
		require
			positive: a_code > 0
		do
			lock.lock
			record_termination_request (a_code)
			lock.unlock
		end

	finish_count: INTEGER
			-- Number of `finish_termination` calls

	restore_count_at_finish: INTEGER
			-- `restore_count` at the last `finish_termination`

	sink_count_at_finish: INTEGER
			-- Length of the watched output at the last `finish_termination`

	immediate_request_count: INTEGER
			-- Requests handled at once by `simulate_termination_request`

	pending_request: INTEGER
			-- Code of the recorded request, or 0

feature {NONE} -- Implementation

	record_termination_request (a_code: INTEGER)
			-- Record `a_code` while deferring and nothing is pending; otherwise count it as
			-- handled at once. Call with `lock` held.
		do
			if is_deferring_termination and pending_request = 0 then
				pending_request := a_code
			else
				immediate_request_count := immediate_request_count + 1
			end
		end

	failing_read: INTEGER
			-- Read number that raises (0: none)

	request_on_read, request_on_read_code: INTEGER
			-- Read number on which `request_on_read_code` is simulated (0: never)

	lock: MUTEX
	script_bytes: ARRAYED_LIST [INTEGER]
	internal_read_count: INTEGER
	internal_resize_poll_count: INTEGER
	is_failing: BOOLEAN

	idle_read_ms: INTEGER
			-- Minimum wait of a read with no input (see `set_idle_read_ms`)

	internal_blocked_read_count: INTEGER
	fake_width, fake_height: INTEGER
	steady_byte, steady_remaining, steady_interval_ms, steady_final: INTEGER
	has_steady_final: BOOLEAN
	watched_sink: detachable STRING_32

end
