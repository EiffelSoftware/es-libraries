note
	description: "[
		Helper class for PDF page operations.
		Provides centralized handling of inheritable page attributes
		per ISO 32000-1:2008 Table 30.
		
		Inheritable attributes:
		- /Resources (required, inheritable)
		- /MediaBox (required, inheritable)
		- /CropBox (optional, inheritable)
		- /Rotate (optional, inheritable)
		
		Note: /Contents is NOT inheritable per Table 30.
	]"
	spec_reference: "ISO 32000-1:2008 Table 30 (Inheritable Page Attributes)"
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_PAGE_HELPER

feature -- Inheritable Attributes

	get_inherited_attribute (a_doc: PDF_DOCUMENT; a_page: PDF_DICTIONARY; a_key: STRING): detachable PDF_OBJECT
			-- Get inheritable attribute from page, traversing page tree if needed.
			-- Per ISO 32000-1:2008 Table 30.
		require
			doc_valid: a_doc /= Void
			page_valid: a_page /= Void
			key_valid: a_key /= Void and then not a_key.is_empty
			is_inheritable: is_inheritable_key (a_key)
		local
			current_node: detachable PDF_DICTIONARY
			result_obj: detachable PDF_OBJECT
		do
			from
				current_node := a_page
			until
				Result /= Void or current_node = Void
			loop
				result_obj := current_node.item (a_key)
				if result_obj /= Void then
					Result := result_obj
				else
						-- Move to parent Pages node
					if attached {PDF_REFERENCE} current_node.item ("Parent") as parent_ref then
						if attached {PDF_DICTIONARY} a_doc.get_object (parent_ref.object_id) as parent_dict then
							current_node := parent_dict
						else
							current_node := Void
						end
					else
						current_node := Void
					end
				end
			end
		end

	get_media_box (a_doc: PDF_DOCUMENT; a_page: PDF_DICTIONARY): PDF_ARRAY
			-- Get MediaBox, with inheritance and default fallback.
			-- MediaBox is REQUIRED per ISO 32000-1:2008 Table 30.
		require
			doc_valid: a_doc /= Void
			page_valid: a_page /= Void
		local
			default_box: PDF_ARRAY
		do
			if attached {PDF_ARRAY} get_inherited_attribute (a_doc, a_page, "MediaBox") as box then
				Result := box
			else
				-- Default to US Letter (should not happen for valid PDFs)
				create default_box.make (4)
				default_box.add_real (0.0)
				default_box.add_real (0.0)
				default_box.add_real (612.0)
				default_box.add_real (792.0)
				Result := default_box
			end
		ensure
			result_attached: Result /= Void
			has_4_elements: Result.count >= 4
		end

	get_crop_box (a_doc: PDF_DOCUMENT; a_page: PDF_DICTIONARY): PDF_ARRAY
			-- Get CropBox, defaulting to MediaBox if not specified.
			-- Per ISO 32000-1:2008 Table 30.
		require
			doc_valid: a_doc /= Void
			page_valid: a_page /= Void
		do
			if attached {PDF_ARRAY} get_inherited_attribute (a_doc, a_page, "CropBox") as box then
				Result := box
			else
				-- Default to MediaBox per spec
				Result := get_media_box (a_doc, a_page)
			end
		ensure
			result_attached: Result /= Void
		end

	get_rotate (a_doc: PDF_DOCUMENT; a_page: PDF_DICTIONARY): INTEGER
			-- Get page rotation in degrees (0, 90, 180, or 270).
			-- Defaults to 0 if not specified.
		require
			doc_valid: a_doc /= Void
			page_valid: a_page /= Void
		do
			if attached {PDF_NUMBER} get_inherited_attribute (a_doc, a_page, "Rotate") as num then
				Result := num.int_value
				-- Normalize to valid values
				Result := Result \\ 360
				if Result < 0 then
					Result := Result + 360
				end
			else
				Result := 0
			end
		ensure
			valid_rotation: Result = 0 or Result = 90 or Result = 180 or Result = 270
		end

	get_resources (a_doc: PDF_DOCUMENT; a_page: PDF_DICTIONARY): detachable PDF_DICTIONARY
			-- Get Resources dictionary, with inheritance support.
			-- Per ISO 32000-1:2008 Table 30, Resources is inheritable.
		require
			doc_valid: a_doc /= Void
			page_valid: a_page /= Void
		do
			if attached {PDF_DICTIONARY} get_inherited_attribute (a_doc, a_page, "Resources") as res then
				Result := res
			end
		end

feature -- Queries

	is_inheritable_key (a_key: STRING): BOOLEAN
			-- Is this an inheritable page attribute per ISO 32000-1:2008 Table 30?
		require
			key_valid: a_key /= Void
		do
			Result := a_key.is_equal ("Resources")
				or a_key.is_equal ("MediaBox")
				or a_key.is_equal ("CropBox")
				or a_key.is_equal ("Rotate")
		ensure
			definition: Result = (a_key.is_equal ("Resources")
				or a_key.is_equal ("MediaBox")
				or a_key.is_equal ("CropBox")
				or a_key.is_equal ("Rotate"))
		end

	has_local_attribute (a_page: PDF_DICTIONARY; a_key: STRING): BOOLEAN
			-- Does page have attribute directly (not inherited)?
		require
			page_valid: a_page /= Void
			key_valid: a_key /= Void
		do
			Result := a_page.has_key (a_key)
		end

feature -- Dimension Helpers

	get_page_width (a_doc: PDF_DOCUMENT; a_page: PDF_DICTIONARY): REAL_64
			-- Get page width from MediaBox (with inheritance).
			-- Width is MediaBox[2] - MediaBox[0].
		require
			doc_valid: a_doc /= Void
			page_valid: a_page /= Void
		local
			box: PDF_ARRAY
			x0, x1: REAL_64
		do
			box := get_media_box (a_doc, a_page)
			if attached {PDF_NUMBER} box.item (1) as n0 then
				x0 := n0.real_value
			end
			if attached {PDF_NUMBER} box.item (3) as n1 then
				x1 := n1.real_value
			end
			Result := x1 - x0
		ensure
			positive_result: Result >= 0.0
		end

	get_page_height (a_doc: PDF_DOCUMENT; a_page: PDF_DICTIONARY): REAL_64
			-- Get page height from MediaBox (with inheritance).
			-- Height is MediaBox[3] - MediaBox[1].
		require
			doc_valid: a_doc /= Void
			page_valid: a_page /= Void
		local
			box: PDF_ARRAY
			y0, y1: REAL_64
		do
			box := get_media_box (a_doc, a_page)
			if attached {PDF_NUMBER} box.item (2) as n0 then
				y0 := n0.real_value
			end
			if attached {PDF_NUMBER} box.item (4) as n1 then
				y1 := n1.real_value
			end
			Result := y1 - y0
		ensure
			positive_result: Result >= 0.0
		end

end
