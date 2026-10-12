note
	description: "Abstract visitor for processing PDF objects. Concrete visitors implement serialization, validation, etc."
	date: "$Date$"
	revision: "$Revision$"

deferred class
	PDF_VISITOR

feature -- Visiting

	visit_dictionary (a_dictionary: PDF_DICTIONARY)
			-- Visit a PDF dictionary object.
		deferred
		end

	visit_array (an_array: PDF_ARRAY)
			-- Visit a PDF array object.
		deferred
		end

	visit_name (a_name: PDF_NAME)
			-- Visit a PDF name object.
		deferred
		end

	visit_string (a_string: PDF_STRING)
			-- Visit a PDF string object.
		deferred
		end

	visit_number (a_number: PDF_NUMBER)
			-- Visit a PDF number object.
		deferred
		end

	visit_boolean (a_boolean: PDF_BOOLEAN)
			-- Visit a PDF boolean object.
		deferred
		end

	visit_indirect (an_indirect: PDF_INDIRECT_OBJECT)
			-- Visit a PDF indirect object.
		deferred
		end

	visit_reference (a_reference: PDF_REFERENCE)
			-- Visit a PDF indirect reference object.
		deferred
		end

	visit_stream (a_stream: PDF_STREAM)
			-- Visit a PDF stream object.
		deferred
		end

	visit_null
			-- Visit a PDF null object.
		deferred
		end

end
