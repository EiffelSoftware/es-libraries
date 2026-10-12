note
	description: "Abstract base class for all PDF objects. Implements visitor pattern for serialization and validation."
	date: "$Date$"
	revision: "$Revision$"

deferred class
	PDF_OBJECT

inherit
	PDF_WITH_LOGGING

feature -- Visitor Pattern

	accept (a_visitor: PDF_VISITOR)
			-- Accept visitor for processing this object.
		deferred
		end

end
