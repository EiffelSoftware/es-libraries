note
	description: "[
		Base class for PDF XObjects (external objects).
		XObjects are self-contained graphical content that can be referenced
		from content streams using the Do operator.
		
		Per ISO 32000-1:2008 §8.8:
		- XObjects are stream objects with /Type /XObject
		- Subtypes: Image (§8.9), Form (§8.10), PostScript (deprecated)
	]"
	spec_reference: "ISO 32000-1:2008 Section 8.8 External Objects"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	PDF_XOBJECT

inherit
	PDF_STREAM
		redefine
			make_with_dictionary
		end

feature -- Initialization

	make_with_dictionary (a_dictionary: PDF_DICTIONARY; a_content: STRING_8)
			-- Create XObject from parsed stream.
			-- Per ISO 32000-1:2008 §8.8, XObjects are streams with specific dictionary entries.
		do
			Precursor (a_dictionary, a_content)
		end

feature -- Access

	subtype: STRING_8
			-- The XObject subtype (Image, Form, PS).
			-- Per ISO 32000-1:2008 §8.8, /Subtype is required.
		deferred
		ensure
			result_not_empty: not Result.is_empty
		end

feature -- Query

	is_image: BOOLEAN
			-- Is this an Image XObject?
			-- Per ISO 32000-1:2008 §8.9.
		do
			Result := subtype.same_string ("Image")
		end

	is_form: BOOLEAN
			-- Is this a Form XObject?
			-- Per ISO 32000-1:2008 §8.10.
		do
			Result := subtype.same_string ("Form")
		end

end
