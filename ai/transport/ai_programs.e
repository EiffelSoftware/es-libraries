note
	description: "[
		Programs that the AI integration can start: their path, found in the folders of PATH when their name has
		no folder (on Windows, also with the extensions of PATHEXT), and how to start a Windows batch file
		(`cmd /c').
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	AI_PROGRAMS

feature -- Access

	program_path (a_command: READABLE_STRING_GENERAL): detachable STRING_32
			-- Path of the program `a_command': as is if it has a folder, otherwise found in the folders of PATH
		local
			l_env: EXECUTION_ENVIRONMENT
			l_extensions: ARRAYED_LIST [STRING_32]
			l_separator: CHARACTER_32
			l_name: STRING_32
			p: PATH
		do
			l_name := a_command.to_string_32
			if l_name.has ('/') or l_name.has ('\') then
				Result := l_name
			elseif not l_name.is_empty then
				create l_env
				create l_extensions.make (6)
				l_extensions.extend ({STRING_32} "")
				if {PLATFORM}.is_windows then
					l_separator := ';'
					if attached l_env.item ("PATHEXT") as l_ext then
						l_extensions.append (l_ext.as_lower.split (';'))
					else
						l_extensions.append (({STRING_32} ".com;.exe;.bat;.cmd").split (';'))
					end
				else
					l_separator := ':'
				end
				if attached l_env.item ("PATH") as l_path then
					across l_path.split (l_separator) as d until Result /= Void loop
						if not d.is_empty then
							across l_extensions as e until Result /= Void loop
								create p.make_from_string (d)
								p := p.extended (l_name + e)
								if is_program (p) then
									Result := p.name
								end
							end
						end
					end
				end
			end
		ensure
			instance_free: class
		end

	launch_arguments (a_program: READABLE_STRING_32; a_arguments: ITERABLE [READABLE_STRING_GENERAL]): TUPLE [program: STRING_32; arguments: ARRAYED_LIST [STRING_32]]
			-- Program and arguments to start `a_program' (a path) with `a_arguments': a Windows batch file is run by the command
			-- interpreter (`cmd /c')
		local
			l_arguments: ARRAYED_LIST [STRING_32]
			l_program: STRING_32
		do
			create l_arguments.make (5)
			l_program := a_program.to_string_32
			if {PLATFORM}.is_windows and then (l_program.as_lower.ends_with ({STRING_32} ".cmd") or l_program.as_lower.ends_with ({STRING_32} ".bat")) then
				l_arguments.extend ({STRING_32} "/c")
				l_arguments.extend (l_program)
				if attached (create {EXECUTION_ENVIRONMENT}).item ("ComSpec") as l_comspec then
					l_program := l_comspec.to_string_32
				else
					l_program := {STRING_32} "cmd.exe"
				end
			end
			across a_arguments as a loop
				l_arguments.extend (a.to_string_32)
			end
			Result := [l_program, l_arguments]
		ensure
			instance_free: class
		end

	is_program (p: PATH): BOOLEAN
			-- Is `p' a file that can be run?
		local
			f: RAW_FILE
		do
			create f.make_with_path (p)
			Result := f.exists and then not f.is_directory and then ({PLATFORM}.is_windows or else f.is_executable)
		ensure
			instance_free: class
		end

	Null_device: STRING_32
			-- File reading nothing, given as input to a program that must not wait for one
		do
			if {PLATFORM}.is_windows then
				Result := {STRING_32} "NUL"
			else
				Result := {STRING_32} "/dev/null"
			end
		ensure
			instance_free: class
		end

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
