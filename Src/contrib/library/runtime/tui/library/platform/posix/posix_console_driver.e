note
	description: "[
		POSIX platform driver interfacing with Linux/macOS terminals via inlined C
		termios, ioctl(TIOCGWINSZ), poll, and signal handlers.
		Saves the complete original termios state once and restores it exactly.

		Shared native state (the original termios) lives in file-scope C globals defined
		once by `c_posix_define_runtime', so that the signal handler can restore the tty.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	POSIX_CONSOLE_DRIVER

inherit
	CONSOLE_DRIVER
		redefine
			default_create,
			input_claim,
			supports_suspend_resume,
			has_resume_request,
			is_foreground,
			clear_resume_request,
			suspend_process,
			writes_output,
			write_output,
			is_title_pushed,
			set_title_pushed
		end

create
	default_create

feature {NONE} -- Initialization

	default_create
			-- Initialize driver and its native runtime support.
		do
			c_posix_define_runtime
				-- The counter is process-wide: continues before this driver existed are not
				-- requests for it
			handled_continue_count := c_posix_continue_count
		ensure then
			no_resume_request: not has_resume_request
		end

feature -- Queries

	console_width: INTEGER
			-- Current console width in columns, or default if unavailable.
		local
			w, h: INTEGER
		do
			if c_posix_get_console_size ($w, $h) and w > 0 then
				Result := w
			else
				Result := Default_width
			end
		end

	console_height: INTEGER
			-- Current console height in rows, or default if unavailable.
		local
			w, h: INTEGER
		do
			if c_posix_get_console_size ($w, $h) and h > 0 then
				Result := h
			else
				Result := Default_height
			end
		end

	is_raw: BOOLEAN
			-- Is raw input mode currently active?

	is_vt_enabled: BOOLEAN = True
			-- POSIX terminals support VT escapes natively.

	is_mouse_enabled: BOOLEAN
			-- Is mouse tracking active?

feature -- Mode Commands

	enable_vt_mode: BOOLEAN
			-- Virtual Terminal mode is native on POSIX terminals.
		do
			Result := True
		end

	enable_raw_mode: BOOLEAN
			-- Enable raw terminal input mode via termios, saving original settings first.
		do
			Result := c_posix_enable_raw_mode
			if Result then
				is_raw := True
			end
		end

	disable_raw_mode: BOOLEAN
			-- Restore the saved original termios settings.
		do
			Result := c_posix_disable_raw_mode
			if Result then
				is_raw := False
			end
		end

	enable_mouse: BOOLEAN
			-- Enable mouse tracking (reporting itself is requested by the backend's escape codes).
		do
			is_mouse_enabled := True
			Result := True
		end

	disable_mouse: BOOLEAN
			-- Disable mouse tracking.
		do
			is_mouse_enabled := False
			Result := True
		end

	is_keyboard_enhancement_enabled: BOOLEAN
			-- Is extended keyboard reporting active?

	enable_keyboard_enhancement
			-- Enable extended keyboard reporting.
		do
			is_keyboard_enhancement_enabled := True
		end

	disable_keyboard_enhancement
			-- Disable extended keyboard reporting.
		do
			is_keyboard_enhancement_enabled := False
		end

	restore_modes
			-- Restore the full original termios state.
		do
			c_posix_restore_modes
			is_raw := False
			is_mouse_enabled := False
			is_keyboard_enhancement_enabled := False
		end

feature -- Input & Resize

	input_claim: CONSOLE_INPUT_CLAIM
			-- One claim for the whole process: every POSIX_CONSOLE_DRIVER reads the same
			-- console, and they share the read-ahead buffer kept in C (`eiffeltui_posix_input`).
		once ("PROCESS")
			create Result.make
		end

	read_char_with_timeout (a_timeout_ms: INTEGER): INTEGER
			-- Read next input byte from console with timeout in milliseconds.
			-- Returns byte value (0..255), or -1 if timeout expired or error.
		do
			Result := c_posix_read_char (a_timeout_ms)
		end

	poll_resize (a_cols, a_rows: TYPED_POINTER [INTEGER]): BOOLEAN
			-- Query if console size has changed since last poll.
		local
			w, h: INTEGER
		do
			if c_posix_get_console_size ($w, $h) and then w > 0 and then h > 0 then
				if last_polled_width = 0 and last_polled_height = 0 then
					last_polled_width := w
					last_polled_height := h
					Result := False
				elseif w /= last_polled_width or h /= last_polled_height then
					last_polled_width := w
					last_polled_height := h
					set_integer_pointer (a_cols, w)
					set_integer_pointer (a_rows, h)
					Result := True
				end
			end
		end

	install_ctrl_handler
			-- Install SIGINT, SIGTERM, SIGHUP, SIGQUIT, SIGTSTP and SIGCONT handlers.
		do
			c_posix_install_signal_handlers
		end

feature -- Suspend / resume

	supports_suspend_resume: BOOLEAN = True
			-- POSIX can stop on SIGTSTP / Ctrl+Z and resume on SIGCONT.

	has_resume_request: BOOLEAN
			-- Has a SIGCONT arrived that is not accounted for by `clear_resume_request`
			-- or `suspend_process`?
		do
			Result := c_posix_continue_count - handled_continue_count > 0
		end

	is_foreground: BOOLEAN
			-- Is the process group the foreground group of the terminal on stdin, or is stdin
			-- no terminal? The shell gives the terminal to a job with `fg` (and sends SIGCONT
			-- only if the job was stopped), and keeps it on `bg` or `kill -CONT`.
		do
			Result := c_posix_is_foreground
		end

	clear_resume_request
			-- Account for the SIGCONTs received so far, and let `write_output` write again.
		do
			handled_continue_count := c_posix_continue_count
			c_posix_allow_output
		end

	suspend_process
			-- Raise SIGTSTP with the default action so the shell stops the process;
			-- returns after SIGCONT (foreground). The SIGCONT that ends the stop is
			-- accounted for beforehand: its handler may run on another thread after this
			-- returns, and must not ask for a second resume (review finding L2).
		do
			expect_continue
			c_posix_suspend_process
		end

	expect_continue
			-- Account in advance for one SIGCONT: the one that will end a stop the caller
			-- is about to make. It does not become a resume request, whenever it arrives.
		do
			handled_continue_count := c_posix_continue_count + 1
		ensure
			no_resume_request: not has_resume_request
		end

feature {NONE} -- Suspend / resume implementation

	handled_continue_count: INTEGER
			-- Value of the SIGCONT counter already accounted for

feature -- Output

	writes_output: BOOLEAN = True
			-- Output is written with write(2), so that it can be dropped after a stop.

	is_output_blocked: BOOLEAN
			-- Does `write_output` drop its bytes now?
		do
			Result := c_posix_output_blocked
		end

	write_output (a_bytes: STRING_8)
			-- Write `a_bytes` to standard output, unless the SIGTSTP handler restored the
			-- tty since it was last set up or restored, or since `clear_resume_request`. A
			-- stop from outside can come in the middle of a frame: continued in the
			-- background, the rest of that frame would go to the shell's terminal, and after
			-- `fg` to the cooked screen before the resume clears it (review finding M11).
		local
			l_area: ANY
		do
			l_area := a_bytes.to_c
			c_posix_write_output ($l_area, a_bytes.count)
		end

feature -- Window title

	is_title_pushed: BOOLEAN
			-- Did the backend push the terminal's title without popping it since, and no
			-- handler popped it either? Kept in C (`eiffeltui_posix_title_pushed`): the signal
			-- handlers pop it when they restore the terminal, and the SIGTSTP handler clears it.
		do
			Result := c_posix_title_pushed
		end

	set_title_pushed (a_pushed: BOOLEAN)
			-- Record whether the terminal's title is pushed, for the signal handlers.
		do
			c_posix_set_title_pushed (a_pushed)
		end

feature -- Termination requests

	is_deferring_termination: BOOLEAN
			-- Are SIGINT, SIGQUIT and SIGHUP recorded for the application loop?
		do
			Result := c_posix_is_deferring
		end

	set_deferring_termination (a_on: BOOLEAN)
			-- Record SIGINT, SIGQUIT and SIGHUP for the application loop (`a_on`), or handle
			-- them at once.
		do
			c_posix_set_deferring (a_on)
		end

	has_termination_request: BOOLEAN
			-- Is a deferred signal waiting?
		do
			Result := c_posix_pending /= 0
		end

	termination_request_code: INTEGER
			-- Number of the pending signal
		do
			Result := c_posix_pending
		end

	discard_termination_request
			-- Forget the pending signal.
		do
			c_posix_discard
		end

	finish_termination
			-- Raise the pending signal again with its default action, which ends the process.
			-- Does not return.
		do
			c_posix_finish
		end

feature {NONE} -- Implementation Helpers

	last_polled_width: INTEGER
	last_polled_height: INTEGER

	set_integer_pointer (a_ptr: TYPED_POINTER [INTEGER]; a_val: INTEGER)
		external
			"C inline"
		alias
			"[
				*(EIF_INTEGER *)$a_ptr = (EIF_INTEGER)$a_val;
			]"
		end

feature {NONE} -- Inlined C Implementation

	c_posix_define_runtime
			-- Define the file-scope C state and helpers shared by the other externals.
			-- The body closes the generated wrapper function, emits file-scope
			-- definitions, and reopens an unused function for the generated epilogue.
		external
			"C inline use <termios.h>, <unistd.h>, <signal.h>, <string.h>, <errno.h>, <pthread.h>"
		alias
			"[
				}

				struct termios eiffeltui_posix_orig;
				int eiffeltui_posix_saved = 0;
				int eiffeltui_posix_handlers_installed = 0;

					/* Deferred termination (review finding C5): while an application loop draws,
					 * SIGINT, SIGQUIT and SIGHUP are recorded (0: none) and the loop restores the tty. */
				volatile sig_atomic_t eiffeltui_posix_deferring = 0;
				volatile int eiffeltui_posix_pending = 0;
					/* Counts SIGCONTs; the driver compares it with the count it accounted for,
					 * so a continue can never be handled twice (a flag could be cleared
					 * before the handler of the continue that ended our own stop ran). */
				volatile sig_atomic_t eiffeltui_posix_continue_count = 0;
					/* Has the application set the tty up (raw mode, escape sequences) since it was
					 * last restored? The SIGTSTP handler restores only then: after a stop, a job
					 * continued in the background must leave the shell's tty alone (review finding M9). */
				volatile sig_atomic_t eiffeltui_posix_tty_taken = 0;
					/* Did the SIGTSTP handler restore the tty since the application last set it
					 * up, restored it, or took note of the continue? Then `c_posix_write_output'
					 * drops what is left of the frame that the stop interrupted (review M11). */
				volatile sig_atomic_t eiffeltui_posix_output_blocked = 0;
					/* Did the application push the terminal's window title (XTWINOPS 22, P2 T2)
					 * without popping it? The handlers then pop it after the reset, and the
					 * SIGTSTP handler clears it: the application pushes again on resume. */
				volatile sig_atomic_t eiffeltui_posix_title_pushed = 0;

					/* Input read ahead by `c_posix_read_char' (input thread only). */
				unsigned char eiffeltui_posix_input [4096];
				int eiffeltui_posix_input_pos = 0;
				int eiffeltui_posix_input_len = 0;

				void eiffeltui_posix_save (void)
				{
					if (!eiffeltui_posix_saved && tcgetattr (STDIN_FILENO, &eiffeltui_posix_orig) == 0) {
						eiffeltui_posix_saved = 1;
					}
				}

				void eiffeltui_posix_restore_modes (void)
				{
					if (eiffeltui_posix_saved) {
						tcsetattr (STDIN_FILENO, TCSAFLUSH, &eiffeltui_posix_orig);
					}
						/* TCSAFLUSH drops unread input; drop what was read ahead too. */
					eiffeltui_posix_input_pos = 0;
					eiffeltui_posix_input_len = 0;
				}

				static void eiffeltui_posix_write_reset (void)
				{
					static const char l_reset [] =
						"\x1b[<u\x1b[?1000l\x1b[?1002l\x1b[?1003l\x1b[?1006l\x1b[?2004l\x1b[?1004l\x1b[0m\x1b[0 q\x1b[?25h\x1b[?1049l";
					static const char l_pop_title [] = "\x1b[23;0t";
					ssize_t l_ignored = write (STDOUT_FILENO, l_reset, sizeof (l_reset) - 1);
					if (eiffeltui_posix_title_pushed) {
						l_ignored = write (STDOUT_FILENO, l_pop_title, sizeof (l_pop_title) - 1);
						eiffeltui_posix_title_pushed = 0;
					}
					(void) l_ignored;
				}

				static void eiffeltui_posix_signal_handler (int a_sig)
				{
						/* Only async-signal-safe calls: write, tcsetattr, signal, raise. */
					if (a_sig != SIGTERM && eiffeltui_posix_deferring
						&& __sync_bool_compare_and_swap (&eiffeltui_posix_pending, 0, a_sig)
							/* Check again: if the loop stopped deferring meanwhile, it may have
							 * looked for a request before this one was recorded. */
						&& (__sync_synchronize (), eiffeltui_posix_deferring)) {
							/* Recorded: the application loop restores the tty, then raises it again. */
						return;
					}
						/* Not deferred, SIGTERM, or a second request: restore here, unless the
						 * tty is not ours to restore (after a stop, waiting in the background). */
					if (eiffeltui_posix_tty_taken) {
						eiffeltui_posix_write_reset ();
						eiffeltui_posix_restore_modes ();
					}
					signal (a_sig, SIG_DFL);
					raise (a_sig);
				}

				static void eiffeltui_posix_sigtstp_handler (int a_sig);

				static void eiffeltui_posix_install_sigtstp_handler (void)
				{
						/* No SA_NODEFER: a second TSTP while the tty is being restored
						 * waits until the handler unblocks it. */
					struct sigaction l_action;
					memset (&l_action, 0, sizeof (l_action));
					l_action.sa_handler = eiffeltui_posix_sigtstp_handler;
					sigemptyset (&l_action.sa_mask);
					sigaction (SIGTSTP, &l_action, NULL);
				}

				static void eiffeltui_posix_sigtstp_handler (int a_sig)
				{
						/* Leave alt screen / show cursor / restore cooked, then stop.
						 * The process goes on after this, and the input thread may be
						 * inside `c_posix_read_char': keep its read-ahead, and let
						 * pending input wait (TCSADRAIN, not TCSAFLUSH).
						 * Only async-signal-safe calls; errno is kept for the interrupted code. */
					int l_errno = errno;
					sigset_t l_tstp;
					(void) a_sig;
					if (eiffeltui_posix_tty_taken) {
							/* First, so that a frame being written stops as soon as possible. */
						eiffeltui_posix_output_blocked = 1;
						eiffeltui_posix_write_reset ();
						if (eiffeltui_posix_saved) {
							tcsetattr (STDIN_FILENO, TCSADRAIN, &eiffeltui_posix_orig);
						}
						eiffeltui_posix_tty_taken = 0;
					}
					signal (SIGTSTP, SIG_DFL);
						/* SIGTSTP is blocked while this handler runs: raised as is, it would
						 * stay pending and run the reinstalled handler again on return, forever
						 * (review finding M8). Unblocked, its default action stops us here. */
					sigemptyset (&l_tstp);
					sigaddset (&l_tstp, SIGTSTP);
					pthread_sigmask (SIG_UNBLOCK, &l_tstp, NULL);
					raise (SIGTSTP);
						/* Continued (SIGCONT): reinstall this handler so a later TSTP works
						 * again. The return restores the mask of the interrupted code, and the
						 * application loop sets the terminal up again (`has_resume_request').
						 * Until the reinstall, SIGTSTP keeps SIG_DFL process-wide, so a TSTP
						 * in that gap stops us without the reset. That is harmless: the tty is
						 * still cooked here, since the loop has not set it up again yet. */
					eiffeltui_posix_install_sigtstp_handler ();
					errno = l_errno;
				}

				static void eiffeltui_posix_sigcont_handler (int a_sig)
				{
					(void) a_sig;
						/* Only this handler writes the counter, and SIGCONT is blocked
						 * while it runs, so the increment cannot be lost. */
					eiffeltui_posix_continue_count = eiffeltui_posix_continue_count + 1;
				}

					/* Does our process group own the terminal on stdin (review finding M9)?
					 * Without a terminal (tcgetpgrp fails) there is nothing to wait for. */
				int eiffeltui_posix_is_foreground (void)
				{
					pid_t l_group = tcgetpgrp (STDIN_FILENO);
					return l_group == -1 || l_group == getpgrp ();
				}

					/* Write the application's output, retrying partial writes, and stop as
					 * soon as the SIGTSTP handler blocks it (review finding M11). */
				void eiffeltui_posix_write_output (const char *a_bytes, size_t a_count)
				{
					ssize_t l_written;
					while (a_count > 0 && !eiffeltui_posix_output_blocked) {
						l_written = write (STDOUT_FILENO, a_bytes, a_count);
						if (l_written > 0) {
							a_bytes += l_written;
							a_count -= (size_t) l_written;
						} else if (!(l_written < 0 && errno == EINTR)) {
							break;
						}
					}
				}

				void eiffeltui_posix_suspend_process (void)
				{
						/* Called after Eiffel restored the tty; just stop until continued. */
					signal (SIGTSTP, SIG_DFL);
					raise (SIGTSTP);
					eiffeltui_posix_install_sigtstp_handler ();
				}

				void eiffeltui_posix_install_signal_handlers (void)
				{
					struct sigaction l_action;
					if (eiffeltui_posix_handlers_installed) return;
					memset (&l_action, 0, sizeof (l_action));
					l_action.sa_handler = eiffeltui_posix_signal_handler;
					sigemptyset (&l_action.sa_mask);
					sigaction (SIGINT, &l_action, NULL);
					sigaction (SIGTERM, &l_action, NULL);
					sigaction (SIGHUP, &l_action, NULL);
					sigaction (SIGQUIT, &l_action, NULL);
					eiffeltui_posix_install_sigtstp_handler ();
					memset (&l_action, 0, sizeof (l_action));
					l_action.sa_handler = eiffeltui_posix_sigcont_handler;
					sigemptyset (&l_action.sa_mask);
					sigaction (SIGCONT, &l_action, NULL);
					eiffeltui_posix_handlers_installed = 1;
				}

				static void eiffeltui_posix_runtime_epilogue (void)
				{
			]"
		end

	c_posix_get_console_size (a_cols, a_rows: TYPED_POINTER [INTEGER]): BOOLEAN
			-- Query window size via ioctl(TIOCGWINSZ) on stdout, falling back to stdin.
		external
			"C inline use <sys/ioctl.h>, <unistd.h>"
		alias
			"[
				struct winsize ws;
				if ((ioctl (STDOUT_FILENO, TIOCGWINSZ, &ws) == 0 || ioctl (STDIN_FILENO, TIOCGWINSZ, &ws) == 0)
					&& ws.ws_col > 0 && ws.ws_row > 0)
				{
					*(EIF_INTEGER *) $a_cols = ws.ws_col;
					*(EIF_INTEGER *) $a_rows = ws.ws_row;
					return EIF_TRUE;
				}
				return EIF_FALSE;
			]"
		end

	c_posix_enable_raw_mode: BOOLEAN
			-- Put the tty in raw mode (equivalent of cfmakeraw), saving the original termios first.
		external
			"C inline use <termios.h>, <unistd.h>, <signal.h>"
		alias
			"[
				extern void eiffeltui_posix_save (void);
				extern volatile sig_atomic_t eiffeltui_posix_tty_taken;
				extern volatile sig_atomic_t eiffeltui_posix_output_blocked;
				struct termios l_raw;
					/* Escape sequences follow even without a tty: the SIGTSTP handler resets them. */
				eiffeltui_posix_tty_taken = 1;
				eiffeltui_posix_output_blocked = 0;
				if (!isatty (STDIN_FILENO)) return EIF_TRUE; /* Not a tty: nothing to change. */
				eiffeltui_posix_save ();
				if (tcgetattr (STDIN_FILENO, &l_raw) != 0) return EIF_FALSE;
				l_raw.c_iflag &= ~(IGNBRK | BRKINT | PARMRK | ISTRIP | INLCR | IGNCR | ICRNL | IXON);
				l_raw.c_oflag &= ~OPOST;
				l_raw.c_lflag &= ~(ECHO | ECHONL | ICANON | ISIG | IEXTEN);
				l_raw.c_cflag &= ~(CSIZE | PARENB);
				l_raw.c_cflag |= CS8;
				l_raw.c_cc [VMIN] = 0;
				l_raw.c_cc [VTIME] = 0;
				return (EIF_BOOLEAN) (tcsetattr (STDIN_FILENO, TCSAFLUSH, &l_raw) == 0);
			]"
		end

	c_posix_disable_raw_mode: BOOLEAN
			-- Reset the tty to the saved original termios settings.
		external
			"C inline use <termios.h>, <unistd.h>, <signal.h>"
		alias
			"[
				extern struct termios eiffeltui_posix_orig;
				extern int eiffeltui_posix_saved;
				extern int eiffeltui_posix_input_pos;
				extern int eiffeltui_posix_input_len;
				extern volatile sig_atomic_t eiffeltui_posix_tty_taken;
				extern volatile sig_atomic_t eiffeltui_posix_output_blocked;
				struct termios l_cooked;
				eiffeltui_posix_tty_taken = 0;
				eiffeltui_posix_output_blocked = 0;
				if (!isatty (STDIN_FILENO)) return EIF_TRUE;
					/* TCSAFLUSH drops unread input; drop what was read ahead too. */
				eiffeltui_posix_input_pos = 0;
				eiffeltui_posix_input_len = 0;
				if (eiffeltui_posix_saved) {
					return (EIF_BOOLEAN) (tcsetattr (STDIN_FILENO, TCSAFLUSH, &eiffeltui_posix_orig) == 0);
				}
				if (tcgetattr (STDIN_FILENO, &l_cooked) != 0) return EIF_FALSE;
				l_cooked.c_lflag |= (ICANON | ECHO | ISIG);
				l_cooked.c_oflag |= OPOST;
				return (EIF_BOOLEAN) (tcsetattr (STDIN_FILENO, TCSAFLUSH, &l_cooked) == 0);
			]"
		end

	c_posix_restore_modes
			-- Restore the saved original termios.
		external
			"C inline use <termios.h>, <unistd.h>"
		alias
			"[
				extern void eiffeltui_posix_restore_modes (void);
				eiffeltui_posix_restore_modes ();
			]"
		end

	c_posix_read_char (a_timeout_ms: INTEGER): INTEGER
			-- Next input byte, waiting at most `a_timeout_ms` with poll(). Input is read in
			-- blocks of up to 4 KB, and the bytes read ahead are returned by the next calls
			-- without a system call.
		external
			"C blocking inline use <poll.h>, <unistd.h>"
		alias
			"[
				extern unsigned char eiffeltui_posix_input [4096];
				extern int eiffeltui_posix_input_pos;
				extern int eiffeltui_posix_input_len;
				struct pollfd pfd;
				int pr;
				if (eiffeltui_posix_input_pos < eiffeltui_posix_input_len) {
					return (EIF_INTEGER) eiffeltui_posix_input [eiffeltui_posix_input_pos++];
				}
				pfd.fd = STDIN_FILENO;
				pfd.events = POLLIN;
				pfd.revents = 0;
				pr = poll (&pfd, 1, (int) $a_timeout_ms);
				if (pr > 0 && (pfd.revents & POLLIN)) {
					ssize_t n = read (STDIN_FILENO, eiffeltui_posix_input, sizeof (eiffeltui_posix_input));
					if (n > 0) {
						eiffeltui_posix_input_pos = 1;
						eiffeltui_posix_input_len = (int) n;
						return (EIF_INTEGER) eiffeltui_posix_input [0];
					}
				}
				if (pr > 0) {
						/* EOF or hang-up: honour the timeout instead of spinning. */
					poll (NULL, 0, (int) $a_timeout_ms);
				}
				return -1;
			]"
		end

	c_posix_is_deferring: BOOLEAN
			-- Are signals deferred?
		external
			"C inline use <signal.h>"
		alias
			"[
				extern volatile sig_atomic_t eiffeltui_posix_deferring;
				return (EIF_BOOLEAN) (eiffeltui_posix_deferring != 0);
			]"
		end

	c_posix_set_deferring (a_on: BOOLEAN)
			-- Defer signals (`a_on`) or not.
		external
			"C inline use <signal.h>"
		alias
			"[
				extern volatile sig_atomic_t eiffeltui_posix_deferring;
				eiffeltui_posix_deferring = $a_on ? 1 : 0;
				__sync_synchronize ();
			]"
		end

	c_posix_pending: INTEGER
			-- Number of the deferred signal, or 0
		external
			"C inline use <signal.h>"
		alias
			"[
				extern volatile int eiffeltui_posix_pending;
				return (EIF_INTEGER) __sync_fetch_and_add (&eiffeltui_posix_pending, 0);
			]"
		end

	c_posix_discard
			-- Forget the deferred signal.
		external
			"C inline use <signal.h>"
		alias
			"[
				extern volatile int eiffeltui_posix_pending;
				__sync_lock_test_and_set (&eiffeltui_posix_pending, 0);
			]"
		end

	c_posix_finish
			-- Raise the deferred signal with its default action; exit if that did not end the process.
		external
			"C inline use <signal.h>, <unistd.h>"
		alias
			"[
				extern volatile int eiffeltui_posix_pending;
				int l_sig = __sync_fetch_and_add (&eiffeltui_posix_pending, 0);
				signal (l_sig, SIG_DFL);
				raise (l_sig);
				_exit (128 + l_sig);
			]"
		end

	c_posix_install_signal_handlers
			-- Register the restore-on-signal handlers (once per process).
		external
			"C inline use <signal.h>"
		alias
			"[
				extern void eiffeltui_posix_install_signal_handlers (void);
				eiffeltui_posix_install_signal_handlers ();
			]"
		end

	c_posix_continue_count: INTEGER
			-- Number of SIGCONTs received so far
		external
			"C inline use <signal.h>"
		alias
			"[
				extern volatile sig_atomic_t eiffeltui_posix_continue_count;
				return (EIF_INTEGER) eiffeltui_posix_continue_count;
			]"
		end

	c_posix_is_foreground: BOOLEAN
			-- Does the process group own the terminal on stdin (or is there none)?
		external
			"C inline use <unistd.h>"
		alias
			"[
				extern int eiffeltui_posix_is_foreground (void);
				return (EIF_BOOLEAN) (eiffeltui_posix_is_foreground () != 0);
			]"
		end

	c_posix_write_output (a_bytes: POINTER; a_count: INTEGER)
			-- Write `a_count` bytes at `a_bytes` to standard output, retrying partial writes,
			-- and stop as soon as the SIGTSTP handler blocks the output.
		external
			"C inline use <stddef.h>"
		alias
			"[
				extern void eiffeltui_posix_write_output (const char *a_bytes, size_t a_count);
				eiffeltui_posix_write_output ((const char *) $a_bytes, (size_t) $a_count);
			]"
		end

	c_posix_allow_output
			-- Let `c_posix_write_output' write again.
		external
			"C inline use <signal.h>"
		alias
			"[
				extern volatile sig_atomic_t eiffeltui_posix_output_blocked;
				eiffeltui_posix_output_blocked = 0;
			]"
		end

	c_posix_output_blocked: BOOLEAN
			-- Does `c_posix_write_output' drop its bytes?
		external
			"C inline use <signal.h>"
		alias
			"[
				extern volatile sig_atomic_t eiffeltui_posix_output_blocked;
				return (EIF_BOOLEAN) (eiffeltui_posix_output_blocked != 0);
			]"
		end

	c_posix_title_pushed: BOOLEAN
			-- Is the terminal's title pushed, for the handlers?
		external
			"C inline use <signal.h>"
		alias
			"[
				extern volatile sig_atomic_t eiffeltui_posix_title_pushed;
				return (EIF_BOOLEAN) (eiffeltui_posix_title_pushed != 0);
			]"
		end

	c_posix_set_title_pushed (a_pushed: BOOLEAN)
			-- Record whether the terminal's title is pushed (`a_pushed`).
		external
			"C inline use <signal.h>"
		alias
			"[
				extern volatile sig_atomic_t eiffeltui_posix_title_pushed;
				eiffeltui_posix_title_pushed = $a_pushed ? 1 : 0;
			]"
		end

	c_posix_suspend_process
			-- Stop via SIGTSTP until continued.
		external
			"C inline use <signal.h>"
		alias
			"[
				extern void eiffeltui_posix_suspend_process (void);
				eiffeltui_posix_suspend_process ();
			]"
		end

end
