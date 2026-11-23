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
			Result.extend (["test_posix_sigcont_sets_resume_request", agent test_posix_sigcont_sets_resume_request])
			Result.extend (["test_posix_own_continue_is_not_a_resume_request", agent test_posix_own_continue_is_not_a_resume_request])
			Result.extend (["test_posix_external_tstp_stops_child", agent test_posix_external_tstp_stops_child])
			Result.extend (["test_posix_second_external_tstp_leaves_tty_alone", agent test_posix_second_external_tstp_leaves_tty_alone])
			Result.extend (["test_posix_external_tstp_pops_pushed_title", agent test_posix_external_tstp_pops_pushed_title])
			Result.extend (["test_posix_is_foreground_follows_terminal_owner", agent test_posix_is_foreground_follows_terminal_owner])
			Result.extend (["test_posix_output_dropped_after_external_stop", agent test_posix_output_dropped_after_external_stop])
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

	test_posix_sigcont_sets_resume_request
			-- SIGCONT marks a resume request for the application loop (no process stop).
		local
			l_driver: POSIX_CONSOLE_DRIVER
		do
			create l_driver
			l_driver.install_ctrl_handler
			assert ("supports suspend", l_driver.supports_suspend_resume)
			l_driver.clear_resume_request
			assert ("no resume yet", not l_driver.has_resume_request)
			raise_signal (Sigcont)
			assert ("resume pending", l_driver.has_resume_request)
			l_driver.clear_resume_request
			assert ("cleared", not l_driver.has_resume_request)
		end

	test_posix_own_continue_is_not_a_resume_request
			-- L2: the SIGCONT that ends the driver's own stop never asks for a second resume,
			-- even when its handler runs after `suspend_process` returned; a later one does.
			-- (`expect_continue` is what `suspend_process` does before stopping; the test
			-- cannot stop its own process.)
		local
			l_driver: POSIX_CONSOLE_DRIVER
		do
			create l_driver
			l_driver.install_ctrl_handler
			assert ("fresh driver: no request", not l_driver.has_resume_request)
			l_driver.expect_continue
			raise_signal (Sigcont)
			assert ("own continue accounted for", not l_driver.has_resume_request)
			raise_signal (Sigcont)
			assert ("next continue is a request", l_driver.has_resume_request)
			l_driver.clear_resume_request
			assert ("handled once", not l_driver.has_resume_request)
				-- A driver created after earlier continues starts without a request
			create l_driver
			assert ("new driver ignores old continues", not l_driver.has_resume_request)
		end

	test_posix_external_tstp_stops_child
			-- M8: a SIGTSTP from outside runs the real handler, which writes the reset once and
			-- stops the process; SIGCONT lets it go on with errno kept. The test cannot stop
			-- itself, so a forked child takes the signal (see `external_stop_check').
		local
			l_driver: POSIX_CONSOLE_DRIVER
			l_code: INTEGER
		do
			create l_driver
			l_driver.install_ctrl_handler
			l_code := external_stop_check (1, False)
			assert ("child forked", l_code < 20)
			assert ("stopped, not looping in the handler", l_code /= 1)
			assert ("stopped by SIGTSTP", l_code /= 2)
			assert ("errno kept by the handler", l_code /= 3)
			assert ("exited after SIGCONT", l_code /= 4)
			assert ("did not exit before the stop", l_code /= 5)
			assert ("exited normally", l_code /= 6)
			assert ("reset written once", l_code /= 7)
				-- P2 T1: DECSCUSR 0 (crossterm `SetCursorStyle::DefaultUserShape`, from its
				-- documentation; not checked against the crossterm source)
			assert ("reset gives the default cursor shape back", l_code /= 8)
			assert ("no title pop without a push", l_code /= 9)
			assert ("reset turns motion reporting off", l_code /= 10)
			assert ("all checks passed", l_code = 0)
		end

	test_posix_second_external_tstp_leaves_tty_alone
			-- M9: a second SIGTSTP from outside, before the application has set the terminal up
			-- again (it waits in the background for `fg`), stops the process but writes no reset
			-- and leaves the modes alone: the terminal is the shell's.
		local
			l_driver: POSIX_CONSOLE_DRIVER
			l_code: INTEGER
		do
			create l_driver
			l_driver.install_ctrl_handler
			l_code := external_stop_check (2, False)
			assert ("child forked", l_code < 20)
			assert ("stopped, not looping in the handler", l_code /= 1)
			assert ("stopped by SIGTSTP", l_code /= 2)
			assert ("errno kept by the handler", l_code /= 3)
			assert ("exited after SIGCONT", l_code /= 4)
			assert ("did not exit before the stop", l_code /= 5)
			assert ("exited normally", l_code /= 6)
			assert ("reset written once, at the first stop", l_code /= 7)
			assert ("reset gives the default cursor shape back", l_code /= 8)
			assert ("no title pop without a push", l_code /= 9)
			assert ("reset turns motion reporting off", l_code /= 10)
			assert ("all checks passed", l_code = 0)
		end

	test_posix_external_tstp_pops_pushed_title
			-- P2 T2: with a window title pushed (as {ANSI_TERMINAL_BACKEND}.push_title records
			-- it), the SIGTSTP handler writes the title pop `CSI 23 ; 0 t` (XTWINOPS) right
			-- after its reset and clears the push, so the second stop pops nothing. Two
			-- stops, as in `test_posix_second_external_tstp_leaves_tty_alone`.
		local
			l_driver: POSIX_CONSOLE_DRIVER
			l_code: INTEGER
		do
			create l_driver
			l_driver.install_ctrl_handler
			l_code := external_stop_check (2, True)
			assert ("child forked", l_code < 20)
			assert ("stopped, not looping in the handler", l_code /= 1)
			assert ("stopped by SIGTSTP", l_code /= 2)
			assert ("errno kept by the handler", l_code /= 3)
			assert ("exited after SIGCONT", l_code /= 4)
			assert ("did not exit before the stop", l_code /= 5)
			assert ("exited normally", l_code /= 6)
			assert ("reset written once, at the first stop", l_code /= 7)
			assert ("reset gives the default cursor shape back", l_code /= 8)
			assert ("title popped once, right after the reset, and the push cleared", l_code /= 9)
			assert ("reset turns motion reporting off", l_code /= 10)
			assert ("all checks passed", l_code = 0)
				-- The flag is per process: this one's was never set
			assert ("nothing pushed here", not l_driver.is_title_pushed)
		end

	test_posix_is_foreground_follows_terminal_owner
			-- M9: `is_foreground` holds only while the process group owns the terminal on stdin,
			-- as the shell hands it over with `fg`, and when stdin is no terminal. The test
			-- process may have no terminal, so a forked child opens a pseudo terminal as its
			-- controlling terminal (see `foreground_check').
		local
			l_driver: POSIX_CONSOLE_DRIVER
			l_code: INTEGER
		do
				-- The driver defines the C helper that the child calls
			create l_driver
			l_code := foreground_check
			assert ("child forked, pseudo terminal opened", l_code < 10)
			assert ("session leader owns its terminal", l_code /= 1)
			assert ("other process group does not", l_code /= 2)
			assert ("owns it once given it", l_code /= 3)
			assert ("no terminal: nothing to wait for", l_code /= 4)
			assert ("not after giving it away", l_code /= 5)
			assert ("all checks passed", l_code = 0)
		end

	test_posix_output_dropped_after_external_stop
			-- M11: a SIGTSTP from outside in the middle of a frame. After the continue, the
			-- rest of the frame is dropped (the terminal may be the shell's now), until the
			-- application takes note of the continue (`clear_resume_request`); then output
			-- is written again. A forked child takes the signal (see `output_after_stop_check').
		local
			l_driver: POSIX_CONSOLE_DRIVER
			l_code: INTEGER
		do
			create l_driver
			l_driver.install_ctrl_handler
			assert ("written through the driver", l_driver.writes_output)
			assert ("not blocked at first", not l_driver.is_output_blocked)
			l_code := output_after_stop_check
			assert ("child forked", l_code < 10)
			assert ("stopped by SIGTSTP", l_code /= 1)
			assert ("exited after SIGCONT", l_code /= 2)
			assert ("blocked after the stop", l_code /= 3)
			assert ("exited normally", l_code /= 4)
			assert ("output before the stop written", l_code /= 5)
			assert ("rest of the frame dropped", l_code /= 6)
			assert ("output after clear_resume_request written", l_code /= 7)
			assert ("all checks passed", l_code = 0)
				-- In this process, the flag is cleared as the loop does it
			l_driver.clear_resume_request
			assert ("not blocked", not l_driver.is_output_blocked)
		end

feature {NONE} -- Implementation

	output_after_stop_check: INTEGER
			-- Fork a child that has set the terminal up, writes "A" with
			-- `eiffeltui_posix_write_output', raises SIGTSTP into the driver's handler (as
			-- `kill -TSTP' would) and, continued, writes "B", then unblocks the output as
			-- `clear_resume_request' does and writes "C". 0 if it stopped and exited, and its
			-- standard output was "A", the reset, then "C"; otherwise the number of the first
			-- check that failed (see the test's assertions).
		external
			"C inline use <signal.h>, <unistd.h>, <sys/wait.h>, <fcntl.h>, <string.h>, <time.h>"
		alias
			"[
				int l_pipe [2];
				pid_t l_pid;
				pid_t l_waited = 0;
				int l_status = 0;
				int l_ms;
				int l_result = 0;
				char l_out [4096];
				size_t l_len = 0;
				ssize_t l_n;
				char *l_reset;
				struct timespec l_tick = {0, 10000000};
				if (pipe (l_pipe) != 0) return 10;
				l_pid = fork ();
				if (l_pid < 0) return 11;
				if (l_pid == 0) {
					extern int eiffeltui_posix_saved;
					extern volatile sig_atomic_t eiffeltui_posix_tty_taken;
					extern volatile sig_atomic_t eiffeltui_posix_output_blocked;
					extern void eiffeltui_posix_write_output (const char *a_bytes, size_t a_count);
						/* As in `external_stop_check': own group, stdin off the tty. */
					int l_null = open ("/dev/null", O_RDONLY);
					eiffeltui_posix_saved = 1;
					eiffeltui_posix_tty_taken = 1;
					setpgid (0, 0);
					if (l_null >= 0) dup2 (l_null, STDIN_FILENO);
					dup2 (l_pipe [1], STDOUT_FILENO);
					close (l_pipe [0]);
					eiffeltui_posix_write_output ("A", 1);
					raise (SIGTSTP);
					if (!eiffeltui_posix_output_blocked) _exit (3);
					eiffeltui_posix_write_output ("B", 1);
						/* As `clear_resume_request' does. */
					eiffeltui_posix_output_blocked = 0;
					eiffeltui_posix_write_output ("C", 1);
					_exit (0);
				}
				close (l_pipe [1]);
				for (l_ms = 0; l_ms < 2000 && (l_waited = waitpid (l_pid, &l_status, WUNTRACED | WNOHANG)) == 0; l_ms += 10) {
					nanosleep (&l_tick, NULL);
				}
				if (l_waited != l_pid || !WIFSTOPPED (l_status) || WSTOPSIG (l_status) != SIGTSTP) {
					l_result = 1;
				} else {
					kill (l_pid, SIGCONT);
					for (l_ms = 0; l_ms < 2000 && (l_waited = waitpid (l_pid, &l_status, WNOHANG)) == 0; l_ms += 10) {
						nanosleep (&l_tick, NULL);
					}
					if (l_waited != l_pid || !WIFEXITED (l_status)) {
						l_result = 2;
					} else if (WEXITSTATUS (l_status) == 3) {
						l_result = 3;
					} else if (WEXITSTATUS (l_status) != 0) {
						l_result = 4;
					}
				}
				if (l_result == 1 || l_result == 2) {
					kill (l_pid, SIGKILL);
					waitpid (l_pid, &l_status, 0);
				}
				while (l_len < sizeof (l_out) - 1 && (l_n = read (l_pipe [0], l_out + l_len, sizeof (l_out) - 1 - l_len)) > 0) {
					l_len += (size_t) l_n;
				}
				close (l_pipe [0]);
				l_out [l_len] = '\0';
				l_reset = strstr (l_out, "\x1b[?1049l");
				if (l_result == 0) {
					if (l_out [0] != 'A' || l_reset == NULL) {
						l_result = 5;
					} else if (strchr (l_out, 'B') != NULL) {
						l_result = 6;
					} else if (strcmp (l_reset + strlen ("\x1b[?1049l"), "C") != 0) {
						l_result = 7;
					}
				}
				return (EIF_INTEGER) l_result;
			]"
		end

	external_stop_check (a_stops: INTEGER; a_title_pushed: BOOLEAN): INTEGER
			-- Fork a child that has set the terminal up and raises SIGTSTP `a_stops' times into
			-- the handler installed by the driver, as `kill -TSTP' would, and continue it each
			-- time: 0 if it stopped within 2 s each time, exited 0 after the last SIGCONT (errno
			-- unchanged across the handler) and wrote the reset sequence once, at the first stop
			-- (later ones find the terminal restored), with the default cursor shape `ESC [ 0 SP q`
			-- in it. With `a_title_pushed' the child has a window title pushed: the title pop
			-- `ESC [ 23 ; 0 t` must follow the reset once and the push be cleared (P2 T2);
			-- without, no pop may be written. The reset must also turn any-event mouse tracking
			-- off (`ESC [ ? 1003 l`, P2 W6). Otherwise the number of the first check that
			-- failed (see the tests' assertions); 20 and up when the child could not be forked.
		require
			positive: a_stops > 0
		external
			"C inline use <signal.h>, <unistd.h>, <sys/wait.h>, <fcntl.h>, <errno.h>, <string.h>, <time.h>"
		alias
			"[
				int l_pipe [2];
				pid_t l_pid;
				pid_t l_waited = 0;
				int l_status = 0;
				int l_ms;
				int l_round;
				int l_result = 0;
				int l_resets = 0;
				int l_pops = 0;
				int l_pop_kept = 0;
				char l_out [4096];
				size_t l_len = 0;
				ssize_t l_n;
				char *l_at;
				struct timespec l_tick = {0, 10000000};
				if (pipe (l_pipe) != 0) return 20;
				l_pid = fork ();
				if (l_pid < 0) return 21;
				if (l_pid == 0) {
						/* Own process group: an orphaned group discards SIGTSTP. Stdin off
						 * the tty: no SIGTTOU when the handler restores the modes, and
						 * with modes marked saved, its tcsetattr fails (ENOTTY) even where
						 * the suite runs without a tty, so a lost errno shows. */
					extern int eiffeltui_posix_saved;
					extern volatile sig_atomic_t eiffeltui_posix_tty_taken;
					extern volatile sig_atomic_t eiffeltui_posix_title_pushed;
					int l_null = open ("/dev/null", O_RDONLY);
					int l_stop;
					eiffeltui_posix_saved = 1;
						/* As `enable_raw_mode' records it, and `push_title' (P2 T2). */
					eiffeltui_posix_tty_taken = 1;
					eiffeltui_posix_title_pushed = $a_title_pushed ? 1 : 0;
					setpgid (0, 0);
					if (l_null >= 0) dup2 (l_null, STDIN_FILENO);
					dup2 (l_pipe [1], STDOUT_FILENO);
					close (l_pipe [0]);
					errno = EDOM;
					for (l_stop = 0; l_stop < $a_stops; l_stop++) {
						raise (SIGTSTP);
						if (errno != EDOM) _exit (3);
					}
						/* The handler pops a pushed title once and clears the push. */
					if (eiffeltui_posix_title_pushed) _exit (8);
					_exit (0);
				}
				close (l_pipe [1]);
				for (l_round = 0; l_result == 0 && l_round < $a_stops; l_round++) {
					for (l_ms = 0; l_ms < 2000 && (l_waited = waitpid (l_pid, &l_status, WUNTRACED | WNOHANG)) == 0; l_ms += 10) {
						nanosleep (&l_tick, NULL);
					}
					if (l_waited != l_pid) {
						l_result = 1;
					} else if (!WIFSTOPPED (l_status)) {
						l_result = 5;
					} else if (WSTOPSIG (l_status) != SIGTSTP) {
						l_result = 2;
					} else {
						kill (l_pid, SIGCONT);
					}
				}
				if (l_result == 0) {
					for (l_ms = 0; l_ms < 2000 && (l_waited = waitpid (l_pid, &l_status, WNOHANG)) == 0; l_ms += 10) {
						nanosleep (&l_tick, NULL);
					}
					if (l_waited != l_pid || !WIFEXITED (l_status)) {
						l_result = 4;
					} else if (WEXITSTATUS (l_status) == 3) {
						l_result = 3;
					} else if (WEXITSTATUS (l_status) == 8) {
						l_pop_kept = 1;
					} else if (WEXITSTATUS (l_status) != 0) {
						l_result = 6;
					}
				}
				if (l_result == 1 || l_result == 2 || l_result == 4) {
						/* Still alive (looping, stopped or not done): end it. */
					kill (l_pid, SIGKILL);
					waitpid (l_pid, &l_status, 0);
				}
					/* The child is gone, so the pipe ends; keep the first 4 KB. */
				while ((l_n = read (l_pipe [0], l_out + l_len, sizeof (l_out) - 1 - l_len)) > 0) {
					l_len += (size_t) l_n;
					if (l_len == sizeof (l_out) - 1) {
						char l_rest [4096];
						while (read (l_pipe [0], l_rest, sizeof (l_rest)) > 0) { }
						break;
					}
				}
				close (l_pipe [0]);
				l_out [l_len] = '\0';
				for (l_at = strstr (l_out, "\x1b[?1049l"); l_at != NULL; l_at = strstr (l_at + 1, "\x1b[?1049l")) {
					l_resets++;
				}
				if (l_result == 0 && l_resets != 1) l_result = 7;
				if (l_result == 0 && strstr (l_out, "\x1b[0 q") == NULL) l_result = 8;
				for (l_at = strstr (l_out, "\x1b[23;0t"); l_at != NULL; l_at = strstr (l_at + 1, "\x1b[23;0t")) {
					l_pops++;
				}
				if (l_result == 0) {
					if ($a_title_pushed) {
						if (l_pops != 1 || l_pop_kept || strstr (l_out, "\x1b[?1049l\x1b[23;0t") == NULL) l_result = 9;
					} else if (l_pops != 0) {
						l_result = 9;
					}
				}
					/* P2 W6: any-event mouse tracking off */
				if (l_result == 0 && strstr (l_out, "\x1b[?1003l") == NULL) l_result = 10;
				return (EIF_INTEGER) l_result;
			]"
		end

	foreground_check: INTEGER
			-- Fork a child that becomes a session leader with a new pseudo terminal on stdin,
			-- as a shell is, and forks a grandchild in its own process group, as a job is.
			-- 0 if `eiffeltui_posix_is_foreground' held for the leader, not for the job, held
			-- for the job and not for the leader once the leader gave the job the terminal
			-- (`tcsetpgrp', as `fg' does), and held with stdin from /dev/null; otherwise the
			-- number of the first check that failed (see the test's assertions), or 10 or more
			-- if the child or the pseudo terminal could not be made.
		external
			"C inline use <unistd.h>, <sys/wait.h>, <sys/ioctl.h>, <fcntl.h>, <stdlib.h>, <termios.h>, <time.h>, <signal.h>"
		alias
			"[
				extern int eiffeltui_posix_is_foreground (void);
				extern int posix_openpt (int);
				extern int grantpt (int);
				extern int unlockpt (int);
				extern char *ptsname (int);
				pid_t l_pid;
				pid_t l_waited = 0;
				int l_status = 0;
				int l_ms;
				struct timespec l_tick = {0, 10000000};
				l_pid = fork ();
				if (l_pid < 0) return 11;
				if (l_pid == 0) {
					int l_master, l_slave, l_null, l_result = 0;
					int l_ready [2], l_go [2];
					char *l_name;
					char l_byte = 0;
					pid_t l_job, l_gone;
					int l_job_status = 0;
					l_master = posix_openpt (O_RDWR | O_NOCTTY);
					if (l_master < 0 || grantpt (l_master) != 0 || unlockpt (l_master) != 0) _exit (12);
					l_name = ptsname (l_master);
					if (l_name == NULL || setsid () < 0) _exit (13);
					l_slave = open (l_name, O_RDWR);
					if (l_slave < 0) _exit (14);
					ioctl (l_slave, TIOCSCTTY, 0);
					dup2 (l_slave, STDIN_FILENO);
					if (!eiffeltui_posix_is_foreground ()) _exit (1);
					if (pipe (l_ready) != 0 || pipe (l_go) != 0) _exit (15);
					l_job = fork ();
					if (l_job < 0) _exit (16);
					if (l_job == 0) {
						int l_job_result = 0;
							/* Only the leader writes `l_go': if it dies, the read below ends. */
						close (l_go [1]);
						setpgid (0, 0);
						if (eiffeltui_posix_is_foreground ()) l_job_result = 2;
						if (write (l_ready [1], &l_byte, 1) != 1) _exit (17);
						if (read (l_go [0], &l_byte, 1) != 1) _exit (17);
						if (l_job_result == 0 && !eiffeltui_posix_is_foreground ()) l_job_result = 3;
						_exit (l_job_result);
					}
					close (l_ready [1]);
					setpgid (l_job, l_job);
					if (read (l_ready [0], &l_byte, 1) != 1) _exit (17);
						/* As `fg' does: the terminal to the job's group. */
					if (tcsetpgrp (STDIN_FILENO, l_job) != 0) _exit (18);
					if (eiffeltui_posix_is_foreground ()) l_result = 5;
					if (write (l_go [1], &l_byte, 1) != 1) _exit (17);
					l_gone = waitpid (l_job, &l_job_status, 0);
					if (l_gone != l_job || !WIFEXITED (l_job_status)) _exit (19);
					if (WEXITSTATUS (l_job_status) != 0) l_result = WEXITSTATUS (l_job_status);
					l_null = open ("/dev/null", O_RDONLY);
					if (l_null < 0) _exit (15);
					dup2 (l_null, STDIN_FILENO);
					if (l_result == 0 && !eiffeltui_posix_is_foreground ()) l_result = 4;
					_exit (l_result);
				}
				for (l_ms = 0; l_ms < 2000 && (l_waited = waitpid (l_pid, &l_status, WNOHANG)) == 0; l_ms += 10) {
					nanosleep (&l_tick, NULL);
				}
				if (l_waited != l_pid) {
					kill (l_pid, SIGKILL);
					waitpid (l_pid, &l_status, 0);
					return 10;
				}
				if (!WIFEXITED (l_status)) return 10;
				return (EIF_INTEGER) WEXITSTATUS (l_status);
			]"
		end

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

	Sigcont: INTEGER
			-- SIGCONT
		external
			"C inline use <signal.h>"
		alias
			"return SIGCONT;"
		end

end
