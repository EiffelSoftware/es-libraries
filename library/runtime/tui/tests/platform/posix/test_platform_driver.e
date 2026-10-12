note
	description: "[
		POSIX-only driver tests (this cluster is selected by the ECF on non-Windows platforms).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_PLATFORM_DRIVER

inherit
	EQA_TEST_SET

feature -- Registry

	tests: ARRAYED_LIST [TUPLE [name: STRING; routine: PROCEDURE]]
			-- Tests of this platform, for TEST_APP.
		do
			create Result.make (3)
			Result.extend (["test_posix_raw_mode_round_trip", agent test_posix_raw_mode_round_trip])
			Result.extend (["test_posix_read_times_out", agent test_posix_read_times_out])
			Result.extend (["test_posix_signal_handler_defers_to_loop", agent test_posix_signal_handler_defers_to_loop])
		end

feature -- Tests

	test_posix_raw_mode_round_trip
			-- Raw mode can be entered and left, and restore resets the driver state.
		local
			l_driver: POSIX_CONSOLE_DRIVER
		do
			create l_driver
			assert ("vt native", l_driver.is_vt_enabled)
			assert ("raw on", l_driver.enable_raw_mode and l_driver.is_raw)
			assert ("raw off", l_driver.disable_raw_mode and not l_driver.is_raw)
			l_driver.restore_modes
			assert ("not raw after restore", not l_driver.is_raw)
		end

	test_posix_read_times_out
			-- A read with nothing to read returns -1 after roughly the timeout.
		local
			l_driver: POSIX_CONSOLE_DRIVER
			l_start: INTEGER_64
		do
			create l_driver
			l_start := {MONOTONIC_CLOCK}.milliseconds
			if l_driver.read_char_with_timeout (20) = -1 then
				assert ("did not return early", {MONOTONIC_CLOCK}.milliseconds - l_start >= 10)
			end
		end

	test_posix_signal_handler_defers_to_loop
			-- While deferring (an application loop runs), the real handler records SIGINT and
			-- SIGHUP instead of restoring the tty and re-raising, so the process lives on
			-- (review finding C5). A second signal, or SIGTERM, would end the test process,
			-- so they are not sent here.
		local
			l_driver: POSIX_CONSOLE_DRIVER
		do
			create l_driver
			l_driver.install_ctrl_handler
			l_driver.set_deferring_termination (True)
			assert ("deferring", l_driver.is_deferring_termination)
			assert ("nothing pending", not l_driver.has_termination_request)

			raise_signal (Sigint)
			assert ("SIGINT recorded, process alive", l_driver.has_termination_request and l_driver.termination_request_code = Sigint)
			l_driver.discard_termination_request
			assert ("discarded", not l_driver.has_termination_request)

			raise_signal (Sighup)
			assert ("SIGHUP recorded", l_driver.has_termination_request and l_driver.termination_request_code = Sighup)
			l_driver.discard_termination_request

			l_driver.set_deferring_termination (False)
			assert ("not deferring", not l_driver.is_deferring_termination and not l_driver.has_termination_request)
		end

feature {NONE} -- Implementation

	raise_signal (a_sig: INTEGER)
			-- Send signal `a_sig` to the calling thread.
		external
			"C inline use <signal.h>"
		alias
			"raise ((int) $a_sig);"
		end

	Sigint: INTEGER
			-- SIGINT
		external
			"C inline use <signal.h>"
		alias
			"return SIGINT;"
		end

	Sighup: INTEGER
			-- SIGHUP
		external
			"C inline use <signal.h>"
		alias
			"return SIGHUP;"
		end

end
