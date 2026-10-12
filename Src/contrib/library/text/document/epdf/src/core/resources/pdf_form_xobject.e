note
	description: "[
		Represents a PDF Form XObject.
		Form XObjects contain a self-contained description of any sequence
		of graphics operators. They can be used to define reusable content.
		
		Per ISO 32000-1:2008 §8.10:
		- /Subtype /Form (required)
		- /BBox (required) - bounding box in form space
		- /Resources (optional) - form's own resource dictionary
		- /Matrix (optional) - transformation matrix
	]"
	spec_reference: "ISO 32000-1:2008 Section 8.10 Form XObjects"
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_FORM_XOBJECT

inherit
	PDF_XOBJECT
		redefine
			make_with_dictionary
		end

create
	make_with_dictionary

feature -- Initialization

	make_with_dictionary (a_dictionary: PDF_DICTIONARY; a_content: STRING_8)
			-- Create form XObject from parsed stream.
			-- Extracts form properties from dictionary.
		do
			Precursor (a_dictionary, a_content)
			extract_properties
		end

feature -- Access

	subtype: STRING_8
			-- Returns "Form" per ISO 32000-1:2008 §8.10.
		once
			Result := "Form"
		end

	bounding_box: detachable PDF_ARRAY
			-- Form bounding box in form space coordinates.
			-- Per ISO 32000-1:2008 §8.10 Table 95: [llx lly urx ury].

	resources: detachable PDF_DICTIONARY
			-- Form's own resource dictionary.
			-- Per ISO 32000-1:2008 §8.10, forms can have their own resources.

	matrix: detachable PDF_ARRAY
			-- Optional transformation matrix.
			-- Per ISO 32000-1:2008 §8.10, default is identity [1 0 0 1 0 0].

	form_type: INTEGER
			-- Form type (1 for XObject form).
			-- Per ISO 32000-1:2008 §8.10, only value 1 is defined.

feature -- Query

	has_own_resources: BOOLEAN
			-- Does this form have its own resource dictionary?
		do
			Result := resources /= Void
		end

	has_transformation: BOOLEAN
			-- Does this form have a custom transformation matrix?
		do
			Result := matrix /= Void
		end

feature {NONE} -- Implementation

	extract_properties
			-- Extract form properties from stream dictionary.
		local
			dict: PDF_DICTIONARY
		do
			dict := stream_dictionary

				-- BBox (required)
			if attached {PDF_ARRAY} dict.item ("BBox") as bbox then
				bounding_box := bbox
			end

				-- Resources (optional, can be inline or reference)
			if attached {PDF_DICTIONARY} dict.item ("Resources") as res then
				resources := res
			end
				-- Note: Reference case handled by caller resolving refs

				-- Matrix (optional)
			if attached {PDF_ARRAY} dict.item ("Matrix") as m then
				matrix := m
			end

				-- FormType (optional, default 1)
			if attached {PDF_NUMBER} dict.item ("FormType") as ft then
				form_type := ft.int_value
			else
				form_type := 1  -- Default per ISO 32000-1:2008
			end
		end

invariant
	valid_subtype: subtype.same_string ("Form")
	valid_form_type: form_type = 1

end
