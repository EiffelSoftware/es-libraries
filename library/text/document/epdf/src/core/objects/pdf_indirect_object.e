note
	description: "Represents a PDF indirect object. Wraps a PDF object with an object ID for indirect referencing."
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_INDIRECT_OBJECT

inherit
	PDF_OBJECT

create
	make

feature -- Initialization

	make (an_id: PDF_OBJECT_ID; a_value: PDF_OBJECT)
			-- Create an indirect object with given ID and value.
		do
			object_id := an_id
			value := a_value
		ensure
			id_set: object_id = an_id
			value_set: value = a_value
		end

feature -- Access

	object_id: PDF_OBJECT_ID
			-- The object identifier

	value: PDF_OBJECT
			-- The wrapped object

feature -- Visitor Pattern

	accept (a_visitor: PDF_VISITOR)
			-- Accept visitor for processing.
		do
			a_visitor.visit_indirect (Current)
		end

invariant

end
