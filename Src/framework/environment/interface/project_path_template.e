note
	description: "[
		Pattern for the project path (location of the EIFGENs folder), for instance
		given with the `-project_path` command line option:
			/tmp/EiffelCOMP/{{system}}-{{target}}-{{platform}}_{{ec_version}}
		Variables:
			{{system}}      name of the system (from the ECF file), e.g. "ec"
			{{target}}      name of the target, e.g. "bench"
			{{platform}}    value of ISE_PLATFORM, e.g. "win64", "linux-x86-64", "macosx-arm64"
			{{os}}          operating system part of the platform, e.g. "windows", "linux", "macosx"
			{{arch}}        architecture part of the platform, e.g. "x86-64", "arm64"
			{{ec_version}}  major.minor version of the compiler, e.g. "26.11"
			{{ec_build}}    major.minor.build version of the compiler, e.g. "26.11.98732"
			{{git_branch}}  current git branch of `git_location` (or of one of its parent folders),
			                with '/' and '\' replaced by '_' (e.g. "ai_v_topic"),
			                or the 8 first characters of the commit id for a detached HEAD
			{{env:NAME}}    value of the environment variable NAME
		A default value, used when the value is empty or undefined, follows ":-":
			{{git_branch:-master}}, {{env:USERNAME:-anonymous}}, {{env:BUILD_ID:-}}
		Spaces around the name are ignored: {{ system }} is the same as {{system}}.
		Any other name, or a "{{" without "}}", makes the pattern invalid (even with a default value),
		and so does an empty or undefined value without default value (see `expand`).
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	PROJECT_PATH_TEMPLATE

create
	make

feature {NONE} -- Initialization

	make (a_template: READABLE_STRING_GENERAL)
			-- Create from the pattern `a_template`.
		do
			create template.make_from_string_general (a_template)
			create unknown_variables.make (0)
			unknown_variables.compare_objects
			create missing_variables.make (0)
			missing_variables.compare_objects
			create expanded_string.make_empty
			create system.make_empty
			create target.make_empty
			create platform.make_empty
			create build.make_empty
			analyze
		ensure
			template_set: template.same_string_general (a_template)
			not_expanded: not is_expanded
		end

feature -- Access

	template: STRING_32
			-- The pattern.

	unknown_variables: ARRAYED_LIST [STRING_32]
			-- Names of the variables of `template` that are not supported.

	system: STRING_32
			-- Value of {{system}}.

	target: STRING_32
			-- Value of {{target}}.

	platform: STRING_32
			-- Value of {{platform}} (ISE_PLATFORM), also used for {{os}} and {{arch}}.

	build: STRING_32
			-- Build number of the compiler, used for {{ec_build}}.

	git_location: detachable PATH
			-- Folder used to find the git branch of {{git_branch}}.

	expanded_string: STRING_32
			-- `template` with the variables replaced by their values, set by `expand`.

	missing_variables: ARRAYED_LIST [STRING_32]
			-- Variables without value nor default value, set by `expand`.

feature -- Variable names

	System_variable: STRING_32 = "system"
	Target_variable: STRING_32 = "target"
	Platform_variable: STRING_32 = "platform"
	Os_variable: STRING_32 = "os"
	Arch_variable: STRING_32 = "arch"
	Ec_version_variable: STRING_32 = "ec_version"
	Ec_build_variable: STRING_32 = "ec_build"
	Git_branch_variable: STRING_32 = "git_branch"

	Environment_prefix: STRING_32 = "env:"
			-- Prefix of the environment variables: {{env:NAME}}.

	Opening_delimiter: STRING_32 = "{{"
	Closing_delimiter: STRING_32 = "}}"
	Default_separator: STRING_32 = ":-"

	supported_variables: ARRAY [STRING_32]
			-- Names of the built-in variables.
		once
			Result := <<System_variable, Target_variable, Platform_variable, Os_variable, Arch_variable, Ec_version_variable, Ec_build_variable, Git_branch_variable>>
			Result.compare_objects
		end

feature -- Status report

	has_variables: BOOLEAN
			-- Does `template` contain variables (or at least an opening delimiter)?

	is_unterminated: BOOLEAN
			-- Does `template` contain an opening delimiter without a closing one?

	is_valid: BOOLEAN
			-- Is `template` syntactically valid, with only supported variables?
		do
			Result := not is_unterminated and unknown_variables.is_empty
		ensure
			definition: Result = (not is_unterminated and unknown_variables.is_empty)
		end

	is_expanded: BOOLEAN
			-- Has `expand` been called (since the last change of a value)?

	has_missing_values: BOOLEAN
			-- Did `expand` find variables without value nor default value?
		require
			is_expanded: is_expanded
		do
			Result := not missing_variables.is_empty
		end

	is_supported_variable (a_name: READABLE_STRING_GENERAL): BOOLEAN
			-- Is `a_name` the name of a supported variable (built-in or environment variable)?
		do
			Result := across supported_variables as v some v.same_string_general (a_name) end
				or else is_environment_variable (a_name)
		end

	is_environment_variable (a_name: READABLE_STRING_GENERAL): BOOLEAN
			-- Is `a_name` of the form "env:NAME"?
		do
			Result := a_name.count > Environment_prefix.count and then
				a_name.head (Environment_prefix.count).same_string (Environment_prefix)
		end

feature -- Element change

	set_system (a_system: READABLE_STRING_GENERAL)
			-- Set `system` to `a_system`.
		do
			create system.make_from_string_general (a_system)
			is_expanded := False
		ensure
			system_set: system.same_string_general (a_system)
			not_expanded: not is_expanded
		end

	set_target (a_target: READABLE_STRING_GENERAL)
			-- Set `target` to `a_target`.
		do
			create target.make_from_string_general (a_target)
			is_expanded := False
		ensure
			target_set: target.same_string_general (a_target)
			not_expanded: not is_expanded
		end

	set_platform (a_platform: READABLE_STRING_GENERAL)
			-- Set `platform` to `a_platform`.
		do
			create platform.make_from_string_general (a_platform)
			is_expanded := False
		ensure
			platform_set: platform.same_string_general (a_platform)
			not_expanded: not is_expanded
		end

	set_build (a_build: READABLE_STRING_GENERAL)
			-- Set `build` to `a_build`.
		do
			create build.make_from_string_general (a_build)
			is_expanded := False
		ensure
			build_set: build.same_string_general (a_build)
			not_expanded: not is_expanded
		end

	set_git_location (a_location: detachable PATH)
			-- Set `git_location` to `a_location`.
		do
			git_location := a_location
			is_expanded := False
		ensure
			git_location_set: git_location = a_location
			not_expanded: not is_expanded
		end

feature -- Basic operations

	expand
			-- Set `expanded_string` to `template` with the variables replaced by their values,
			-- or by their default value when the value is empty or undefined,
			-- and `missing_variables` to the variables without value nor default value.
		require
			is_valid: is_valid
		local
			i, j, n: INTEGER
			l_name: STRING_32
			l_default: detachable STRING_32
			l_value: detachable STRING_32
		do
			from
				create expanded_string.make (template.count)
				missing_variables.wipe_out
				i := 1
				n := template.count
			until
				i > n
			loop
				j := template.substring_index (Opening_delimiter, i)
				if j = 0 then
					expanded_string.append_substring (template, i, n)
					i := n + 1
				else
					expanded_string.append_substring (template, i, j - 1)
					i := template.substring_index (Closing_delimiter, j + Opening_delimiter.count)
					check closed: i > 0 then end
					l_name := variable_name (j, i)
					l_default := default_value (j, i)
					l_value := variable_value (l_name)
					if l_value = Void or else l_value.is_empty then
						l_value := l_default
					end
					if l_value /= Void then
						expanded_string.append (l_value)
					elseif not missing_variables.has (l_name) then
						missing_variables.extend (l_name)
					end
					i := i + Closing_delimiter.count
				end
			variant
				n - i + 1
			end
			is_expanded := True
		ensure
			is_expanded: is_expanded
			same_if_no_variable: not has_variables implies expanded_string.same_string (template)
		end

feature -- Conversion

	error_message: STRING_32
			-- Description of the errors of `template`, or of its expansion.
		require
			has_error: not is_valid or else (is_expanded and then has_missing_values)
		do
			create Result.make_from_string ({STRING_32} "Invalid project path %"")
			Result.append (template)
			Result.append ({STRING_32} "%": ")
			if is_unterminated then
				Result.append ({STRING_32} "missing %"")
				Result.append (Closing_delimiter)
				Result.append ({STRING_32} "%"")
			elseif not unknown_variables.is_empty then
				Result.append ({STRING_32} "unknown variable")
				if unknown_variables.count > 1 then
					Result.append_character ('s')
				end
				append_variable_list (unknown_variables, Result)
			else
				Result.append ({STRING_32} "no value for")
				append_variable_list (missing_variables, Result)
				Result.append ({STRING_32} " (use ")
				Result.append (Opening_delimiter)
				Result.append ({STRING_32} "name")
				Result.append (Default_separator)
				Result.append ({STRING_32} "default")
				Result.append (Closing_delimiter)
				Result.append ({STRING_32} " for a default value)")
			end
			Result.append ({STRING_32} " (supported:")
			across
				supported_variables as v
			loop
				Result.append_character (' ')
				Result.append (Opening_delimiter)
				Result.append (v)
				Result.append (Closing_delimiter)
			end
			Result.append_character (' ')
			Result.append (Opening_delimiter)
			Result.append (Environment_prefix)
			Result.append ({STRING_32} "NAME")
			Result.append (Closing_delimiter)
			Result.append ({STRING_32} ").")
		end

feature -- Platform

	ec_version: STRING_32
			-- Major and minor version of the compiler, e.g. "26.11".
		local
			l_constants: EIFFEL_CONSTANTS
		do
			create l_constants
			create Result.make (5)
			Result.append_string_general (l_constants.two_digit_minimum_major_version)
			Result.append_character ('.')
			Result.append_string_general (l_constants.two_digit_minimum_minor_version)
		end

	platform_os (a_platform: READABLE_STRING_GENERAL): STRING_32
			-- Operating system of the platform `a_platform` (ISE_PLATFORM value):
			-- "windows" for "win64" and "windows", otherwise the part before the first '-'.
		local
			i: INTEGER
		do
			if is_windows_platform_name (a_platform) then
				Result := "windows"
			else
				i := a_platform.index_of ('-', 1)
				if i > 0 then
					create Result.make_from_string_general (a_platform.head (i - 1))
				else
					create Result.make_from_string_general (a_platform)
				end
			end
		end

	platform_arch (a_platform: READABLE_STRING_GENERAL): STRING_32
			-- Architecture of the platform `a_platform` (ISE_PLATFORM value):
			-- "x86-64" for "win64", "x86" for "windows", otherwise the part after the first '-'
			-- (or "unknown" when there is none).
		local
			i: INTEGER
		do
			if a_platform.same_string ("win64") then
				Result := "x86-64"
			elseif a_platform.same_string ("windows") then
				Result := "x86"
			else
				i := a_platform.index_of ('-', 1)
				if i > 0 and i < a_platform.count then
					create Result.make_from_string_general (a_platform.substring (i + 1, a_platform.count))
				else
					Result := "unknown"
				end
			end
		end

feature -- Git

	git_branch (a_location: PATH): detachable STRING_32
			-- Current branch of the git working tree containing `a_location`, if any,
			-- with '/' and '\' replaced by '_', or the 8 first characters of the commit id
			-- for a detached HEAD.
		local
			l_dir: detachable PATH
			l_git: PATH
			l_git_dir: detachable PATH
			l_line: detachable STRING_32
		do
			from
				l_dir := a_location.absolute_path.canonical_path
			until
				l_dir = Void or l_git_dir /= Void
			loop
				l_git := l_dir.extended (".git")
				if (create {DIRECTORY}.make_with_path (l_git)).exists then
					l_git_dir := l_git
				elseif (create {RAW_FILE}.make_with_path (l_git)).exists then
						-- Worktree or submodule: ".git" is a file "gitdir: <path>".
					l_line := first_line (l_git)
					if l_line /= Void and then l_line.starts_with ({STRING_32} "gitdir:") then
						l_line.remove_head (7)
						l_line.adjust
						if not l_line.is_empty then
							create l_git_dir.make_from_string (l_line)
							if not l_git_dir.is_absolute then
								l_git_dir := l_dir.extended_path (l_git_dir)
							end
						end
					end
					if l_git_dir = Void then
						l_dir := Void
					end
				end
				if l_git_dir = Void and l_dir /= Void then
					if attached l_dir.entry then
						l_dir := l_dir.parent
					else
							-- Root folder.
						l_dir := Void
					end
				end
			variant
				if attached l_dir then l_dir.name.count + 1 else 0 end
			end
			if l_git_dir /= Void then
				l_line := first_line (l_git_dir.extended ("HEAD"))
				if l_line /= Void then
					l_line.adjust
					if l_line.starts_with ({STRING_32} "ref:") then
						l_line.remove_head (4)
						l_line.adjust
						if l_line.starts_with ({STRING_32} "refs/heads/") then
							l_line.remove_head (11)
						end
						l_line.replace_substring_all ({STRING_32} "/", {STRING_32} "_")
						l_line.replace_substring_all ({STRING_32} "\", {STRING_32} "_")
						if not l_line.is_empty then
							Result := l_line
						end
					elseif not l_line.is_empty then
						Result := l_line.head (8)
					end
				end
			end
		ensure
			no_separator: attached Result implies not (Result.has ('/') or Result.has ('\'))
		end

feature {NONE} -- Implementation

	analyze
			-- Find the variables of `template`, and set `has_variables`,
			-- `is_unterminated` and `unknown_variables`.
		local
			i, j, n: INTEGER
			l_name: STRING_32
		do
			from
				i := 1
				n := template.count
			until
				i > n
			loop
				j := template.substring_index (Opening_delimiter, i)
				if j = 0 then
					i := n + 1
				else
					has_variables := True
					i := template.substring_index (Closing_delimiter, j + Opening_delimiter.count)
					if i = 0 then
						is_unterminated := True
						i := n + 1
					else
						l_name := variable_name (j, i)
						if not is_supported_variable (l_name) and not unknown_variables.has (l_name) then
							unknown_variables.extend (l_name)
						end
						i := i + Closing_delimiter.count
					end
				end
			variant
				n - i + 1
			end
		end

	variable_text (a_opening, a_closing: INTEGER): STRING_32
			-- Text between the opening delimiter at `a_opening` and the closing delimiter
			-- at `a_closing` in `template`.
		require
			valid_opening: template.substring_index (Opening_delimiter, a_opening) = a_opening
			valid_closing: template.substring_index (Closing_delimiter, a_closing) = a_closing
			ordered: a_opening + Opening_delimiter.count <= a_closing
		do
			Result := template.substring (a_opening + Opening_delimiter.count, a_closing - 1)
		end

	variable_name (a_opening, a_closing: INTEGER): STRING_32
			-- Name of the variable between the opening delimiter at `a_opening`
			-- and the closing delimiter at `a_closing` in `template`,
			-- without default value nor surrounding spaces.
		require
			valid_opening: template.substring_index (Opening_delimiter, a_opening) = a_opening
			valid_closing: template.substring_index (Closing_delimiter, a_closing) = a_closing
			ordered: a_opening + Opening_delimiter.count <= a_closing
		local
			i: INTEGER
		do
			Result := variable_text (a_opening, a_closing)
			i := Result.substring_index (Default_separator, 1)
			if i > 0 then
				Result.keep_head (i - 1)
			end
			Result.adjust
		end

	default_value (a_opening, a_closing: INTEGER): detachable STRING_32
			-- Default value of the variable between the opening delimiter at `a_opening`
			-- and the closing delimiter at `a_closing` in `template`, if any.
		require
			valid_opening: template.substring_index (Opening_delimiter, a_opening) = a_opening
			valid_closing: template.substring_index (Closing_delimiter, a_closing) = a_closing
			ordered: a_opening + Opening_delimiter.count <= a_closing
		local
			s: STRING_32
			i: INTEGER
		do
			s := variable_text (a_opening, a_closing)
			i := s.substring_index (Default_separator, 1)
			if i > 0 then
				Result := s.substring (i + Default_separator.count, s.count)
			end
		end

	variable_value (a_name: READABLE_STRING_GENERAL): detachable STRING_32
			-- Value of the variable `a_name`, if any.
		require
			supported: is_supported_variable (a_name)
		do
			if is_environment_variable (a_name) then
				Result := (create {EXECUTION_ENVIRONMENT}).item (a_name.substring (Environment_prefix.count + 1, a_name.count))
			elseif a_name.same_string (System_variable) then
				Result := system
			elseif a_name.same_string (Target_variable) then
				Result := target
			elseif a_name.same_string (Platform_variable) then
				Result := platform
			elseif a_name.same_string (Os_variable) then
				if not platform.is_empty then
					Result := platform_os (platform)
				end
			elseif a_name.same_string (Arch_variable) then
				if not platform.is_empty then
					Result := platform_arch (platform)
				end
			elseif a_name.same_string (Ec_version_variable) then
				Result := ec_version
			elseif a_name.same_string (Ec_build_variable) then
				if not build.is_empty then
					Result := ec_version
					Result.append_character ('.')
					Result.append (build)
				end
			else
				check is_git_branch: a_name.same_string (Git_branch_variable) end
				if attached git_location as l_location then
					Result := git_branch (l_location)
				end
			end
		end

	first_line (a_file: PATH): detachable STRING_32
			-- First line of the text file `a_file`, if it can be read.
		local
			f: detachable PLAIN_TEXT_FILE
			retried: BOOLEAN
		do
			if not retried then
				create f.make_with_path (a_file)
				if f.exists and then f.is_readable then
					f.open_read
					if not f.end_of_file then
						f.read_line
						create Result.make_from_string_general (f.last_string)
					end
					f.close
				end
			end
		rescue
			retried := True
			if attached f and then not f.is_closed then
				f.close
			end
			retry
		end

	append_variable_list (a_names: LIST [READABLE_STRING_32]; a_output: STRING_32)
			-- Append the variables `a_names` with their delimiters to `a_output`, separated by spaces.
		do
			across
				a_names as n
			loop
				a_output.append_character (' ')
				a_output.append (Opening_delimiter)
				a_output.append (n)
				a_output.append (Closing_delimiter)
			end
		end

	is_windows_platform_name (a_platform: READABLE_STRING_GENERAL): BOOLEAN
			-- Is `a_platform` a Windows platform name?
		do
			Result := a_platform.same_string ("win64") or a_platform.same_string ("windows")
				or else (a_platform.count > 8 and then a_platform.head (8).same_string ("windows-"))
		end

invariant
	valid_definition: is_valid = (not is_unterminated and unknown_variables.is_empty)
	unterminated_has_variables: is_unterminated implies has_variables

note
	copyright: "Copyright (c) 1984-2026, Eiffel Software"
	license: "GPL version 2 (see http://www.eiffel.com/licensing/gpl.txt)"
	licensing_options: "http://www.eiffel.com/licensing"
	copying: "[
			This file is part of Eiffel Software's Eiffel Development Environment.

			Eiffel Software's Eiffel Development Environment is free
			software; you can redistribute it and/or modify it under
			the terms of the GNU General Public License as published
			by the Free Software Foundation, version 2 of the License
			(available at the URL listed under "license" above).

			Eiffel Software's Eiffel Development Environment is
			distributed in the hope that it will be useful, but
			WITHOUT ANY WARRANTY; without even the implied warranty
			of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
			See the GNU General Public License for more details.

			You should have received a copy of the GNU General Public
			License along with Eiffel Software's Eiffel Development
			Environment; if not, write to the Free Software Foundation,
			Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
		]"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"

end
