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

feature {NONE} -- Input claim

	own_input_claim: CONSOLE_INPUT_CLAIM
			-- Claim of this driver object, the default `input_claim`
		attribute
			create Result.make
		end

feature -- Constants

	Default_width: INTEGER = 80
			-- Fallback column count

	Default_height: INTEGER = 24
			-- Fallback row count

end
