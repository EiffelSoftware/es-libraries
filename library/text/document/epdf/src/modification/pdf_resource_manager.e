note
	description: "[
		Manages resources in PDF pages.
		Ensures proper resource dictionary structure per ISO 32000-1:2008 §7.8.3.
		Handles font allocation, naming, and collision resolution.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_RESOURCE_MANAGER

create
	make

feature -- Initialization

	make
			-- Create resource manager.
		do
			create font_counter.make (0)
			create shared_fonts.make (5)
			create xobject_counter.make (0)
			create extgstate_counter.make (0)
		ensure
			font_counter_created: font_counter /= Void
			shared_fonts_created: shared_fonts /= Void
			xobject_counter_created: xobject_counter /= Void
			extgstate_counter_created: extgstate_counter /= Void
		end

feature -- Access

	font_counter: HASH_TABLE [INTEGER, STRING_8]
			-- Counter for font resource names per page.
			-- Maps page object ID to next available font number.

	shared_fonts: HASH_TABLE [PDF_OBJECT_ID, STRING_8]
			-- Document-level shared font cache.
			-- Maps font identifier (e.g., "Helvetica") to object ID.
			-- Enables font deduplication across pages per ISO 32000-1:2008 best practices.

	xobject_counter: HASH_TABLE [INTEGER, STRING_8]
			-- Counter for XObject resource names per page.
			-- Maps page object ID to next available XObject number.

	extgstate_counter: HASH_TABLE [INTEGER, STRING_8]
			-- Counter for ExtGState resource names per page.
			-- Maps page object ID to next available ExtGState number.

feature -- Resource Management

	ensure_resources_dict (a_page: PDF_DICTIONARY; a_doc: PDF_DOCUMENT): PDF_DICTIONARY
			-- Ensure page has a /Resources dictionary, create if needed.
			-- Per ISO 32000-1:2008 §7.7.3.4, Resources can be inherited from parent Pages nodes.
			-- When creating local Resources, copy inherited resources to preserve fonts, XObjects, etc.
			-- Resources may be stored as inline dictionary OR as indirect reference.
		require
			page_valid: a_page /= Void
			doc_valid: a_doc /= Void
		local
			resources: PDF_DICTIONARY
			inherited_resources: detachable PDF_DICTIONARY
		do
			if a_page.has_key ("Resources") then
					-- Page has its own Resources entry (not inherited)
					-- Can be inline dictionary OR indirect reference
				if attached {PDF_DICTIONARY} a_page.item ("Resources") as res then
						-- Resources is an inline dictionary - copy and dereference sub-resources
					resources := copy_resources (res, a_doc)
					a_page.put (resources, "Resources")
					Result := resources
				elseif attached {PDF_REFERENCE} a_page.item ("Resources") as res_ref then
						-- Resources is an indirect reference - dereference and copy
						-- Per ISO 32000-1:2008 §7.3.10, must resolve indirect references
					if attached {PDF_DICTIONARY} a_doc.get_object (res_ref.object_id) as res_dict then
							-- Copy the referenced Resources to create a modifiable local copy
							-- This preserves existing fonts (TT1, TT2, etc.) while allowing modifications
						resources := copy_resources (res_dict, a_doc)
						a_page.put (resources, "Resources")
						Result := resources
					else
							-- Reference didn't resolve to dictionary - create empty
						create resources.make_empty
						a_page.put (resources, "Resources")
						Result := resources
					end
				else
						-- Shouldn't happen, but handle gracefully
					create resources.make_empty
					a_page.put (resources, "Resources")
					Result := resources
				end
			else
					-- Page inherits Resources from parent Pages node
					-- Find inherited resources by traversing the page tree
				inherited_resources := find_inherited_resources (a_doc, a_page)

				if inherited_resources /= Void then
						-- Copy inherited resources to create local dictionary
					resources := copy_resources (inherited_resources, a_doc)
				else
						-- No inherited resources found, create empty
					create resources.make_empty
				end

				a_page.put (resources, "Resources")
				Result := resources
			end
		ensure
			result_attached: Result /= Void
			page_has_resources: a_page.has_key ("Resources")
		end

	ensure_font_dict (a_resources: PDF_DICTIONARY): PDF_DICTIONARY
			-- Ensure resources dictionary has a /Font dictionary, create if needed.
			-- Per ISO 32000-1:2008 §7.8.3, resources may contain /Font entry.
		require
			resources_valid: a_resources /= Void
		local
			fonts: PDF_DICTIONARY
		do
			if attached {PDF_DICTIONARY} a_resources.item ("Font") as font_dict then
				Result := font_dict
			else
					-- Create new font dictionary
				create fonts.make_empty
				a_resources.put (fonts, "Font")
				Result := fonts
			end
		ensure
			result_attached: Result /= Void
			resources_has_fonts: a_resources.has_key ("Font")
		end

	allocate_font_name (a_page_id: STRING_8; a_font_dict: PDF_DICTIONARY): STRING_8
			-- Allocate a unique font resource name for the given page.
			-- Returns name like "F1", "F2", etc.
			-- Checks existing fonts to avoid collisions.
		require
			page_id_valid: a_page_id /= Void and then not a_page_id.is_empty
			font_dict_valid: a_font_dict /= Void
		local
			next_num: INTEGER
			candidate: STRING_8
		do
				-- Get next font number for this page
			if font_counter.has (a_page_id) then
				next_num := font_counter.item (a_page_id)
			else
				next_num := 1
			end

				-- Find available name
			from
				candidate := "F" + next_num.out
			until
				not a_font_dict.has_key (candidate)
			loop
				next_num := next_num + 1
				candidate := "F" + next_num.out
			end

				-- Update counter
			font_counter.force (next_num + 1, a_page_id)
			Result := candidate
		ensure
			result_valid: Result /= Void and then not Result.is_empty
			result_starts_with_f: Result.starts_with ("F")
			not_in_dict: not a_font_dict.has_key (Result)
		end

	add_type1_font (a_page: PDF_DICTIONARY; a_doc: PDF_DOCUMENT; a_font_name: STRING_8; a_base_font: STRING_8): PDF_DICTIONARY
			-- Add a Type1 font to the page resources as a DIRECT object.
			-- Per ISO 32000-1:2008 §9.6.2, Type1 fonts use /Type /Font and /Subtype /Type1.
			-- Per ISO 32000-1:2008 §7.8.3, fonts in Resources can be direct objects or references.
			-- We use direct objects for simplicity.
		require
			page_valid: a_page /= Void
			doc_valid: a_doc /= Void
			font_name_valid: a_font_name /= Void and then not a_font_name.is_empty
			base_font_valid: a_base_font /= Void and then not a_base_font.is_empty
		local
			resources: PDF_DICTIONARY
			font_dict: PDF_DICTIONARY
			font_obj: PDF_DICTIONARY
		do
				-- Ensure resource dictionaries exist (with inheritance support)
			resources := ensure_resources_dict (a_page, a_doc)
			font_dict := ensure_font_dict (resources)

				-- Create font object as direct dictionary
			create font_obj.make (3)
			font_obj.put_name ("Font", "Type")
			font_obj.put_name ("Type1", "Subtype")
			font_obj.put_name (a_base_font, "BaseFont")

				-- Add DIRECTLY to font dictionary (not as reference)
			font_dict.put (font_obj, a_font_name)

			Result := font_obj
		ensure
			result_attached: Result /= Void
		end

	find_or_add_helvetica (a_page: PDF_DICTIONARY; a_doc: PDF_DOCUMENT; a_page_id: STRING_8): STRING_8
			-- Find existing Helvetica font or add new one using shared font cache.
			-- Returns the font resource name (e.g., "F1").
			-- Uses document-level font deduplication for optimal PDF size.
		require
			page_valid: a_page /= Void
			doc_valid: a_doc /= Void
			page_id_valid: a_page_id /= Void and then not a_page_id.is_empty
		local
			resources: PDF_DICTIONARY
			font_dict: PDF_DICTIONARY
			font_name: STRING_8
			font_id: PDF_OBJECT_ID
			font_ref: PDF_REFERENCE
		do
				-- Ensure resource dictionaries exist (with inheritance support)
			resources := ensure_resources_dict (a_page, a_doc)
			font_dict := ensure_font_dict (resources)

				-- Allocate unique font name for this page
			font_name := allocate_font_name (a_page_id, font_dict)

				-- Get or create shared Helvetica font object
			font_id := find_or_create_shared_helvetica (a_doc)

				-- Add reference to shared font in page's Resources
			create font_ref.make (font_id)
			font_dict.put (font_ref, font_name)

			Result := font_name
		ensure
			result_valid: Result /= Void and then not Result.is_empty
		end

feature -- XObject Management

	ensure_xobject_dict (a_resources: PDF_DICTIONARY): PDF_DICTIONARY
			-- Ensure resources dictionary has an /XObject dictionary, create if needed.
			-- Per ISO 32000-1:2008 §7.8.3, resources may contain /XObject entry.
		require
			resources_valid: a_resources /= Void
		local
			xobjects: PDF_DICTIONARY
		do
			if attached {PDF_DICTIONARY} a_resources.item ("XObject") as xobject_dict then
				Result := xobject_dict
			else
					-- Create new XObject dictionary
				create xobjects.make_empty
				a_resources.put (xobjects, "XObject")
				Result := xobjects
			end
		ensure
			result_attached: Result /= Void
			resources_has_xobjects: a_resources.has_key ("XObject")
		end

	allocate_xobject_name (a_page_id: STRING_8; a_xobject_dict: PDF_DICTIONARY): STRING_8
			-- Allocate a unique XObject resource name for the given page.
			-- Returns name like "Im1", "Im2", etc. for images.
			-- Checks existing XObjects to avoid collisions.
		require
			page_id_valid: a_page_id /= Void and then not a_page_id.is_empty
			xobject_dict_valid: a_xobject_dict /= Void
		local
			next_num: INTEGER
			candidate: STRING_8
		do
				-- Get next XObject number for this page
			if xobject_counter.has (a_page_id) then
				next_num := xobject_counter.item (a_page_id)
			else
				next_num := 1
			end

				-- Find available name
			from
				candidate := "Im" + next_num.out
			until
				not a_xobject_dict.has_key (candidate)
			loop
				next_num := next_num + 1
				candidate := "Im" + next_num.out
			end

				-- Update counter
			xobject_counter.force (next_num + 1, a_page_id)
			Result := candidate
		ensure
			result_valid: Result /= Void and then not Result.is_empty
			result_starts_with_im: Result.starts_with ("Im")
			not_in_dict: not a_xobject_dict.has_key (Result)
		end

	add_xobject_reference (a_page: PDF_DICTIONARY; a_doc: PDF_DOCUMENT;
			a_name: STRING_8; a_xobject_id: PDF_OBJECT_ID)
			-- Add XObject reference to page resources.
			-- Per ISO 32000-1:2008 §7.8.3, XObjects in Resources reference indirect objects.
		require
			page_valid: a_page /= Void
			doc_valid: a_doc /= Void
			name_valid: a_name /= Void and then not a_name.is_empty
			id_valid: a_xobject_id /= Void
		local
			resources: PDF_DICTIONARY
			xobject_dict: PDF_DICTIONARY
			xobject_ref: PDF_REFERENCE
		do
				-- Ensure resource dictionaries exist
			resources := ensure_resources_dict (a_page, a_doc)
			xobject_dict := ensure_xobject_dict (resources)

				-- Add reference to XObject
			create xobject_ref.make (a_xobject_id)
			xobject_dict.put (xobject_ref, a_name)
		ensure
			page_has_resources: a_page.has_key ("Resources")
		end

feature -- ExtGState Management

	ensure_extgstate_dict (a_resources: PDF_DICTIONARY): PDF_DICTIONARY
			-- Ensure resources dictionary has an /ExtGState dictionary, create if needed.
			-- Per ISO 32000-1:2008 §7.8.3, resources may contain /ExtGState entry.
		require
			resources_valid: a_resources /= Void
		local
			extgstates: PDF_DICTIONARY
		do
			if attached {PDF_DICTIONARY} a_resources.item ("ExtGState") as gs_dict then
				Result := gs_dict
			else
					-- Create new ExtGState dictionary
				create extgstates.make_empty
				a_resources.put (extgstates, "ExtGState")
				Result := extgstates
			end
		ensure
			result_attached: Result /= Void
			resources_has_extgstate: a_resources.has_key ("ExtGState")
		end

	allocate_extgstate_name (a_page_id: STRING_8; a_gs_dict: PDF_DICTIONARY): STRING_8
			-- Allocate a unique ExtGState resource name for the given page.
			-- Returns name like "GS1", "GS2", etc.
			-- Checks existing ExtGState entries to avoid collisions.
		require
			page_id_valid: a_page_id /= Void and then not a_page_id.is_empty
			gs_dict_valid: a_gs_dict /= Void
		local
			next_num: INTEGER
			candidate: STRING_8
		do
				-- Get next ExtGState number for this page
			if extgstate_counter.has (a_page_id) then
				next_num := extgstate_counter.item (a_page_id)
			else
				next_num := 1
			end

				-- Find available name
			from
				candidate := "GS" + next_num.out
			until
				not a_gs_dict.has_key (candidate)
			loop
				next_num := next_num + 1
				candidate := "GS" + next_num.out
			end

				-- Update counter
			extgstate_counter.force (next_num + 1, a_page_id)
			Result := candidate
		ensure
			result_valid: Result /= Void and then not Result.is_empty
			result_starts_with_gs: Result.starts_with ("GS")
			not_in_dict: not a_gs_dict.has_key (Result)
		end

	add_extgstate_reference (a_page: PDF_DICTIONARY; a_doc: PDF_DOCUMENT;
			a_name: STRING_8; a_gs_id: PDF_OBJECT_ID)
			-- Add ExtGState reference to page resources.
			-- Per ISO 32000-1:2008 §7.8.3, ExtGState in Resources reference indirect objects.
		require
			page_valid: a_page /= Void
			doc_valid: a_doc /= Void
			name_valid: a_name /= Void and then not a_name.is_empty
			id_valid: a_gs_id /= Void
		local
			resources: PDF_DICTIONARY
			gs_dict: PDF_DICTIONARY
			gs_ref: PDF_REFERENCE
		do
				-- Ensure resource dictionaries exist
			resources := ensure_resources_dict (a_page, a_doc)
			gs_dict := ensure_extgstate_dict (resources)

				-- Add reference to ExtGState
			create gs_ref.make (a_gs_id)
			gs_dict.put (gs_ref, a_name)
		ensure
			page_has_resources: a_page.has_key ("Resources")
		end

	deep_copy_dictionary (a_dict: PDF_DICTIONARY): PDF_DICTIONARY
			-- Create a deep copy of a dictionary.
			-- Copies all key-value pairs from source to new dictionary.
			-- Per ISO 32000-1:2008 §7.3.7, dictionaries are unordered collections of key-value pairs.
		require
			dict_valid: a_dict /= Void
		do
			create Result.make (a_dict.count)

				-- Copy all entries from source dictionary
				-- Iterate over HASH_TABLE entries using cursor
			across a_dict.entries as cursor loop
				Result.put (cursor, @ cursor.key)
			end
		ensure
			result_attached: Result /= Void
			same_size: Result.count = a_dict.count
		end

	copy_resources (a_resources: PDF_DICTIONARY; a_doc: PDF_DOCUMENT): PDF_DICTIONARY
			-- Create a deep copy of Resources dictionary.
			-- Copies Font, XObject, ExtGState, ColorSpace, Pattern, Shading, and Properties.
			-- Per ISO 32000-1:2008 §7.8.3, these are the standard resource types.
			-- Creates deep copies of subdictionaries to prevent modifications affecting inherited pages.
			-- Resolves and copies indirect references to standard categories (Font, XObject, ExtGState).
		require
			resources_valid: a_resources /= Void
			doc_valid: a_doc /= Void
		local
			resource_keys: ARRAY [STRING_8]
			copied_dict: PDF_DICTIONARY
			res_val: detachable PDF_OBJECT
		do
			create Result.make_empty

				-- Copy standard resource categories
			resource_keys := <<"Font", "XObject", "ExtGState", "ColorSpace", "Pattern", "Shading", "Properties">>

			across resource_keys as key loop
				if attached a_resources.item (key) as resource_value then
					res_val := resource_value
						-- Resolve indirect reference if any
					if attached {PDF_REFERENCE} res_val as ref then
						res_val := a_doc.get_object (ref.object_id)
					end

						-- Deep copy: if it's a dictionary, copy all entries
					if attached {PDF_DICTIONARY} res_val as res_dict then
						copied_dict := deep_copy_dictionary (res_dict)
						Result.put (copied_dict, key)
					else
							-- Fallback: copy original value (shallow copy is safe if not a dictionary)
						Result.put (resource_value, key)
					end
				end
			end
		ensure
			result_attached: Result /= Void
		end

feature {NONE} -- Implementation

	find_or_create_shared_helvetica (a_doc: PDF_DOCUMENT): PDF_OBJECT_ID
			-- Find or create shared Helvetica font object.
			-- Creates font once and reuses for all pages (deduplication).
			-- Per ISO 32000-1:2008 §9.6.2, Type1 fonts are shared resources.
		require
			doc_valid: a_doc /= Void
		local
			font_obj: PDF_DICTIONARY
		do
			if shared_fonts.has ("Helvetica") and then attached shared_fonts.item ("Helvetica") as cached_id then
					-- Reuse existing shared font
				Result := cached_id
			else
					-- Create new Helvetica font object
				create font_obj.make (3)
				font_obj.put_name ("Font", "Type")
				font_obj.put_name ("Type1", "Subtype")
				font_obj.put_name ("Helvetica", "BaseFont")

					-- Add to document as indirect object
				Result := a_doc.add_object (font_obj)

					-- Cache for reuse
				shared_fonts.put (Result, "Helvetica")
			end
		ensure
			result_valid: Result /= Void
			cached: shared_fonts.has ("Helvetica")
		end

	find_inherited_resources (a_doc: PDF_DOCUMENT; a_page: PDF_DICTIONARY): detachable PDF_DICTIONARY
			-- Find inherited Resources by traversing up the page tree.
			-- Per ISO 32000-1:2008 §7.7.3.4, Resources are inheritable from parent Pages nodes.
		require
			doc_valid: a_doc /= Void
			page_valid: a_page /= Void
		local
			parent_ref: detachable PDF_REFERENCE
			parent_dict: detachable PDF_DICTIONARY
		do
				-- Check if page has a /Parent entry
			if attached {PDF_REFERENCE} a_page.item ("Parent") as pref then
				parent_ref := pref
				if attached {PDF_DICTIONARY} a_doc.get_object (pref.object_id) as pdict then
					parent_dict := pdict
						-- Check if parent has Resources (can be inline dict OR reference)
					if attached {PDF_DICTIONARY} parent_dict.item ("Resources") as res then
						-- Resources is an inline dictionary
						Result := res
					elseif attached {PDF_REFERENCE} parent_dict.item ("Resources") as res_ref then
						-- Resources is a reference - dereference it
						-- Per ISO 32000-1:2008 §7.3.10, indirect references must be resolved
						if attached {PDF_DICTIONARY} a_doc.get_object (res_ref.object_id) as res_dict then
							Result := res_dict
						end
					else
							-- Recursively check parent's parent
						Result := find_inherited_resources (a_doc, parent_dict)
					end
				end
			end
		end

invariant
	font_counter_attached: font_counter /= Void
	shared_fonts_attached: shared_fonts /= Void
	xobject_counter_attached: xobject_counter /= Void
	extgstate_counter_attached: extgstate_counter /= Void

end
