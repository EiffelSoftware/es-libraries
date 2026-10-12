note
	description: "Represents a PDF name object (e.g., /Type, /Pages). Names are atomic symbols used as keys in dictionaries."
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_NAME

inherit
	PDF_OBJECT

create
	make

feature -- Initialization

	make (a_value: READABLE_STRING_GENERAL)
			-- Create a PDF name with the given value.
			-- Value should not include the leading slash.
			-- Per ISO 32000-1:2008 §7.3.5, PDF names are 7-bit ASCII.
		require
			value_not_empty: not a_value.is_empty
		do
			value := a_value.to_string_8
		ensure
			value_set: value.same_string_general (a_value)
		end

feature -- Access

	value: STRING_8
			-- The name value (without leading slash).
			-- Per ISO 32000-1:2008 §7.3.5, names are 7-bit ASCII.

feature -- Visitor Pattern

	accept (a_visitor: PDF_VISITOR)
			-- Accept visitor for processing.
		do
			a_visitor.visit_name (Current)
		end

feature -- Conversion

	to_pdf_string: STRING_8
			-- Convert to PDF format (with leading slash).
			-- Per ISO 32000-1:2008 §7.3.5, names serialize to 7-bit ASCII.
		do
			create Result.make (value.count + 1)
			Result.append_character ('/')
			Result.append (value)
		ensure
			starts_with_slash: Result.count > 0 and then Result [1] = '/'
		end

invariant
	value_not_empty: not value.is_empty

end
