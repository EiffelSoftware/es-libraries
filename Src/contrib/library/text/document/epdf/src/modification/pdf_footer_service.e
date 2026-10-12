note
	description: "[
		Service for adding footers to PDF documents.
		Implements footer injection strategy per plan.md §6.
		Never rewrites existing content streams, only appends new ones.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_FOOTER_SERVICE

inherit
	PDF_WITH_LOGGING

create
	make

feature -- Initialization

	make
			-- Create footer service.
		do
			create resource_manager.make
			create stream_creator.make
			create page_helper
			default_font_size := 10.0
			default_margin := 36.0
			footer_alignment := Alignment_center
		ensure
			resource_manager_created: resource_manager /= Void
			stream_creator_created: stream_creator /= Void
			page_helper_created: page_helper /= Void
			default_font_size_set: default_font_size = 10.0
			default_margin_set: default_margin = 36.0
			default_alignment_center: footer_alignment = Alignment_center
		end

feature -- Access

	resource_manager: PDF_RESOURCE_MANAGER
			-- Resource manager for font allocation.

	stream_creator: PDF_CONTENT_STREAM_CREATOR
			-- Content stream creator.

	default_font_size: REAL_64
			-- Default font size for footer text.

	default_margin: REAL_64
			-- Default margin from bottom of page (in points).

	page_helper: PDF_PAGE_HELPER
			-- Helper for page attribute inheritance per ISO 32000-1:2008 Table 30.

	footer_alignment: INTEGER
			-- Footer horizontal alignment: Alignment_left, Alignment_center, or Alignment_right.

	get_page_width (a_doc: PDF_DOCUMENT; a_page: PDF_DICTIONARY): REAL_64
			-- Get page width from MediaBox (with full inheritance support).
			-- Delegates to PDF_PAGE_HELPER for centralized inheritance handling.
		require
			doc_valid: a_doc /= Void
			page_valid: a_page /= Void
		do
			Result := page_helper.get_page_width (a_doc, a_page)
		ensure
			result_positive: Result > 0.0
		end

	get_page_height (a_doc: PDF_DOCUMENT; a_page: PDF_DICTIONARY): REAL_64
			-- Get page height from MediaBox (with full inheritance support).
			-- Delegates to PDF_PAGE_HELPER for centralized inheritance handling.
		require
			doc_valid: a_doc /= Void
			page_valid: a_page /= Void
		do
			Result := page_helper.get_page_height (a_doc, a_page)
		ensure
			result_positive: Result > 0.0
		end

	find_inherited_mediabox (a_doc: PDF_DOCUMENT; a_page: PDF_DICTIONARY): detachable PDF_ARRAY
			-- Find inherited MediaBox by traversing up the page tree.
			-- Delegates to PDF_PAGE_HELPER.get_media_box for centralized inheritance.
			-- Kept for backward compatibility.
		require
			doc_valid: a_doc /= Void
			page_valid: a_page /= Void
		do
			Result := page_helper.get_media_box (a_doc, a_page)
		end

	get_footer_y_position (a_doc: PDF_DOCUMENT; a_page: PDF_DICTIONARY): REAL_64
			-- Calculate footer Y position based on CropBox (visible area).
			-- Footer is placed at CropBox lower Y + margin to stay within visible area.
			-- Per ISO 32000-1:2008, CropBox defines the visible region.
		require
			doc_valid: a_doc /= Void
			page_valid: a_page /= Void
		local
			crop_box: PDF_ARRAY
			lower_y: REAL_64
		do
			crop_box := page_helper.get_crop_box (a_doc, a_page)
				-- CropBox[1] is the lower Y coordinate
			if attached {PDF_NUMBER} crop_box.item (2) as y_num then
				lower_y := y_num.real_value
			end
			-- Position footer at lower edge of CropBox + margin
			Result := lower_y + default_margin
		ensure
			positive_result: Result >= 0.0
		end

	get_footer_x_position (a_doc: PDF_DOCUMENT; a_page: PDF_DICTIONARY; a_text_length: INTEGER; a_font_size: REAL_64): REAL_64
			-- Calculate footer X position based on alignment setting.
			-- Supports left, center, and right alignment within CropBox.
		require
			doc_valid: a_doc /= Void
			page_valid: a_page /= Void
			text_length_valid: a_text_length > 0
			font_size_valid: a_font_size > 0.0
		local
			crop_box: PDF_ARRAY
			left_x, right_x, crop_width, text_width: REAL_64
		do
			crop_box := page_helper.get_crop_box (a_doc, a_page)
				-- CropBox[0] is left X, CropBox[2] is right X
			if attached {PDF_NUMBER} crop_box.item (1) as x0 then
				left_x := x0.real_value
			end
			if attached {PDF_NUMBER} crop_box.item (3) as x1 then
				right_x := x1.real_value
			end
			crop_width := right_x - left_x
			text_width := a_text_length.to_real * a_font_size * 0.55

			inspect footer_alignment
			when Alignment_left then
					-- Left-align with margin
				Result := left_x + default_margin
			when Alignment_right then
					-- Right-align with margin
				Result := right_x - text_width - default_margin
					-- Ensure we don't go past left margin
				if Result < left_x + default_margin then
					Result := left_x + default_margin
				end
			else
					-- Center alignment (default)
				Result := left_x + (crop_width / 2.0) - (text_width / 2.0)
					-- If text is too long, left-align with margin
				if Result < left_x + default_margin then
					Result := left_x + default_margin
				end
			end
		ensure
			positive_result: Result >= 0.0
		end

	footer_x_position_for_text (a_doc: PDF_DOCUMENT; a_page: PDF_DICTIONARY; a_text: STRING_8; a_font_size: REAL_64): REAL_64
			-- Calculate footer X position based on alignment setting and precise text width.
			-- Supports left, center, and right alignment within CropBox.
		require
			doc_valid: a_doc /= Void
			page_valid: a_page /= Void
			text_valid: a_text /= Void and then not a_text.is_empty
			font_size_valid: a_font_size > 0.0
		local
			crop_box: PDF_ARRAY
			left_x, right_x, crop_width, text_width: REAL_64
		do
			crop_box := page_helper.get_crop_box (a_doc, a_page)
				-- CropBox[0] is left X, CropBox[2] is right X
			if attached {PDF_NUMBER} crop_box.item (1) as x0 then
				left_x := x0.real_value
			end
			if attached {PDF_NUMBER} crop_box.item (3) as x1 then
				right_x := x1.real_value
			end
			crop_width := right_x - left_x
			text_width := string_width (a_text, a_font_size)

			inspect footer_alignment
			when Alignment_left then
					-- Left-align with margin
				Result := left_x + default_margin
			when Alignment_right then
					-- Right-align with margin
				Result := right_x - text_width - default_margin
					-- Ensure we don't go past left margin
				if Result < left_x + default_margin then
					Result := left_x + default_margin
				end
			else
					-- Center alignment (default)
				Result := left_x + (crop_width / 2.0) - (text_width / 2.0)
					-- If text is too long, left-align with margin
				if Result < left_x + default_margin then
					Result := left_x + default_margin
				end
			end
		ensure
			positive_result: Result >= 0.0
		end

	string_width (a_text: STRING_8; a_font_size: REAL_64): REAL_64
			-- Calculate estimated width of `a_text` in Helvetica.
		require
			text_valid: a_text /= Void
			font_size_valid: a_font_size > 0.0
		local
			i: INTEGER
			w: REAL_64
		do
			from
				i := 1
				w := 0.0
			invariant
				valid_index: i >= 1 and i <= a_text.count + 1
				valid_width: w >= 0.0
			until
				i > a_text.count
			loop
				w := w + helvetica_char_width (a_text [i])
				i := i + 1
			variant
				remaining: a_text.count + 1 - i
			end
			Result := w * a_font_size
		ensure
			positive_result: Result >= 0.0
		end

	helvetica_char_width (c: CHARACTER_8): REAL_64
			-- Width of character `c` in Helvetica (for font size 1.0).
		do
			inspect c
			when 'i', 'j', 'l' then
				Result := 0.222
			when ' ', '!', ',', '.', '/', ':', ';', '[', '\', ']', 'f', 't', 'I' then
				Result := 0.278
			when 'r', '(', ')', '-' then
				Result := 0.333
			when 'c', 'k', 's', 'v', 'x', 'y', 'z', 'J', '?' then
				Result := 0.500
			when 'a', 'b', 'd', 'e', 'g', 'h', 'n', 'o', 'p', 'q', 'u', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '$', 'L', '_', '^' then
				Result := 0.556
			when 'F', 'T', 'Z' then
				Result := 0.611
			when 'A', 'B', 'E', 'K', 'P', 'R', 'S', 'V', 'X', 'Y', '&' then
				Result := 0.667
			when 'C', 'D', 'H', 'N', 'U', 'w' then
				Result := 0.722
			when 'G', 'O', 'Q', '@' then
				Result := 0.778
			when 'M', 'm' then
				Result := 0.833
			when 'W' then
				Result := 0.944
			when '%%' then
				Result := 0.889
			else
				Result := 0.550 -- Default average
			end
		end

feature -- Element Change

	set_font_size (a_size: REAL_64)
			-- Set default font size for footer text.
		require
			size_positive: a_size > 0.0
		do
			default_font_size := a_size
		ensure
			font_size_set: default_font_size = a_size
		end

	set_margin (a_margin: REAL_64)
			-- Set default margin from bottom of page.
		require
			margin_non_negative: a_margin >= 0.0
		do
			default_margin := a_margin
		ensure
			margin_set: default_margin = a_margin
		end

	set_alignment (a_alignment: INTEGER)
			-- Set footer horizontal alignment.
			-- Use Alignment_left, Alignment_center, or Alignment_right constants.
		require
			valid_alignment: a_alignment >= Alignment_left and a_alignment <= Alignment_right
		do
			footer_alignment := a_alignment
		ensure
			alignment_set: footer_alignment = a_alignment
		end

feature -- Operations

	add_footer_to_page (a_doc: PDF_DOCUMENT; a_page: PDF_DICTIONARY; a_page_id: STRING_8; a_text: STRING_8)
			-- Add footer to a single page (without modification tracking).
			-- For incremental update support, use add_footer_to_page_tracked instead.
		require
			doc_valid: a_doc /= Void
			page_valid: a_page /= Void
			page_id_valid: a_page_id /= Void and then not a_page_id.is_empty
			text_valid: a_text /= Void and then not a_text.is_empty
		do
			add_footer_to_page_tracked (a_doc, a_page, a_page_id, a_text, Void)
		end

	add_footer_to_page_tracked (a_doc: PDF_DOCUMENT; a_page: PDF_DICTIONARY; a_page_id: STRING_8; a_text: STRING_8; a_page_obj_id: detachable PDF_OBJECT_ID)
			-- Add footer to a single page.
			-- Per plan.md §6.2, converts /Contents to array and appends footer stream.
			-- If a_page_obj_id is provided, marks the page as modified for incremental updates.
		require
			doc_valid: a_doc /= Void
			page_valid: a_page /= Void
			page_id_valid: a_page_id /= Void and then not a_page_id.is_empty
			text_valid: a_text /= Void and then not a_text.is_empty
		local
			font_name: STRING_8
			contents: detachable PDF_OBJECT
			lines: ARRAYED_LIST [STRING_8]
			x_positions: ARRAYED_LIST [REAL_64]
			y_positions: ARRAYED_LIST [REAL_64]
			base_y_pos, line_spacing: REAL_64
			i: INTEGER
			footer_ops: STRING_8
			footer_stream: PDF_STREAM
			footer_id: PDF_OBJECT_ID
			footer_ref: PDF_REFERENCE
			contents_array: PDF_ARRAY
		do
				-- Ensure font resource exists (with inheritance support)
			font_name := resource_manager.find_or_add_helvetica (a_page, a_doc, a_page_id)

				-- Split text into lines
			lines := split_lines (a_text)

				-- Calculate footer positions for each line
			create x_positions.make (lines.count)
			create y_positions.make (lines.count)

			base_y_pos := get_footer_y_position (a_doc, a_page)
			line_spacing := 1.2 * default_font_size

			from
				i := 1
			until
				i > lines.count
			loop
				y_positions.extend (base_y_pos + (lines.count - i).to_double * line_spacing)
				x_positions.extend (footer_x_position_for_text (a_doc, a_page, lines [i], default_font_size))
				i := i + 1
			end

			-- Generate scrambled footer operators for all lines
			create footer_ops.make (512)
			from
				i := 1
			until
				i > lines.count
			loop
				footer_ops.append (stream_creator.create_scrambled_line_operators (lines [i], font_name, default_font_size, x_positions [i], y_positions [i]))
				i := i + 1
			end

				-- Get existing contents
			contents := a_page.item ("Contents")

			if contents = Void then
				-- No existing contents - create new Contents array with just the footer stream
				create footer_stream.make ("q%N" + footer_ops + "%NQ%N")
				footer_id := a_doc.add_object (footer_stream)
				create footer_ref.make (footer_id)
				
				create contents_array.make (1)
				contents_array.add (footer_ref)
				a_page.put (contents_array, "Contents")
			else
				-- Coalesce/merge the footer operators directly into the last content stream
				coalesce_footer_to_contents (a_doc, contents, footer_ops)
			end

				-- Mark page as modified for incremental update support
			if a_page_obj_id /= Void then
				a_doc.mark_modified (a_page_obj_id)
			end
		end

	coalesce_footer_to_contents (a_doc: PDF_DOCUMENT; a_contents: PDF_OBJECT; a_footer_ops: STRING_8)
			-- Coalesce `a_footer_ops` into the last stream of `a_contents`.
		require
			doc_valid: a_doc /= Void
			contents_valid: a_contents /= Void
			footer_ops_valid: a_footer_ops /= Void
		local
			last_item: PDF_OBJECT
		do
			if attached {PDF_ARRAY} a_contents as arr then
				if arr.count > 0 then
					last_item := arr.item (arr.count)
					if attached {PDF_REFERENCE} last_item as ref then
						if attached {PDF_STREAM} a_doc.get_object (ref.object_id) as stream then
							coalesce_to_stream (a_doc, stream, a_footer_ops)
							a_doc.mark_modified (ref.object_id)
						end
					elseif attached {PDF_STREAM} last_item as stream then
						coalesce_to_stream (a_doc, stream, a_footer_ops)
					end
				end
			elseif attached {PDF_STREAM} a_contents as stream then
				coalesce_to_stream (a_doc, stream, a_footer_ops)
			elseif attached {PDF_REFERENCE} a_contents as ref then
				if attached {PDF_STREAM} a_doc.get_object (ref.object_id) as stream then
					coalesce_to_stream (a_doc, stream, a_footer_ops)
					a_doc.mark_modified (ref.object_id)
				end
			end
		end

	coalesce_to_stream (a_doc: PDF_DOCUMENT; a_stream: PDF_STREAM; a_footer_ops: STRING_8)
			-- Decompress `a_stream`, append `a_footer_ops`, and update the stream content.
		require
			doc_valid: a_doc /= Void
			stream_valid: a_stream /= Void
			footer_ops_valid: a_footer_ops /= Void
		local
			decoder: PDF_FLATE_DECODER
			content: STRING_8
		do
			if a_stream.is_compressed then
				create decoder.make
				if attached decoder.decode (a_stream.content) as decomp then
					content := decomp
					content.append ("%Nq%N")
					content.append (a_footer_ops)
					content.append ("%NQ%N")
					a_stream.set_decompressed_content (content, "FlateDecode")
				else
					-- Decompression failed, append to raw content as fallback
					content := a_stream.content
					content.append ("%Nq%N")
					content.append (a_footer_ops)
					content.append ("%NQ%N")
					a_stream.set_content (content)
				end
			else
				content := a_stream.content
				content.append ("%Nq%N")
				content.append (a_footer_ops)
				content.append ("%NQ%N")
				a_stream.set_content (content)
			end
		end


	add_footer_to_document (a_doc: PDF_DOCUMENT; a_text: STRING_8)
			-- Add footer to all pages in document.
			-- Per plan.md §6.3, iterate over all pages and add footer.
		require
			doc_loaded: a_doc.is_loaded
			text_valid: a_text /= Void and then not a_text.is_empty
		local
			catalog: detachable PDF_DICTIONARY
			pages_ref: detachable PDF_REFERENCE
			pages_dict: detachable PDF_DICTIONARY
		do
				-- Get document catalog
			catalog := a_doc.catalog

			if catalog /= Void then
					-- Get Pages dictionary
				if attached {PDF_REFERENCE} catalog.item ("Pages") as pref then
					pages_ref := pref
					if attached {PDF_DICTIONARY} a_doc.get_object (pref.object_id) as pdict then
						pages_dict := pdict
						process_pages_tree_with_parent (a_doc, pages_dict, a_text, Void, Void)
					end
				elseif attached {PDF_DICTIONARY} catalog.item ("Pages") as pdict then
					pages_dict := pdict
					process_pages_tree_with_parent (a_doc, pages_dict, a_text, Void, Void)
				end
			end
		end

feature {NONE} -- Implementation

	process_pages_tree_with_parent (a_doc: PDF_DOCUMENT; a_pages: PDF_DICTIONARY; a_text: STRING_8; a_parent: detachable PDF_DICTIONARY; a_page_obj_id: detachable PDF_OBJECT_ID)
			-- Recursively process pages tree and add footer to each page.
			-- Per ISO 32000-1:2008 §7.7.3.3, page tree is hierarchical.
			-- Tracks parent for inheritance resolution and page object ID for modification tracking.
		require
			doc_valid: a_doc /= Void
			pages_valid: a_pages /= Void
			text_valid: a_text /= Void and then not a_text.is_empty
		local
			kids: detachable PDF_OBJECT
			kids_array: detachable PDF_ARRAY
			page_type: detachable PDF_OBJECT
		do
				-- Check if this is a page or pages node
			page_type := a_pages.item ("Type")

			if attached {PDF_NAME} page_type as type_name then
				if type_name.value.is_equal ("Page") then
						-- This is a leaf page node
						-- Pass the actual parent for inheritance resolution and object ID for tracking
					add_footer_to_page_with_inheritance (a_doc, a_pages, "page", a_text, a_parent, a_page_obj_id)
				elseif type_name.value.is_equal ("Pages") then
						-- This is an intermediate pages node, process kids
						-- THIS node becomes the parent for its children
					kids := a_pages.item ("Kids")

					if attached {PDF_ARRAY} kids as arr then
						kids_array := arr
						process_kids_array_with_parent (a_doc, kids_array, a_text, a_pages)
					elseif attached {PDF_REFERENCE} kids as ref then
						if attached {PDF_ARRAY} a_doc.get_object (ref.object_id) as arr then
							kids_array := arr
							process_kids_array_with_parent (a_doc, kids_array, a_text, a_pages)
						end
					end
				end
			end
		end

	add_footer_to_page_with_inheritance (a_doc: PDF_DOCUMENT; a_page: PDF_DICTIONARY; a_page_id: STRING_8; a_text: STRING_8; a_parent: detachable PDF_DICTIONARY; a_page_obj_id: detachable PDF_OBJECT_ID)
			-- Add footer to page, properly handling inherited /Contents
			-- Per ISO 32000-1:2008 Table 30, /Contents is inheritable
			-- If a_page_obj_id is provided, marks page as modified for incremental updates.
		require
			doc_valid: a_doc /= Void
			page_valid: a_page /= Void
			page_id_valid: a_page_id /= Void and then not a_page_id.is_empty
			text_valid: a_text /= Void and then not a_text.is_empty
		local
			contents: detachable PDF_OBJECT
			resolved_contents: detachable PDF_OBJECT
		do
				-- Try to get Contents from page first
			contents := a_page.item ("Contents")

				-- If not found and we have a parent, try inheritance
			if contents = Void and a_parent /= Void then
				resolved_contents := resolve_inherited_contents (a_doc, a_parent)
				if resolved_contents /= Void then
					log_info ("[PDF_FOOTER_SERVICE] Using inherited Contents for page%N")
						-- For inherited contents, we need to create a local copy
						-- Don't modify the inherited value!
						-- Put the resolved contents into the page dictionary so add_footer_to_page can find it.
					a_page.put (resolved_contents, "Contents")
					contents := resolved_contents -- Update local 'contents' for the check below
				end
			end

				-- If we still don't have Contents, skip this page
			if contents = Void then
				log_info ("[PDF_FOOTER_SERVICE] Warning: Skipping page with no Contents (even after inheritance check)%N")
			else
					-- Normal footer addition logic with modification tracking
				add_footer_to_page_tracked (a_doc, a_page, a_page_id, a_text, a_page_obj_id)
			end
		end

	resolve_inherited_contents (a_doc: PDF_DOCUMENT; a_pages_node: PDF_DICTIONARY): detachable PDF_OBJECT
			-- Resolve inherited /Contents from parent Pages nodes
			-- Walks up the page tree looking for Contents
		require
			doc_valid: a_doc /= Void
			pages_valid: a_pages_node /= Void
		local
			contents: detachable PDF_OBJECT
			parent_ref: detachable PDF_REFERENCE
			parent_dict: detachable PDF_DICTIONARY
		do
				-- Check current node for Contents
			contents := a_pages_node.item ("Contents")

			if contents /= Void then
				Result := contents
			else
					-- Try parent
				if attached {PDF_REFERENCE} a_pages_node.item ("Parent") as pref then
					parent_ref := pref
					if attached {PDF_DICTIONARY} a_doc.get_object (pref.object_id) as pdict then
						parent_dict := pdict
						Result := resolve_inherited_contents (a_doc, parent_dict)
					end
				end
			end
		end


	process_kids_array_with_parent (a_doc: PDF_DOCUMENT; a_kids: PDF_ARRAY; a_text: STRING_8; a_parent: detachable PDF_DICTIONARY)
			-- Process kids array in pages tree.
			-- Extracts object IDs from references for modification tracking.
		require
			doc_valid: a_doc /= Void
			kids_valid: a_kids /= Void
			text_valid: a_text /= Void and then not a_text.is_empty
		local
			kid_dict: detachable PDF_DICTIONARY
		do
			across a_kids.items as cursor loop
				if attached {PDF_REFERENCE} cursor as ref then
					if attached {PDF_DICTIONARY} a_doc.get_object (ref.object_id) as dict then
						kid_dict := dict
						-- Pass the object ID for modification tracking
						process_pages_tree_with_parent (a_doc, kid_dict, a_text, a_parent, ref.object_id)
					end
				elseif attached {PDF_DICTIONARY} cursor as dict then
					kid_dict := dict
						-- Direct dictionary without reference - no object ID available
					process_pages_tree_with_parent (a_doc, kid_dict, a_text, a_parent, Void)
				end
			end
		end

	get_page_mediabox (a_page: PDF_DICTIONARY): detachable PDF_ARRAY
			-- Get MediaBox from page, checking inheritance.
			-- Per ISO 32000-1:2008 Table 30, MediaBox is inheritable from parent Pages nodes.
			-- If not found anywhere, returns default US Letter size: [0 0 612 792].
			-- NOTE: This method cannot traverse parent tree without document reference.
			-- Use `find_inherited_mediabox` for full inheritance support.
		require
			page_valid: a_page /= Void
		local
			media_box: detachable PDF_OBJECT
			default_box: PDF_ARRAY
		do
			media_box := a_page.item ("MediaBox")

			if attached {PDF_ARRAY} media_box as arr then
				Result := arr
			else
					-- MediaBox not in page, might be inherited
					-- Return default US Letter (cannot traverse without document reference)
				create default_box.make (4)
				default_box.add_real (0.0)
				default_box.add_real (0.0)
				default_box.add_real (612.0)
				default_box.add_real (792.0)
				Result := default_box
			end
		ensure
			result_attached: Result /= Void
			result_has_4_elements: Result.count = 4
		end

	split_lines (a_text: STRING_8): ARRAYED_LIST [STRING_8]
			-- Split `a_text` by newlines.
		require
			text_attached: a_text /= Void
		local
			start_pos, end_pos: INTEGER
			line: STRING_8
		do
			create Result.make (5)
			from
				start_pos := 1
			until
				start_pos > a_text.count
			loop
				end_pos := a_text.index_of ('%N', start_pos)
				if end_pos > 0 then
					line := a_text.substring (start_pos, end_pos - 1)
					-- Remove carriage return if present
					if not line.is_empty and then line [line.count] = '%R' then
						line.remove_tail (1)
					end
					Result.extend (line)
					start_pos := end_pos + 1
				else
					line := a_text.substring (start_pos, a_text.count)
					if not line.is_empty and then line [line.count] = '%R' then
						line.remove_tail (1)
					end
					Result.extend (line)
					start_pos := a_text.count + 1
				end
			end
		ensure
			result_attached: Result /= Void
		end

feature -- Constants

	Alignment_left: INTEGER = 1
			-- Left alignment constant.

	Alignment_center: INTEGER = 2
			-- Center alignment constant (default).

	Alignment_right: INTEGER = 3
			-- Right alignment constant.

invariant
	resource_manager_attached: resource_manager /= Void
	stream_creator_attached: stream_creator /= Void
	font_size_positive: default_font_size > 0.0
	margin_non_negative: default_margin >= 0.0
	valid_alignment: footer_alignment >= Alignment_left and footer_alignment <= Alignment_right

end
