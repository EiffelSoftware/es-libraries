note
	description: "Represents a PDF boolean object (true or false)."
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_BOOLEAN

inherit
	PDF_OBJECT

create
	make

feature -- Initialization

	make (a_value: BOOLEAN)
			-- Create a PDF boolean with the given value.
		do
			value := a_value
		ensure
			value_set: value = a_value
		end

feature -- Access

	value: BOOLEAN
			-- The boolean value

feature -- Visitor Pattern

	accept (a_visitor: PDF_VISITOR)
			-- Accept visitor for processing.
		do
			a_visitor.visit_boolean (Current)
		end

feature -- Conversion

	to_pdf_string: STRING_8
			-- Convert to PDF format ("true" or "false").
			-- Per ISO 32000-1:2008 §7.3.2, boolean keywords are 7-bit ASCII.
		do
			if value then
				Result := "true"
			else
				Result := "false"
			end
		ensure
			valid_result: Result.is_equal ("true") or Result.is_equal ("false")
		end

end
