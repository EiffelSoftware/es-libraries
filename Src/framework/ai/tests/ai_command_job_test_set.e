note
	description: "Tests of the programs run for the AI models (POSIX: sh, echo, sleep)."
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	AI_COMMAND_JOB_TEST_SET

inherit
	EQA_TEST_SET

feature -- Tests

	test_output_and_exit_code
			-- The output and error of a program, its exit code.
		local
			j: AI_COMMAND_JOB
		do
			if not {PLATFORM}.is_windows then
				create j.make ("sh", <<"-c", "echo out; echo err 1>&2; exit 3">>, Void, 10, 10_000)
				j.start
				wait (j, 500)
				assert ("finished", j.is_finished)
				assert ("exit code", j.exit_code = 3)
				assert ("output [" + {UTF_CONVERTER}.utf_32_string_to_utf_8_string_8 (j.output) + "]", j.output.has_substring ("out%N") and j.output.has_substring ("err%N"))
				assert ("not timed out", not j.is_timed_out)
			end
		end

	test_quick_program_output_kept
			-- The output of a program ending at once is not lost (the end of the program closes its pipes).
		local
			j: AI_COMMAND_JOB
			i: INTEGER
		do
			if not {PLATFORM}.is_windows then
				from i := 1 until i > 30 loop
					create j.make ("sh", <<"-c", "echo 42">>, Void, 10, 100)
					j.start
					wait (j, 500)
					assert ("output " + i.out + " [" + {UTF_CONVERTER}.utf_32_string_to_utf_8_string_8 (j.output) + "]", j.is_finished and j.exit_code = 0 and j.output.same_string ({STRING_32} "42%N"))
					i := i + 1
				end
			end
		end

	test_output_cut
			-- The output is cut after `max_output' bytes.
		local
			j: AI_COMMAND_JOB
		do
			if not {PLATFORM}.is_windows then
				create j.make ("sh", <<"-c", "i=0; while [ $i -lt 100 ]; do echo 0123456789; i=$((i+1)); done">>, Void, 10, 50)
				j.start
				wait (j, 500)
				assert ("cut", j.output.count = 50 and j.dropped_count = 1100 - 50)
				assert ("exit code", j.exit_code = 0)
			end
		end

	test_missing_program
			-- A program not found: an error, finished at once.
		local
			j: AI_COMMAND_JOB
		do
			create j.make ("no_such_program_for_ai_tests", <<"x">>, Void, 10, 100)
			j.start
			assert ("finished", j.is_finished)
			assert ("error", attached j.last_error as e and then e.has_substring ("not found"))
		end

	test_timeout_and_stop
			-- A program running longer than its timeout is stopped; `stop' stops one at once.
		local
			j: AI_COMMAND_JOB
		do
			if not {PLATFORM}.is_windows then
				create j.make ("sleep", <<"30">>, Void, 1, 100)
				j.start
				wait (j, 500)
				assert ("finished", j.is_finished)
				assert ("timed out", j.is_timed_out)
				assert ("quickly", j.seconds < 10)
				create j.make ("sh", <<"-c", "sleep 30; echo never">>, "/tmp", 60, 100)
				j.start
				sleep_ms (200)
				j.stop
				wait (j, 500)
				assert ("stopped", j.is_finished and j.is_stopped and not j.output.has_substring ("never"))
			end
		end

feature {NONE} -- Implementation

	sleep_ms (n: INTEGER)
			-- Wait `n' milliseconds.
		do
			(create {EXECUTION_ENVIRONMENT}).sleep (n.to_integer_64 * 1_000_000)
		end

	wait (j: AI_COMMAND_JOB; a_count: INTEGER)
			-- Poll `j' every 20 ms until it ends, at most `a_count' times.
		local
			n: INTEGER
		do
			from
				j.poll
			until
				j.is_finished or n >= a_count
			loop
				sleep_ms (20)
				j.poll
				n := n + 1
			end
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
