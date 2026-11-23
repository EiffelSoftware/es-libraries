note
	description: "[
		Deferred base class for platform console drivers interfacing with host OS console APIs.
		Provides abstraction for Win32 and POSIX terminal control, raw/cooked modes,
		dimensions, non-blocking byte reads, and panic restoration.
		Implementations live in library/platform/<os>/; the ECF compiles exactly one of them,
		and that cluster's TERMINAL_DRIVER is the default driver of ANSI_TERMINAL_BACKEND.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	CONSOLE_DRIVER

feature -- Queries

	console_width: INTEGER
			-- Current console width in columns, or default if unavailable.
		deferred
		ensure
			positive_width: Result > 0
		end

	console_height: INTEGER
			-- Current console height in rows, or default if unavailable.
		deferred
		ensure
			positive_height: Result > 0
		end

	is_raw: BOOLEAN
			-- Is raw input mode currently active?
		deferred
		end

	is_vt_enabled: BOOLEAN
			-- Is virtual terminal escape processing active?
		deferred
		end

	is_mouse_enabled: BOOLEAN
			-- Is mouse event reporting enabled in driver?
		deferred
		end

feature -- Mode Commands

	enable_vt_mode: BOOLEAN
			-- Enable Virtual Terminal processing for ANSI escape sequences.
		deferred
		end

	enable_raw_mode: BOOLEAN
			-- Enable raw terminal input mode (disable echo and line buffering).
		deferred
		ensure
			raw_on_success: Result implies is_raw
		end

	disable_raw_mode: BOOLEAN
			-- Restore normal cooked terminal input mode.
		deferred
		ensure
			cooked_on_success: Result implies not is_raw
		end

	enable_mouse: BOOLEAN
			-- Enable mouse event capture (disabling quick-edit mode on Windows).
		deferred
		ensure
			mouse_on_success: Result implies is_mouse_enabled
		end

	disable_mouse: BOOLEAN
			-- Restore default mouse behavior.
		deferred
		ensure
			mouse_disabled_on_success: Result implies not is_mouse_enabled
		end

	is_keyboard_enhancement_enabled: BOOLEAN
			-- Is extended keyboard reporting (progressive enhancement / key release & repeat) active?
		deferred
		end

	provides_keyboard_enhancement: BOOLEAN
			-- Does this driver produce the enhanced key events (release, repeat) itself, from
			-- the console's own key records, whatever the terminal supports? Then the terminal
			-- need not be asked whether it speaks the Kitty keyboard protocol
			-- ({TUI_APPLICATION}.set_keyboard_enhancement_if_supported). False here: the
			-- events come from the terminal.
		do
			Result := False
		end

	enable_keyboard_enhancement
			-- Enable extended keyboard reporting (key release and repeat).
		deferred
		ensure
			enhancement_enabled: is_keyboard_enhancement_enabled
		end

	disable_keyboard_enhancement
			-- Disable extended keyboard reporting.
		deferred
		ensure
			enhancement_disabled: not is_keyboard_enhancement_enabled
		end

	restore_modes
			-- Restore original terminal modes, code pages, and settings saved at launch.
		deferred
		ensure
			cooked_restored: not is_raw
			mouse_restored: not is_mouse_enabled
			keyboard_enhancement_restored: not is_keyboard_enhancement_enabled
		end

feature -- Input & Resize

	input_claim: CONSOLE_INPUT_CLAIM
			-- Right to read input from this console, held by at most one reader at a time.
			-- Take it before calling `read_char_with_timeout` from a reader that can run while
			-- another one does (see CONSOLE_INPUT_CLAIM). One per driver object here; drivers
			-- of a process-wide console redefine it to share one claim per process.
		do
			Result := own_input_claim
		end

	is_input_claimed: BOOLEAN
			-- Is a reader reading this console's input?
		do
			Result := input_claim.is_held
		end

	read_char_with_timeout (a_timeout_ms: INTEGER): INTEGER
			-- Read next input byte from console with timeout in milliseconds.
			-- Text is delivered UTF-8 encoded, one byte per call, whatever the platform.
			-- Returns the byte (0..255), or -1 only when no input arrived within
			-- `a_timeout_ms` (or on error): -1 is what lets callers flush a lone ESC.
		require
			non_negative_timeout: a_timeout_ms >= 0
		deferred
		ensure
			valid_byte_or_timeout: Result >= -1 and Result <= 255
		end

	poll_resize (a_cols, a_rows: TYPED_POINTER [INTEGER]): BOOLEAN
			-- Query if console size has changed since last poll.
			-- If changed, writes new dimensions to `a_cols` and `a_rows` and returns True.
		require
			cols_valid: a_cols /= default_pointer
			rows_valid: a_rows /= default_pointer
		deferred
		end

	install_ctrl_handler
			-- Install process signal/Ctrl+C handler to restore console on unexpected termination.
		deferred
		end

feature -- Suspend / resume

	supports_suspend_resume: BOOLEAN
			-- Can this platform suspend the process (POSIX SIGTSTP) and resume it?
		do
			Result := False
		end

	has_resume_request: BOOLEAN
			-- Was the process continued (SIGCONT) after a stop that `suspend_process` did not
			-- make, e.g. `kill -TSTP`? The application loop then sets the terminal up again,
			-- once `is_foreground` holds.
		do
			Result := False
		end

	is_foreground: BOOLEAN
			-- Does the process own the terminal (POSIX: is its process group the terminal's
			-- foreground group)? True where there is no job control (Windows) or no terminal.
			-- A job continued in the background (`bg`, `kill -CONT`) must leave the shell's
			-- terminal alone: after a stop, the application loop sets the terminal up again
			-- only once this holds, as `fg` makes it.
		do
			Result := True
		end

	clear_resume_request
			-- Forget the continues received so far, and let `write_output` write again.
			-- There is no `not has_resume_request` postcondition: a signal may arrive right
			-- after, and it is a new request.
		do
		end

	suspend_process
			-- Stop the process until continued (POSIX SIGTSTP). No-op on Windows.
			-- Caller must restore the terminal before calling and re-enter after return
			-- (once `is_foreground` holds: `bg` continues the process in the background).
			-- The continue that ends this stop does not count as a resume request, even
			-- when its handler runs after this returns.
		do
		end

feature -- Output

	writes_output: BOOLEAN
			-- Does `write_output` write the backend's output, instead of standard output?
			-- POSIX: a stop from outside can come in the middle of a frame, and the rest of
			-- that frame must not be written once the terminal was handed back (review M11).
		do
			Result := False
		end

	write_output (a_bytes: STRING_8)
			-- Write `a_bytes` to the console, unless a stop from outside handed the terminal
			-- back since it was last set up or restored, or since `clear_resume_request`:
			-- then they are dropped.
		require
			writes: writes_output
		do
		end

feature -- Clipboard read

	provides_clipboard_read: BOOLEAN
			-- Does this driver read the system clipboard itself (`read_clipboard_text`)? Then
			-- {TUI_APPLICATION}.read_clipboard asks the driver instead of the terminal (OSC 52),
			-- and delivers its answer the same way (P2b K4). False here: the terminal is asked.
		do
			Result := False
		end

	read_clipboard_text (a_max_count: INTEGER): detachable STRING_32
			-- The clipboard's text, read now, or Void; `last_clipboard_status` says why:
			-- `Status_text` with a Void result for an empty clipboard or one with no text,
			-- `Status_unavailable` when it could not be read, `Status_too_large` when its text
			-- is longer than `a_max_count` (then nothing is copied). The text is not sanitised.
			-- Nothing here: only a driver that `provides_clipboard_read` reads.
		require
			provides: provides_clipboard_read
			positive_max: a_max_count > 0
		do
			last_clipboard_status := {CLIPBOARD_EVENT}.Status_unavailable
		ensure
			valid_status: {CLIPBOARD_EVENT}.is_valid_status (last_clipboard_status)
				and last_clipboard_status /= {CLIPBOARD_EVENT}.Status_invalid
			text_only_with_status_text: Result /= Void implies last_clipboard_status = {CLIPBOARD_EVENT}.Status_text
			bounded: attached Result as r implies r.count <= a_max_count
			not_empty: attached Result as r implies not r.is_empty
		end

	last_clipboard_status: INTEGER
			-- Status of the last `read_clipboard_text` (a {CLIPBOARD_EVENT} status constant),
			-- or 0 before the first

	clipboard_answer (a_selection: CHARACTER_32; a_max_count: INTEGER): CLIPBOARD_EVENT
			-- The answer to a read of `a_selection`, from `read_clipboard_text (a_max_count)`:
			-- the text (empty for an empty clipboard), `Status_unavailable` or
			-- `Status_too_large`. The selection is the one asked for, whatever the platform
			-- reads for it.
		require
			provides: provides_clipboard_read
			positive_max: a_max_count > 0
		do
			if attached read_clipboard_text (a_max_count) as l_text then
				create Result.make_owned_text (a_selection, l_text)
			elseif last_clipboard_status = {CLIPBOARD_EVENT}.Status_text then
				create Result.make_text (a_selection, "")
			else
				create Result.make (a_selection, last_clipboard_status)
			end
		ensure
			selection_kept: Result.selection = a_selection
			same_status: Result.status = last_clipboard_status
			bounded: Result.text.count <= a_max_count
		end

feature -- Window title

	is_title_pushed: BOOLEAN
			-- Did the backend save the terminal's window title on its stack (XTWINOPS
			-- `CSI 22 ; 0 t`) without popping it since? The platform handlers that restore
			-- the terminal themselves then pop it too (`CSI 23 ; 0 t`), and a stop's handler
			-- clears it (POSIX).
		do
			Result := title_pushed
		end

	set_title_pushed (a_pushed: BOOLEAN)
			-- Record whether the terminal's title is pushed (set by the backend; P2 T2).
		do
			title_pushed := a_pushed
		ensure
			set: is_title_pushed = a_pushed
		end

feature -- Termination requests

	is_deferring_termination: BOOLEAN
			-- Are termination requests recorded for the application loop instead of handled at
			-- once? While an application draws, a handler that writes the terminal reset itself
			-- would mix it with the frame being written, and race the loop's console mode
			-- changes (review finding C5). Deferred requests: on Windows, Ctrl+C, Ctrl+Break
			-- and console close / logoff / shutdown; on POSIX, SIGINT, SIGQUIT and SIGHUP
			-- (SIGTERM is always handled at once: a signal handler cannot wait for the loop).
			-- A second request while one is pending is always handled at once, so a stuck loop
			-- cannot keep the terminal from being restored.
		deferred
		end

	set_deferring_termination (a_on: BOOLEAN)
			-- Record termination requests for the application loop (`a_on`), or handle them at
			-- once again. A request recorded before the loop stops stays pending.
		deferred
		ensure
			set: is_deferring_termination = a_on
		end

	has_termination_request: BOOLEAN
			-- Is a deferred termination request waiting? (Set by a handler on another thread.)
		deferred
		end

	termination_request_code: INTEGER
			-- Platform code of the pending request: the Ctrl event type on Windows, the signal
			-- number on POSIX
		require
			pending: has_termination_request
		deferred
		end

	discard_termination_request
			-- Forget the pending request.
		deferred
		ensure
			none_pending: not has_termination_request
		end

	finish_termination
			-- End the process as the pending request's default action would, now that the
			-- application has restored the terminal. The platform drivers do not return.
		require
			pending: has_termination_request
			not_deferring: not is_deferring_termination
		deferred
		end

feature {NONE} -- Window title

	title_pushed: BOOLEAN
			-- Default `is_title_pushed`, for drivers whose handlers do not restore the
			-- terminal; the platform drivers keep it in C, where their handlers read it

feature {NONE} -- Input claim

	own_input_claim: CONSOLE_INPUT_CLAIM
			-- Claim of this driver object, the default `input_claim`
		do
			if attached internal_own_input_claim as l_own_input_claim then
				Result := l_own_input_claim
			else
				create Result.make
				internal_own_input_claim := Result
			end
		end

	internal_own_input_claim: detachable CONSOLE_INPUT_CLAIM
			-- Storage of `own_input_claim`, created on first use (rather than a self-initializing
			-- attribute, which is not initialized when the library is compiled without void safety)

feature -- Constants

	Default_width: INTEGER = 80
			-- Fallback column count

	Default_height: INTEGER = 24
			-- Fallback row count

end
