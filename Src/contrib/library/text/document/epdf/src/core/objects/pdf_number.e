note
	description: "Represents a PDF numeric object (integer or real)."
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_NUMBER

inherit
	PDF_OBJECT

create
	make,
	make_integer,
	make_real

feature -- Initialization

	make (a_value: REAL_64)
			-- Create a PDF number from a real value.
			-- Automatically determines if value is an integer.
		do
			real_value := a_value
			int_value := a_value.truncated_to_integer
			is_integer := (a_value = a_value.truncated_to_integer.to_double)
		ensure
			value_set: real_value = a_value
		end

	make_integer (an_integer: INTEGER)
			-- Create a PDF number from an integer.
		do
			int_value := an_integer
			real_value := an_integer.to_double
			is_integer := True
		ensure
			is_integer: is_integer
			value_set: int_value = an_integer
		end

	make_real (a_real: REAL_64)
			-- Create a PDF number from a real.
		do
			real_value := a_real
			int_value := a_real.truncated_to_integer
			is_integer := False
		ensure
			not_integer: not is_integer
			value_set: real_value = a_real
		end

feature -- Access

	int_value: INTEGER
			-- Integer representation

	real_value: REAL_64
			-- Real representation

	is_integer: BOOLEAN
			-- Is this number an integer?

feature -- Visitor Pattern

	accept (a_visitor: PDF_VISITOR)
			-- Accept visitor for processing.
		do
			a_visitor.visit_number (Current)
		end

feature -- Conversion

	to_pdf_string: STRING_8
		-- Convert to PDF format.
		-- Per ISO 32000-1:2008 §7.3.3, numbers serialize to 7-bit ASCII.
	do
		if is_integer then
			Result := int_value.out
		else
			Result := real_value.out
		end
	ensure
		result_not_empty: not Result.is_empty
	end

end
