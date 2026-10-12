note
	description: "[
		Represents the PDF null object.
		The null object has a type and value that are unequal to those of any other object.
		ISO 32000-1:2008 Section 7.3.9: There shall be only one object of type null, 
		denoted by the keyword null, and having a value that is unequal to any other object.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_NULL

inherit
	PDF_OBJECT

create
	default_create,
	make

feature -- Initialization

	make
			-- Create a null object.
		do
			-- Nothing to initialize
		end

feature -- Visitor Pattern

	accept (a_visitor: PDF_VISITOR)
			-- Accept visitor for processing this null object.
		do
			a_visitor.visit_null
		end

feature -- Access

	to_pdf_string: STRING_8
		-- PDF representation of null object.
		-- Per ISO 32000-1:2008 §7.3.9, null is a 7-bit ASCII keyword.
	do
		Result := "null"
	ensure
		result_is_null: Result.is_equal ("null")
	end

end
