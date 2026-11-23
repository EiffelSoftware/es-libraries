note
	description: "Tests of {PROJECT_PATH_TEMPLATE}."
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	PROJECT_PATH_TEMPLATE_TEST_SET

inherit
	EQA_TEST_SET

feature -- Tests

	test_no_variable
			-- A path without variable is kept as is.
		local
			t: PROJECT_PATH_TEMPLATE
		do
			t := new_template ("/tmp/EiffelCOMP/ec")
			assert ("no variable", not t.has_variables)
			assert ("valid", t.is_valid)
			t.expand
			assert ("same", t.expanded_string.same_string ("/tmp/EiffelCOMP/ec"))
			assert ("nothing missing", not t.has_missing_values)
		end

	test_all_variables
			-- Every built-in variable is replaced.
		local
			t: PROJECT_PATH_TEMPLATE
			v: STRING_32
		do
			v := t_version
			t := new_template ("/tmp/EiffelCOMP/{{system}}-{{target}}-{{platform}}_{{ec_version}}/")
			assert ("has variables", t.has_variables)
			assert ("valid", t.is_valid)
			t.expand
			assert ("windows", t.expanded_string.same_string ({STRING_32} "/tmp/EiffelCOMP/ec-bench-win64_" + v + "/"))

			t := new_template ("C:\EiffelCOMP\{{os}}\{{arch}}\{{ec_build}}\{{system}}")
			t.set_platform ("linux-x86-64")
			assert ("valid os/arch/build", t.is_valid)
			t.expand
			assert ("os, arch, build", t.expanded_string.same_string ({STRING_32} "C:\EiffelCOMP\linux\x86-64\" + v + ".98732\ec"))
		end

	test_spaces_and_repetition
			-- Spaces around the name are ignored, a variable can be used several times.
		local
			t: PROJECT_PATH_TEMPLATE
		do
			t := new_template ("{{ target }}/{{target}}{{system}}")
			assert ("valid", t.is_valid)
			t.expand
			assert ("expanded", t.expanded_string.same_string ("bench/benchec"))
		end

	test_unknown_variables
			-- Unknown variables make the pattern invalid, even with a default value, and are listed once.
		local
			t: PROJECT_PATH_TEMPLATE
		do
			t := new_template ("/tmp/{{system}}-{{foo}}-{{Target}}-{{foo:-x}}-{{}}-{{env:}}")
			assert ("not valid", not t.is_valid)
			assert ("terminated", not t.is_unterminated)
			assert ("four unknown", t.unknown_variables.count = 4)
			assert ("foo", t.unknown_variables.first.same_string ("foo"))
			assert ("case sensitive", t.unknown_variables.i_th (2).same_string ("Target"))
			assert ("empty", t.unknown_variables.i_th (3).is_empty)
			assert ("env without name", t.unknown_variables.last.same_string ("env:"))
			assert ("message", t.error_message.has_substring ("unknown variables {{foo}} {{Target}} {{}} {{env:}}"))
		end

	test_unterminated
			-- An opening delimiter without closing delimiter makes the pattern invalid.
		local
			t: PROJECT_PATH_TEMPLATE
		do
			t := new_template ("/tmp/{{system}}-{{target")
			assert ("has variables", t.has_variables)
			assert ("unterminated", t.is_unterminated)
			assert ("not valid", not t.is_valid)
			assert ("message", t.error_message.has_substring ("missing %"}}%""))
		end

	test_single_braces
			-- Single braces are not delimiters.
		local
			t: PROJECT_PATH_TEMPLATE
		do
			t := new_template ("/tmp/{system}/}}")
			assert ("no variable", not t.has_variables)
			assert ("valid", t.is_valid)
			t.expand
			assert ("same", t.expanded_string.same_string ("/tmp/{system}/}}"))
		end

	test_environment_variables
			-- {{env:NAME}} and default values.
		local
			t: PROJECT_PATH_TEMPLATE
		do
			execution_environment.put ("jdoe", "PPT_TEST_USER")
			execution_environment.put ("", "PPT_TEST_EMPTY")
			t := new_template ("/tmp/{{env:PPT_TEST_USER}}/{{ env:PPT_TEST_USER :-nobody}}/{{env:PPT_TEST_EMPTY:-empty}}/{{env:PPT_TEST_UNDEFINED_42:-}}/{{env:PPT_TEST_UNDEFINED_42:-a:-b}}")
			assert ("valid", t.is_valid)
			t.expand
			assert ("nothing missing", not t.has_missing_values)
			assert ("expanded", t.expanded_string.same_string ("/tmp/jdoe/jdoe/empty//a:-b"))

			t := new_template ("/tmp/{{env:PPT_TEST_UNDEFINED_42}}/{{env:PPT_TEST_EMPTY}}/{{env:PPT_TEST_UNDEFINED_42}}")
			assert ("valid undefined", t.is_valid)
			t.expand
			assert ("missing", t.has_missing_values)
			assert ("two missing", t.missing_variables.count = 2)
			assert ("message", t.error_message.has_substring ("no value for {{env:PPT_TEST_UNDEFINED_42}} {{env:PPT_TEST_EMPTY}}"))
		end

	test_default_of_built_in
			-- Default value of a built-in variable without value.
		local
			t: PROJECT_PATH_TEMPLATE
		do
			create t.make ("{{system}}-{{ec_build:-nobuild}}-{{git_branch:-nobranch}}")
			t.set_system ("ec")
			t.expand
			assert ("defaults", t.expanded_string.same_string ("ec-nobuild-nobranch"))

			create t.make ("{{target}}")
			t.expand
			assert ("missing target", t.has_missing_values and then t.missing_variables.first.same_string ("target"))
		end

	test_git_branch
			-- {{git_branch}} from the HEAD of a repository, of a worktree, and a detached HEAD.
		local
			t: PROJECT_PATH_TEMPLATE
			l_root, l_sub: PATH
		do
			l_root := execution_environment.current_working_path.extended ("ppt_repo")
			l_sub := l_root.extended ("src").extended ("lib")
			create_folder (l_sub)
			create_folder (l_root.extended (".git"))
			write_file (l_root.extended (".git").extended ("HEAD"), "ref: refs/heads/ai/v_topic%N")

			t := new_template ("{{system}}-{{git_branch}}")
			t.set_git_location (l_sub)
			t.expand
			assert ("branch from sub folder", t.expanded_string.same_string ("ec-ai_v_topic"))
			assert ("branch", attached t.git_branch (l_root) as b and then b.same_string ("ai_v_topic"))

				-- Worktree: ".git" is a file with a relative "gitdir:".
			create_folder (l_root.extended (".git").extended ("worktrees").extended ("wt"))
			write_file (l_root.extended (".git").extended ("worktrees").extended ("wt").extended ("HEAD"), "ref: refs/heads/feature/x%R%N")
			create_folder (l_root.extended ("wt"))
			write_file (l_root.extended ("wt").extended (".git"), "gitdir: ../.git/worktrees/wt%N")
			assert ("worktree branch", attached t.git_branch (l_root.extended ("wt")) as b and then b.same_string ("feature_x"))

				-- Detached HEAD.
			write_file (l_root.extended (".git").extended ("HEAD"), "0123456789abcdef0123456789abcdef01234567%N")
			assert ("detached", attached t.git_branch (l_sub) as b and then b.same_string ("01234567"))
		end

	test_platform_parts
			-- Operating system and architecture of the ISE_PLATFORM values.
		local
			t: PROJECT_PATH_TEMPLATE
		do
			create t.make ("")
			assert ("win64 os", t.platform_os ("win64").same_string ("windows"))
			assert ("win64 arch", t.platform_arch ("win64").same_string ("x86-64"))
			assert ("windows os", t.platform_os ("windows").same_string ("windows"))
			assert ("windows arch", t.platform_arch ("windows").same_string ("x86"))
			assert ("windows-arm64-mingw os", t.platform_os ("windows-arm64-mingw").same_string ("windows"))
			assert ("windows-arm64-mingw arch", t.platform_arch ("windows-arm64-mingw").same_string ("arm64-mingw"))
			assert ("linux os", t.platform_os ("linux-x86-64").same_string ("linux"))
			assert ("linux arch", t.platform_arch ("linux-x86-64").same_string ("x86-64"))
			assert ("macosx os", t.platform_os ("macosx-arm64").same_string ("macosx"))
			assert ("macosx arch", t.platform_arch ("macosx-arm64").same_string ("arm64"))
			assert ("alpha os", t.platform_os ("alpha").same_string ("alpha"))
			assert ("alpha arch", t.platform_arch ("alpha").same_string ("unknown"))
		end

feature {NONE} -- Implementation

	new_template (a_template: READABLE_STRING_GENERAL): PROJECT_PATH_TEMPLATE
			-- Template `a_template` for system "ec", target "bench", platform "win64", build "98732".
		do
			create Result.make (a_template)
			Result.set_system ("ec")
			Result.set_target ("bench")
			Result.set_platform ("win64")
			Result.set_build ("98732")
		end

	t_version: STRING_32
			-- Expected value of {{ec_version}}.
		do
			create Result.make (5)
			Result.append_natural_16 ({EIFFEL_CONSTANTS}.major_version)
			Result.append_character ('.')
			if {EIFFEL_CONSTANTS}.minor_version < 10 then
				Result.append_character ('0')
			end
			Result.append_natural_16 ({EIFFEL_CONSTANTS}.minor_version)
		end

	execution_environment: EXECUTION_ENVIRONMENT
			-- Access to the environment variables and current folder.
		once
			create Result
		end

	create_folder (a_path: PATH)
			-- Create the folder `a_path` and its parents.
		do
			(create {DIRECTORY}.make_with_path (a_path)).recursive_create_dir
		end

	write_file (a_path: PATH; a_content: STRING_8)
			-- Write `a_content` in the file `a_path`.
		local
			f: PLAIN_TEXT_FILE
		do
			create f.make_with_path (a_path)
			f.create_read_write
			f.put_string (a_content)
			f.close
		end

end
