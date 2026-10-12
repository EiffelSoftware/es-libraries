note
	description: "Represents a PDF indirect reference (e.g., 1 0 R). References point to indirect objects."
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_REFERENCE

inherit
	PDF_OBJECT

create
	make

feature -- Initialization

	make (an_object_id: PDF_OBJECT_ID)
			-- Create a reference to the object with given ID.
		do
			object_id := an_object_id
		ensure
			object_id_set: object_id = an_object_id
		end

feature -- Access

	object_id: PDF_OBJECT_ID
			-- The referenced object's ID

feature -- Visitor Pattern

	accept (a_visitor: PDF_VISITOR)
			-- Accept visitor for processing.
		do
			a_visitor.visit_reference (Current)
		end

feature -- Conversion

	to_pdf_string: STRING_8
		-- Convert to PDF format (e.g., "1 0 R").
		-- Per ISO 32000-1:2008 §7.3.10, references are 7-bit ASCII.
	do
		Result := object_id.to_reference_string
	ensure
		result_not_empty: not Result.is_empty
		ends_with_r: Result.ends_with ("R")
	end

invariant

end
