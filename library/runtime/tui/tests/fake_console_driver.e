note
	description: "[
		Scriptable CONSOLE_DRIVER for headless tests of EVENT_THREAD, ANSI_TERMINAL_BACKEND
		and TUI_APPLICATION. Input bytes are queued with `script', optionally followed by a
		steady stream (`set_steady_input'). Mode calls are counted, and `restore_modes'
		records how much output the watched sink held at that moment, so tests can check
		that escape sequences were written before the console modes were restored.
		Reads happen on the input thread, so all script state is guarded by `lock'.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	FAKE_CONSOLE_DRIVER

inherit
	CONSOLE_DRIVER
		redefine
			default_create
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
			Result := True
		end

	enable_raw_mode: BOOLEAN
		do
			raw_enable_count := raw_enable_count + 1
			is_raw := True
			Result := True
		end

	disable_raw_mode: BOOLEAN
		do
			raw_disable_count := raw_disable_count + 1
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
			if attached watched_sink as l_sink then
				output_at_restore := l_sink.twin
			end
			is_raw := False
			is_mouse_enabled := False
			is_keyboard_enhancement_enabled := False
		end

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
