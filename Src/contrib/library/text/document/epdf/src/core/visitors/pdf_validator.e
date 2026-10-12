note
	description: "[
		Validates PDF objects against ISO 32000-1:2008 specification.
		Checks structural correctness, required entries, valid values, etc.
		Respects error policy for strict vs permissive validation.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_VALIDATOR

inherit
	PDF_VISITOR

create
	make,
	make_with_policy

feature -- Initialization

	make
			-- Create validator with default permissive policy.
		do
			create error_policy.make_permissive
			create errors.make (10)
			is_valid_result := True
		ensure
			policy_permissive: not error_policy.strict_mode
			no_errors: errors.is_empty
			initially_valid: is_valid_result
		end

	make_with_policy (a_policy: PDF_ERROR_POLICY)
			-- Create validator with specific error policy.
		do
			error_policy := a_policy
			create errors.make (10)
			is_valid_result := True
		ensure
			policy_set: error_policy = a_policy
			no_errors: errors.is_empty
			initially_valid: is_valid_result
		end

feature -- Access

	is_valid_result: BOOLEAN
			-- Was last validation successful?

	errors: ARRAYED_LIST [STRING_8]
			-- List of validation errors (ASCII messages).

	error_policy: PDF_ERROR_POLICY
			-- Error handling policy.

feature -- Element Change

	reset
			-- Reset validation state.
		do
			errors.wipe_out
			is_valid_result := True
		ensure
			no_errors: errors.is_empty
			valid: is_valid_result
		end

feature -- Visiting

	visit_dictionary (a_dictionary: PDF_DICTIONARY)
			-- Validate a PDF dictionary.
		do
				-- Basic validation: dictionary should have entries
			if a_dictionary.count = 0 then
				report_minor_issue ("Dictionary has no entries")
			end

				-- Validate all values in dictionary
			across a_dictionary.entries as entry loop
				entry.accept (Current)
			end
		end

	visit_array (an_array: PDF_ARRAY)
			-- Validate a PDF array.
		do
				-- Validate all items in array
			across an_array.items as obj loop
				obj.accept (Current)
			end
		end

	visit_name (a_name: PDF_NAME)
			-- Validate a PDF name.
		do
			-- Name cannot be empty (enforced by PDF_NAME.make precondition)
			-- Future: validate special character encoding per ISO 32000-1:2008 §7.3.5
		end

	visit_string (a_string: PDF_STRING)
			-- Validate a PDF string.
		do
			-- String can be empty, so no validation needed
			-- Future: validate encoding (UTF-16BE with BOM, PDFDocEncoding)
		end

	visit_number (a_number: PDF_NUMBER)
			-- Validate a PDF number.
		do
			-- All numbers are valid in PDF
			-- Future: check for reasonable ranges in specific contexts
		end

	visit_boolean (a_boolean: PDF_BOOLEAN)
			-- Validate a PDF boolean.
		do
			-- All booleans are valid
		end

	visit_indirect (an_indirect: PDF_INDIRECT_OBJECT)
			-- Validate a PDF indirect object.
		do
				-- Validate the wrapped value
			an_indirect.value.accept (Current)
		end

	visit_reference (a_reference: PDF_REFERENCE)
			-- Validate a PDF indirect reference.
		do
			-- References are validated when resolved
			-- Future: check that referenced object exists in document
		end

	visit_stream (a_stream: PDF_STREAM)
			-- Validate a PDF stream object.
		local
			length_obj: detachable PDF_OBJECT
		do
				-- Stream must have /Length entry (ISO 32000-1:2008 §7.3.8)
			length_obj := a_stream.stream_dictionary.item ("Length")
			if length_obj = Void then
				report_error ("Stream missing required /Length entry")
			end

				-- Validate stream dictionary
			a_stream.stream_dictionary.accept (Current)
		end

	visit_null
			-- Validate a PDF null.
		do
			-- Null is always valid
		end

feature {NONE} -- Implementation

	report_error (message: READABLE_STRING_GENERAL)
			-- Report a validation error.
			-- Accepts any string type for internationalization support.
		require
			message_not_empty: not message.is_empty
		local
			msg: STRING_8
		do
			msg := message.to_string_8
			errors.extend (msg)
			is_valid_result := False
			error_policy.report_error (message)
		ensure
			error_recorded: errors.has (message.to_string_8)
			no_longer_valid: not is_valid_result
		end

	report_minor_issue (message: READABLE_STRING_GENERAL)
			-- Report a minor validation issue.
			-- Accepts any string type for internationalization support.
		require
			message_not_empty: not message.is_empty
		do
			if error_policy.should_reject_minor_violation then
				report_error (message)
			else
					-- Record as warning but don't fail validation
				io.put_string ("Validation warning: " + message.to_string_8 + "%N")
			end
		end

invariant
	invalid_has_errors: not is_valid_result implies not errors.is_empty

end
