note
	description: "[
		A program run for an AI model (tool run_command): started directly with its arguments, without a
		shell, in a folder, with nothing on its input (the null device). Its output and error are read by
		two threads into one text (`output'), cut after `max_output' bytes; a third thread waits for its end
		and sets `exit_code'. Nothing here waits: the user interface calls `poll', which stops the program
		(and its children) when it runs longer than `timeout' seconds; `stop' stops it at once.
		{AI_REQUEST_JOB}.Finished_notification is called, in a thread, when the program ends.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	AI_COMMAND_JOB

create
	make

feature {NONE} -- Initialization

	make (a_program: READABLE_STRING_GENERAL; a_arguments: ITERABLE [READABLE_STRING_GENERAL]; a_folder: detachable READABLE_STRING_GENERAL; a_timeout, a_max_output: INTEGER)
			-- Job running `a_program' with `a_arguments' in `a_folder' (Void: the current folder), stopped after `a_timeout'
			-- seconds, keeping at most `a_max_output' bytes of output.
		require
			a_program_not_empty: not a_program.is_empty
			positive_timeout: a_timeout > 0
			positive_max_output: a_max_output > 0
		do
			program := a_program.to_string_32
			create arguments.make (5)
			across a_arguments as a loop
				arguments.extend (a.to_string_32)
			end
			if attached a_folder then
				folder := a_folder.to_string_32
			end
			timeout := a_timeout
			max_output := a_max_output
			create bytes.make (1024)
			create mutex.make
		ensure
			not_started: not is_started
		end

feature -- Access

	program: STRING_32
			-- Program run (its name, or its path)

	arguments: ARRAYED_LIST [STRING_32]
			-- Arguments of `program'

	folder: detachable STRING_32
			-- Folder in which `program' runs

	timeout: INTEGER
			-- Seconds the program may run

	max_output: INTEGER
			-- Most bytes of output kept

	exit_code: INTEGER
			-- Exit code of the program, once finished (-1 if unknown)

	last_error: detachable STRING_32
			-- Why the program could not start, if so

	output: STRING_32
			-- Output and error of the program so far (UTF-8 decoded)
		local
			l_bytes: STRING_8
		do
			mutex.lock
			l_bytes := bytes.twin
			mutex.unlock
			if {UTF_CONVERTER}.is_valid_utf_8_string_8 (l_bytes) then
				Result := {UTF_CONVERTER}.utf_8_string_8_to_string_32 (l_bytes)
			else
				Result := l_bytes.to_string_32
			end
			Result.replace_substring_all ({STRING_32} "%R%N", {STRING_32} "%N")
		end

	dropped_count: INTEGER
			-- Bytes of output dropped (after `max_output')

	seconds: INTEGER
			-- Seconds the program ran (so far)
		do
			if attached started_at as s then
				Result := ((create {DATE_TIME}.make_now_utc).definite_duration (s).fine_seconds_count).truncated_to_integer
			end
		end

feature -- Status report

	is_started: BOOLEAN
			-- Was the program launched?

	is_finished: BOOLEAN
			-- Did the program end (or could it not start)?
		do
			mutex.lock
			Result := internal_is_finished
			mutex.unlock
		end

	is_timed_out: BOOLEAN
			-- Was the program stopped because it ran longer than `timeout'?

	is_stopped: BOOLEAN
			-- Was the program stopped by `stop'?

feature -- Basic operations

	start
			-- Launch the program; set `last_error' (and finish) if it cannot be.
		require
			not_started: not is_started
		local
			l_process: BASE_PROCESS
			l_path: detachable STRING_32
			l_launch: TUPLE [program: STRING_32; arguments: ARRAYED_LIST [STRING_32]]
			l_output, l_error, l_waiter: WORKER_THREAD
			retried: BOOLEAN
		do
			if not retried then
				is_started := True
				exit_code := -1
				started_at := create {DATE_TIME}.make_now_utc
				l_path := {AI_PROGRAMS}.program_path (program)
				if not attached l_path then
					last_error := {STRING_32} "Program not found: " + program
					internal_is_finished := True
				else
					l_launch := {AI_PROGRAMS}.launch_arguments (l_path, arguments)
					l_process := (create {BASE_PROCESS_FACTORY}).process_launcher (l_launch.program, l_launch.arguments, folder)
					l_process.set_hidden (True)
					l_process.enable_launch_in_new_process_group
					l_process.redirect_input_to_file ({AI_PROGRAMS}.Null_device)
					l_process.redirect_output_to_stream
					l_process.redirect_error_to_stream
					l_process.launch
					if l_process.launched then
						process := l_process
						open_streams := 2
						create l_output.make (agent read (l_process, False))
						create l_error.make (agent read (l_process, True))
						create l_waiter.make (agent wait_for_end (l_process))
						l_output.launch
						l_error.launch
						l_waiter.launch
					else
						last_error := {STRING_32} "Cannot start " + program
						internal_is_finished := True
					end
				end
			else
				last_error := {STRING_32} "Cannot start " + program
				internal_is_finished := True
			end
		ensure
			started: is_started
			finished_if_error: last_error /= Void implies is_finished
		rescue
			retried := True
			retry
		end

	poll
			-- Stop the program if it runs longer than `timeout'.
		do
			if is_started and not is_finished and not is_timed_out and seconds >= timeout then
				is_timed_out := True
				kill
			end
		end

	stop
			-- Stop the program now.
		do
			if is_started and not is_finished then
				is_stopped := True
				kill
			end
		end

feature {NONE} -- Implementation

	process: detachable BASE_PROCESS
			-- Program, once launched

	started_at: detachable DATE_TIME
			-- When the program was launched

	bytes: STRING_8
			-- Output received so far, at most `max_output' bytes

	mutex: MUTEX
			-- Protection of `bytes', `dropped_count' and `internal_is_finished'

	internal_is_finished: BOOLEAN
			-- Did the program end?

	open_streams: INTEGER
			-- Output streams of the program not ended yet

	read (p: BASE_PROCESS; a_error: BOOLEAN)
			-- Read the output (or the error if `a_error') of `p' until it ends, in a thread.
		local
			l_buffer: SPECIAL [NATURAL_8]
			l_done: BOOLEAN
			retried: BOOLEAN
		do
			if not retried then
				from
					create l_buffer.make_filled (0, 8192)
				until
					l_done
				loop
					l_buffer := l_buffer.aliased_resized_area_with_default (0, 8192)
					if a_error then
						p.read_error_to_special (l_buffer)
						l_done := p.has_error_stream_closed or p.has_error_stream_error
					else
						p.read_output_to_special (l_buffer)
						l_done := p.has_output_stream_closed or p.has_output_stream_error
					end
					if l_buffer.count > 0 then
						append (l_buffer)
					elseif not l_done then
							-- (Nothing read, but the stream is not closed: read again a bit later.)
						(create {EXECUTION_ENVIRONMENT}).sleep (5_000_000)
					end
				end
			end
			mutex.lock
			open_streams := open_streams - 1
			mutex.unlock
		rescue
			retried := True
			retry
		end

	append (a_buffer: SPECIAL [NATURAL_8])
			-- Keep the bytes of `a_buffer' in `bytes', up to `max_output'.
		local
			i: INTEGER
		do
			mutex.lock
			from i := 0 until i >= a_buffer.count loop
				if bytes.count < max_output then
					bytes.append_character (a_buffer [i].to_character_8)
				else
					dropped_count := dropped_count + 1
				end
				i := i + 1
			end
			mutex.unlock
		end

	wait_for_end (p: BASE_PROCESS)
			-- Wait for the end of the output of `p', then for its end, and set `exit_code' (in a thread).
		local
			retried: BOOLEAN
			l_streams: INTEGER
		do
			if not retried then
					-- (The end of the output first: waiting for the end of the program closes its pipes, and would lose
					-- the output not read yet. A program leaving a child holding its output is stopped by its timeout.)
				from
					mutex.lock
					l_streams := open_streams
					mutex.unlock
				until
					l_streams <= 0
				loop
					(create {EXECUTION_ENVIRONMENT}).sleep (10_000_000)
					mutex.lock
					l_streams := open_streams
					mutex.unlock
				end
				p.wait_for_exit
				exit_code := p.exit_code
			end
			mutex.lock
			internal_is_finished := True
			mutex.unlock
			notify
		rescue
			retried := True
			retry
		end

	kill
			-- Stop the program and its children.
		local
			retried: BOOLEAN
		do
			if not retried and then attached process as p and then p.launched and then not p.force_terminated then
				p.terminate_tree
			end
		rescue
			retried := True
			retry
		end

	notify
			-- Call {AI_REQUEST_JOB}.Finished_notification, if set (its failures are ignored).
		local
			retried: BOOLEAN
		do
			if not retried and then attached {AI_REQUEST_JOB}.Finished_notification.item as a then
				a.call (Void)
			end
		rescue
			retried := True
			retry
		end

invariant
	bytes_bounded: bytes.count <= max_output
	mutex_attached: mutex /= Void

note
	copyright: "Copyright (c) 1984-2026, Eiffel Software"
	license: "GPL version 2 (see http://www.eiffel.com/licensing/gpl.txt)"
	licensing_options: "http://www.eiffel.com/licensing"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"

end
