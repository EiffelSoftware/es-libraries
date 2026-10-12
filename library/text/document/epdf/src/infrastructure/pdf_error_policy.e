note
	description: "[
		Defines error handling policies for PDF processing.
		Supports both strict ISO compliance mode and permissive mode for real-world PDFs.
		As per plan.md Section 0.2: Strict ISO Mode vs Permissive Mode (Default).
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_ERROR_POLICY

create
	make_permissive,
	make_strict

feature -- Initialization

	make_permissive
			-- Create with permissive error handling (default).
			-- Tolerates minor violations common in real-world PDFs.
		do
			strict_mode := False
		ensure
			permissive: not strict_mode
		end

	make_strict
			-- Create with strict ISO compliance mode.
			-- Rejects any violations of ISO 32000-1:2008.
		do
			strict_mode := True
		ensure
			strict: strict_mode
		end

feature -- Access

	strict_mode: BOOLEAN
			-- Is strict ISO compliance mode enabled?

feature -- Status Report

	should_reject_minor_violation: BOOLEAN
			-- Should minor spec violations be rejected?
		do
			Result := strict_mode
		ensure
			definition: Result = strict_mode
		end

	should_reject_missing_optional_entry: BOOLEAN
			-- Should missing optional dictionary entries be rejected?
		do
			Result := strict_mode
		ensure
			definition: Result = strict_mode
		end

	should_reject_extra_whitespace: BOOLEAN
			-- Should extra whitespace be rejected?
		do
			Result := strict_mode
		ensure
			definition: Result = strict_mode
		end

feature -- Element Change

	set_strict_mode (enable: BOOLEAN)
			-- Enable or disable strict mode.
		do
			strict_mode := enable
		ensure
			mode_set: strict_mode = enable
		end

feature -- Error Reporting

	report_error (message: READABLE_STRING_GENERAL)
			-- Report an error according to current policy.
			-- Accepts any string type for internationalization support.
		require
			message_not_empty: not message.is_empty
		do
			if strict_mode then
					-- In strict mode, fail immediately
				(create {EXCEPTIONS}).raise ("PDF Error (Strict Mode): " + message.to_string_8)
			else
					-- In permissive mode, just log (for now)
				io.put_string ("PDF Warning: " + message.to_string_8 + "%N")
			end
		end

	report_minor_violation (message: READABLE_STRING_GENERAL)
			-- Report a minor spec violation.
			-- Accepts any string type for internationalization support.
		require
			message_not_empty: not message.is_empty
		do
			if should_reject_minor_violation then
				report_error (message)
			else
				io.put_string ("PDF Minor Violation (Ignored): " + message.to_string_8 + "%N")
			end
		end

end
