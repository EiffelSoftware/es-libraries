note
	description: "[
		Transport of an MCP server started as a program (stdio): the client writes each message on
		its standard input, as one line of JSON, and reads its messages from its standard output,
		one per line; its standard error is its log.

		The output and the error are read by two threads, which keep the lines received
		(`take_messages', `take_log_lines') and call `Message_notification' after each one, so that
		a user interface waiting for them can wake up at once.

		The program is looked for in the folders of PATH when its name has no folder (and, on
		Windows, with the extensions of PATHEXT); a Windows batch file (`npx.cmd') is run by
		`cmd /c'.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	AI_MCP_STDIO_TRANSPORT

create
	make

feature {NONE} -- Initialization

	make (a_definition: AI_MCP_SERVER_DEFINITION)
			-- Transport of the server `a_definition' (not started).
		require
			stdio: a_definition.is_stdio
		do
			definition := a_definition
			create mutex.make
			create messages.make (4)
			create log_lines.make (4)
		ensure
			definition_set: definition = a_definition
			not_started: not is_started
		end

feature -- Access

	definition: AI_MCP_SERVER_DEFINITION
			-- Server

	last_error: detachable STRING_32
			-- Why the server could not be started, if so

	Message_notification: CELL [detachable PROCEDURE]
			-- Action called, in a thread of a transport, when a message or a line of log arrives (if set).
			-- It must be safe to call from any thread.
		once ("PROCESS")
			create Result.put (Void)
		ensure
			instance_free: class
		end

feature -- Status report

	is_started: BOOLEAN
			-- Was the program launched?

	is_running: BOOLEAN
			-- Is the program running (its output not closed)?
		do
			mutex.lock
			Result := is_started and not is_output_closed
			mutex.unlock
		end

feature -- Basic operations

	start
			-- Launch the program of `definition'; set `last_error' if it cannot be.
		require
			not_started: not is_started
		local
			l_process: BASE_PROCESS
			l_program: detachable STRING_32
			l_arguments: ARRAYED_LIST [STRING_32]
			l_environment: HASH_TABLE [STRING_32, STRING_32]
			l_env: EXECUTION_ENVIRONMENT
			l_output, l_error: WORKER_THREAD
		do
			last_error := Void
			l_program := program_path (definition.command)
			if not attached l_program then
				last_error := {STRING_32} "Program not found: " + definition.command
			else
				create l_arguments.make (definition.arguments.count + 2)
				if {PLATFORM}.is_windows and then (l_program.as_lower.ends_with ({STRING_32} ".cmd") or l_program.as_lower.ends_with ({STRING_32} ".bat")) then
						-- (A batch file is run by the command interpreter.)
					l_arguments.extend ({STRING_32} "/c")
					l_arguments.extend (l_program)
					if attached (create {EXECUTION_ENVIRONMENT}).item ("ComSpec") as l_comspec then
						l_program := l_comspec.to_string_32
					else
						l_program := {STRING_32} "cmd.exe"
					end
				end
				l_arguments.append (definition.arguments)
				l_process := (create {BASE_PROCESS_FACTORY}).process_launcher (l_program, l_arguments, definition.working_directory)
				if not definition.environment.is_empty then
						-- (The variables of the client, and those of the server.)
					create l_env
					create l_environment.make (50)
					across l_env.starting_environment as v loop
						l_environment.force (v, @v.key)
					end
					across definition.environment as v loop
						l_environment.force (v, @v.key.to_string_32)
					end
					l_process.set_environment_variable_table (l_environment)
				end
				l_process.set_hidden (True)
				l_process.redirect_input_to_stream
				l_process.redirect_output_to_stream
				l_process.redirect_error_to_stream
				l_process.launch
				if l_process.launched then
					process := l_process
					is_started := True
					create l_output.make (agent read_output (l_process))
					create l_error.make (agent read_error (l_process))
					l_output.launch
					l_error.launch
				else
					last_error := {STRING_32} "Cannot start " + l_program
				end
			end
		ensure
			started_or_error: is_started = (last_error = Void)
		end

	send (a_message: READABLE_STRING_8)
			-- Write `a_message' (one line of JSON, UTF-8) to the server.
		require
			one_line: not a_message.has ('%N')
		local
			retried: BOOLEAN
		do
			if not retried and then attached process as p and then is_running then
				p.put_string (a_message + "%N")
			end
		rescue
			retried := True
			retry
		end

	take_messages: ARRAYED_LIST [STRING_8]
			-- Messages received since the last call (lines of JSON, UTF-8)
		do
			mutex.lock
			Result := messages
			create messages.make (4)
			mutex.unlock
		end

	take_log_lines: ARRAYED_LIST [STRING_32]
			-- Lines written by the server to its error since the last call
		do
			mutex.lock
			Result := log_lines
			create log_lines.make (4)
			mutex.unlock
		end

	stop
			-- Stop the program, if running.
		local
			retried: BOOLEAN
		do
			if not retried and then attached process as p and then p.launched then
				if not p.has_exited and not p.force_terminated then
					p.terminate_tree
				end
				p.wait_for_exit_with_timeout (2000)
			end
			mutex.lock
			is_output_closed := True
			mutex.unlock
		rescue
			retried := True
			retry
		end

feature {NONE} -- Implementation

	process: detachable BASE_PROCESS
			-- Program of the server, once started

	mutex: MUTEX
			-- Protection of the lines received

	messages: ARRAYED_LIST [STRING_8]
			-- Messages received, not taken yet

	log_lines: ARRAYED_LIST [STRING_32]
			-- Lines of log received, not taken yet

	is_output_closed: BOOLEAN
			-- Did the output of the program end?

	Buffer_size: INTEGER = 8192
			-- Bytes read at once

	Max_line_size: INTEGER = 50_000_000
			-- Largest message kept (bytes)

	read_output (p: BASE_PROCESS)
			-- Read the messages of `p' until its output ends (in a thread).
		local
			l_buffer: SPECIAL [NATURAL_8]
			l_line: STRING_8
			retried: BOOLEAN
		do
			if not retried then
				create l_line.make (1024)
				from
					create l_buffer.make_filled (0, Buffer_size)
					p.read_output_to_special (l_buffer)
				until
					l_buffer.count = 0 or p.has_output_stream_closed or p.has_output_stream_error
				loop
					add_bytes (l_buffer, l_line, False)
					l_buffer := l_buffer.aliased_resized_area_with_default (0, Buffer_size)
					p.read_output_to_special (l_buffer)
				end
				if l_buffer.count > 0 then
					add_bytes (l_buffer, l_line, False)
				end
			end
			mutex.lock
			if attached l_line and then not l_line.is_empty then
				messages.extend (l_line)
			end
			is_output_closed := True
			mutex.unlock
			notify
		rescue
			retried := True
			retry
		end

	read_error (p: BASE_PROCESS)
			-- Read the log of `p' until its error ends (in a thread).
		local
			l_buffer: SPECIAL [NATURAL_8]
			l_line: STRING_8
			retried: BOOLEAN
		do
			if not retried then
				create l_line.make (256)
				from
					create l_buffer.make_filled (0, Buffer_size)
					p.read_error_to_special (l_buffer)
				until
					l_buffer.count = 0 or p.has_error_stream_closed or p.has_error_stream_error
				loop
					add_bytes (l_buffer, l_line, True)
					l_buffer := l_buffer.aliased_resized_area_with_default (0, Buffer_size)
					p.read_error_to_special (l_buffer)
				end
				if l_buffer.count > 0 then
					add_bytes (l_buffer, l_line, True)
				end
				if not l_line.is_empty then
					mutex.lock
					log_lines.extend ({UTF_CONVERTER}.utf_8_string_8_to_string_32 (l_line))
					mutex.unlock
					notify
				end
			end
		rescue
			retried := True
			retry
		end

	add_bytes (a_buffer: SPECIAL [NATURAL_8]; a_line: STRING_8; a_is_log: BOOLEAN)
			-- Add the bytes of `a_buffer' to `a_line', keeping each line completed (as a message, or as a line of log
			-- if `a_is_log') and starting a new one.
		local
			i: INTEGER
			c: CHARACTER_8
		do
			from
				i := 0
			until
				i >= a_buffer.count
			loop
				c := a_buffer [i].to_character_8
				if c = '%N' then
					if not a_line.is_empty and then a_line [a_line.count] = '%R' then
						a_line.remove_tail (1)
					end
					if not a_line.is_empty then
						mutex.lock
						if a_is_log then
							log_lines.extend ({UTF_CONVERTER}.utf_8_string_8_to_string_32 (a_line))
						else
							messages.extend (a_line.twin)
						end
						mutex.unlock
						notify
					end
					a_line.wipe_out
				elseif a_line.count < Max_line_size then
					a_line.append_character (c)
				end
				i := i + 1
			end
		end

	notify
			-- Call `Message_notification', if set (its failures are ignored).
		local
			retried: BOOLEAN
		do
			if not retried and then attached Message_notification.item as a then
				a.call (Void)
			end
		rescue
			retried := True
			retry
		end

	program_path (a_command: STRING_32): detachable STRING_32
			-- Path of the program `a_command': as is if it has a folder, otherwise found in the folders of PATH
		local
			l_env: EXECUTION_ENVIRONMENT
			l_extensions: ARRAYED_LIST [STRING_32]
			l_separator: CHARACTER_32
			p: PATH
		do
			if a_command.has ('/') or a_command.has ('\') then
				Result := a_command
			elseif not a_command.is_empty then
				create l_env
				if {PLATFORM}.is_windows then
					l_separator := ';'
					create l_extensions.make (6)
					l_extensions.extend ({STRING_32} "")
					if attached l_env.item ("PATHEXT") as l_ext then
						l_extensions.append (l_ext.as_lower.split (';'))
					else
						l_extensions.append (({STRING_32} ".com;.exe;.bat;.cmd").split (';'))
					end
				else
					l_separator := ':'
					create l_extensions.make (1)
					l_extensions.extend ({STRING_32} "")
				end
				if attached l_env.item ("PATH") as l_path then
					across l_path.split (l_separator) as d until Result /= Void loop
						if not d.is_empty then
							across l_extensions as e until Result /= Void loop
								create p.make_from_string (d)
								p := p.extended (a_command + e)
								if is_program (p) then
									Result := p.name
								end
							end
						end
					end
				end
			end
		end

	is_program (p: PATH): BOOLEAN
			-- Is `p' a file that can be run?
		local
			f: RAW_FILE
		do
			create f.make_with_path (p)
			Result := f.exists and then not f.is_directory and then ({PLATFORM}.is_windows or else f.is_executable)
		end

invariant
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
