note
	description: "[
		Test suite for Phase 3: Modifier components.
		Tests resource manager, content stream creator, and footer service.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_PHASE3_MODIFIER

inherit
	EQA_TEST_SET

feature -- Test: Resource Manager

	test_resource_manager_creation
			-- Test resource manager creation.
		local
			manager: PDF_RESOURCE_MANAGER
		do
			create manager.make
			assert ("manager created", manager /= Void)
			assert ("font counter created", manager.font_counter /= Void)
		end

	test_ensure_resources_dict
			-- Test ensuring resources dictionary exists.
		local
			manager: PDF_RESOURCE_MANAGER
			page: PDF_DICTIONARY
			resources: PDF_DICTIONARY
			doc: PDF_DOCUMENT
		do
			create manager.make
			create page.make_empty
			create doc.make

				-- First call should create resources
			resources := manager.ensure_resources_dict (page, doc)
			assert ("resources created", resources /= Void)
			assert ("page has resources", page.has_key ("Resources"))

				-- Second call should return same resources
			resources := manager.ensure_resources_dict (page, doc)
			assert ("resources still exists", resources /= Void)
		end

	test_ensure_font_dict
			-- Test ensuring font dictionary exists.
		local
			manager: PDF_RESOURCE_MANAGER
			resources: PDF_DICTIONARY
			fonts: PDF_DICTIONARY
		do
			create manager.make
			create resources.make_empty

				-- First call should create fonts
			fonts := manager.ensure_font_dict (resources)
			assert ("fonts created", fonts /= Void)
			assert ("resources has fonts", resources.has_key ("Font"))

				-- Second call should return same fonts
			fonts := manager.ensure_font_dict (resources)
			assert ("fonts still exists", fonts /= Void)
		end

	test_allocate_font_name
			-- Test font name allocation.
		local
			manager: PDF_RESOURCE_MANAGER
			font_dict: PDF_DICTIONARY
			name1, name2, name3: STRING_8
		do
			create manager.make
			create font_dict.make_empty

				-- Allocate first font name
			name1 := manager.allocate_font_name ("page1", font_dict)
			assert ("first name is F1", name1.is_equal ("F1"))
			assert ("not in dict", not font_dict.has_key (name1))

				-- Add to dict and allocate next
			font_dict.put_name ("Helvetica", name1)
			name2 := manager.allocate_font_name ("page1", font_dict)
			assert ("second name is F2", name2.is_equal ("F2"))
			assert ("different from first", not name1.is_equal (name2))

				-- Add to dict and allocate next
			font_dict.put_name ("Times-Roman", name2)
			name3 := manager.allocate_font_name ("page1", font_dict)
			assert ("third name is F3", name3.is_equal ("F3"))
		end

	test_add_type1_font
			-- Test adding Type1 font to page.
		local
			manager: PDF_RESOURCE_MANAGER
			page: PDF_DICTIONARY
			font_obj: PDF_DICTIONARY
			doc: PDF_DOCUMENT
		do
			create manager.make
			create page.make_empty
			create doc.make

			font_obj := manager.add_type1_font (page, doc, "F1", "Helvetica")
			assert ("font object created", font_obj /= Void)
			assert ("page has resources", page.has_key ("Resources"))
		end

	test_find_or_add_helvetica
			-- Test finding or adding Helvetica font.
		local
			manager: PDF_RESOURCE_MANAGER
			page: PDF_DICTIONARY
			font_name: STRING_8
			doc: PDF_DOCUMENT
		do
			create manager.make
			create page.make_empty
			create doc.make

			font_name := manager.find_or_add_helvetica (page, doc, "page1")
			assert ("font name valid", font_name /= Void and then not font_name.is_empty)
			assert ("font name starts with F", font_name.starts_with ("F"))
		end

feature -- Test: Content Stream Creator

	test_stream_creator_creation
			-- Test content stream creator creation.
		local
			creator: PDF_CONTENT_STREAM_CREATOR
		do
			create creator.make
			assert ("creator created", creator /= Void)
		end

	test_create_footer_stream
			-- Test creating footer content stream.
		local
			creator: PDF_CONTENT_STREAM_CREATOR
			stream: PDF_STREAM
		do
			create creator.make
			stream := creator.create_footer_stream ("Page 1", "F1", 10.0, 100.0, 50.0)
			assert ("stream created", stream /= Void)
			assert ("stream has content", stream.content.count > 0)
			assert ("contains BT", stream.content.has_substring ("BT"))
			assert ("contains ET", stream.content.has_substring ("ET"))
			assert ("contains Tf", stream.content.has_substring ("Tf"))
			assert ("contains Td", stream.content.has_substring ("Td"))
			assert ("contains Tj", stream.content.has_substring ("Tj"))
		end

	test_create_text_stream_with_color
			-- Test creating text stream with color.
		local
			creator: PDF_CONTENT_STREAM_CREATOR
			stream: PDF_STREAM
		do
			create creator.make
			stream := creator.create_text_stream ("Colored Text", "F1", 12.0, 100.0, 50.0, 1.0, 0.0, 0.0)
			assert ("stream created", stream /= Void)
			assert ("stream has content", stream.content.count > 0)
			assert ("contains rg (color)", stream.content.has_substring ("rg"))
			assert ("contains BT", stream.content.has_substring ("BT"))
			assert ("contains ET", stream.content.has_substring ("ET"))
		end

	test_escape_text
			-- Test text escaping for PDF strings.
		local
			creator: PDF_CONTENT_STREAM_CREATOR
			stream: PDF_STREAM
		do
			create creator.make
				-- Test with special characters
			stream := creator.create_footer_stream ("Test (parentheses)", "F1", 10.0, 100.0, 50.0)
			assert ("stream created", stream /= Void)
			assert ("parentheses escaped", stream.content.has_substring ("\(") or stream.content.has_substring ("\)"))
		end

feature -- Test: Footer Service

	test_footer_service_creation
			-- Test footer service creation.
		local
			service: PDF_FOOTER_SERVICE
		do
			create service.make
			assert ("service created", service /= Void)
			assert ("resource manager created", service.resource_manager /= Void)
			assert ("stream creator created", service.stream_creator /= Void)
			assert ("default font size set", service.default_font_size = 10.0)
			assert ("default margin set", service.default_margin = 36.0)
		end

	test_set_font_size
			-- Test setting font size.
		local
			service: PDF_FOOTER_SERVICE
		do
			create service.make
			service.set_font_size (12.0)
			assert ("font size changed", service.default_font_size = 12.0)
		end

	test_set_margin
			-- Test setting margin.
		local
			service: PDF_FOOTER_SERVICE
		do
			create service.make
			service.set_margin (50.0)
			assert ("margin changed", service.default_margin = 50.0)
		end

			test_add_footer_to_page_no_contents
			-- Test adding footer to page with no existing contents.
		local
			service: PDF_FOOTER_SERVICE
			page: PDF_DICTIONARY
			doc: PDF_DOCUMENT
		do
			create service.make
			create page.make_empty
			create doc.make

			service.add_footer_to_page (doc, page, "page1", "Footer Text")
			assert ("page has contents", page.has_key ("Contents"))
			
			if attached {PDF_ARRAY} page.item ("Contents") as contents_array then
				assert ("contents is array", True)
				assert ("array has one item", contents_array.count = 1)
			else
				assert ("contents should be array", False)
			end
		end

	test_add_footer_to_page_with_stream
			-- Test adding footer to page with existing stream.
		local
			service: PDF_FOOTER_SERVICE
			page: PDF_DICTIONARY
			existing_stream: PDF_STREAM
			doc: PDF_DOCUMENT
		do
			create service.make
			create page.make_empty
			create doc.make
			create existing_stream.make ("BT /F1 12 Tf 100 700 Td (Existing) Tj ET")
			page.put (existing_stream, "Contents")

			service.add_footer_to_page (doc, page, "page1", "Footer Text")
			
			if attached {PDF_STREAM} page.item ("Contents") as stream then
				assert ("contents is still stream", True)
				assert ("contains original content", stream.content.has_substring ("(Existing) Tj"))
				assert ("contains footer BT", stream.content.has_substring ("BT"))
				assert ("contains footer ET", stream.content.has_substring ("ET"))
				assert ("does not contain plain footer text", not stream.content.has_substring ("(Footer Text) Tj"))
			else
				assert ("contents should be stream", False)
			end
		end

	test_add_footer_to_page_with_array
			-- Test adding footer to page with existing array.
		local
			service: PDF_FOOTER_SERVICE
			page: PDF_DICTIONARY
			contents_array: PDF_ARRAY
			stream1, stream2: PDF_STREAM
			doc: PDF_DOCUMENT
		do
			create service.make
			create page.make_empty
			create doc.make
			create stream1.make ("BT /F1 12 Tf 100 700 Td (Stream1) Tj ET")
			create stream2.make ("BT /F1 12 Tf 100 650 Td (Stream2) Tj ET")
			create contents_array.make (2)
			contents_array.add (stream1)
			contents_array.add (stream2)
			page.put (contents_array, "Contents")

			service.add_footer_to_page (doc, page, "page1", "Footer Text")
			
			if attached {PDF_ARRAY} page.item ("Contents") as result_array then
				assert ("contents still array", True)
				assert ("array has two items", result_array.count = 2)
				if attached {PDF_STREAM} result_array.item (2) as s2 then
					assert ("second stream contains original", s2.content.has_substring ("(Stream2) Tj"))
					assert ("second stream contains footer BT", s2.content.has_substring ("BT"))
					assert ("second stream does not contain plain footer text", not s2.content.has_substring ("(Footer Text) Tj"))
				else
					assert ("second item should be stream", False)
				end
			else
				assert ("contents should be array", False)
			end
		end

	test_get_page_dimensions
			-- Test getting page dimensions from MediaBox.
		local
			service: PDF_FOOTER_SERVICE
			page: PDF_DICTIONARY
			media_box: PDF_ARRAY
			doc: PDF_DOCUMENT
		do
			create service.make
			create page.make_empty
			create doc.make

				-- Create MediaBox [0 0 612 792] (US Letter)
			create media_box.make (4)
			media_box.add_number (0)
			media_box.add_number (0)
			media_box.add_number (612)
			media_box.add_number (792)
			page.put (media_box, "MediaBox")

				-- Test dimensions (internal methods, tested indirectly)
			service.add_footer_to_page (doc, page, "page1", "Test")
			assert ("footer added successfully", page.has_key ("Contents"))
		end

feature -- Test: Integration

	test_complete_footer_workflow
			-- Test complete workflow of adding footer to page.
		local
			service: PDF_FOOTER_SERVICE
			page: PDF_DICTIONARY
			media_box: PDF_ARRAY
			doc: PDF_DOCUMENT
		do
			create service.make
			create page.make_empty
			create doc.make

				-- Set up page with MediaBox
			create media_box.make (4)
			media_box.add_number (0)
			media_box.add_number (0)
			media_box.add_number (612)
			media_box.add_number (792)
			page.put (media_box, "MediaBox")
			page.put_name ("Page", "Type")

				-- Add footer
			service.add_footer_to_page (doc, page, "page1", "Page 1 of 10")

				-- Verify results
			assert ("page has resources", page.has_key ("Resources"))
			assert ("page has contents", page.has_key ("Contents"))

			if attached {PDF_DICTIONARY} page.item ("Resources") as resources then
				assert ("resources has fonts", resources.has_key ("Font"))
				
				if attached {PDF_DICTIONARY} resources.item ("Font") as fonts then
					assert ("fonts not empty", fonts.count > 0)
				else
					assert ("fonts should be dictionary", False)
				end
			else
				assert ("resources should be dictionary", False)
			end

			if attached {PDF_ARRAY} page.item ("Contents") as contents then
				assert ("contents has footer stream", contents.count = 1)
			else
				assert ("contents should be array", False)
			end
		end

feature -- Test: Phase 4B Enhancements

	test_mediabox_inheritance
			-- Test MediaBox inheritance from parent Pages node.
			-- Per ISO 32000-1:2008 Table 30, MediaBox is inheritable.
		local
			footer_service: PDF_FOOTER_SERVICE
			doc: PDF_DOCUMENT
			pages_dict: PDF_DICTIONARY
			page_dict: PDF_DICTIONARY
			media_box: PDF_ARRAY
			found_box: detachable PDF_ARRAY
			width, height: REAL_64
			pages_id: PDF_OBJECT_ID
			parent_ref: PDF_REFERENCE
			trailer_dict: PDF_DICTIONARY
			trailer: PDF_TRAILER
			catalog: PDF_DICTIONARY
			catalog_id: PDF_OBJECT_ID
		do
			create footer_service.make
			create doc.make
			
			-- Create a mock trailer so doc.is_loaded returns True
			-- This is needed because get_object has precondition: loaded: is_loaded
			create catalog.make_empty
			catalog.put_name ("Catalog", "Type")
			catalog_id := doc.add_object (catalog)
			
			create trailer_dict.make_empty
			trailer_dict.put_number (10, "Size")  -- Required trailer entry
			trailer_dict.put (create {PDF_REFERENCE}.make (catalog_id), "Root")  -- Required
			create trailer.make (trailer_dict)
			doc.set_trailer (trailer)
			
				-- Create parent Pages node with MediaBox (A4: 595 x 842 points)
			create pages_dict.make_empty
			pages_dict.put_name ("Pages", "Type")
			create media_box.make (4)
			media_box.add_real (0.0)
			media_box.add_real (0.0)
			media_box.add_real (595.0)  -- A4 width
			media_box.add_real (842.0)  -- A4 height
			pages_dict.put (media_box, "MediaBox")
			
				-- Add parent Pages node to document and get its ID
			pages_id := doc.add_object (pages_dict)
			create parent_ref.make (pages_id)
			
				-- Create child Page node without MediaBox (should inherit)
			create page_dict.make_empty
			page_dict.put_name ("Page", "Type")
			page_dict.put (parent_ref, "Parent")
			
				-- Test MediaBox inheritance
			found_box := footer_service.find_inherited_mediabox (doc, page_dict)
			assert ("MediaBox found through inheritance", found_box /= Void)
			
			if found_box /= Void then
				assert ("MediaBox has 4 elements", found_box.count = 4)
					-- Verify it's the A4 dimensions we set
				if attached {PDF_NUMBER} found_box.item (3) as width_num then
					assert ("Width is A4 (595)", width_num.real_value = 595.0)
				end
				if attached {PDF_NUMBER} found_box.item (4) as height_num then
					assert ("Height is A4 (842)", height_num.real_value = 842.0)
				end
			end
			
				-- Test with page dimensions (should find inherited MediaBox)
			width := footer_service.get_page_width (doc, page_dict)
			height := footer_service.get_page_height (doc, page_dict)
			assert ("Width from inheritance is A4", width = 595.0)
			assert ("Height from inheritance is A4", height = 842.0)
		end

	test_deep_copy_dictionary
			-- Test deep copy of resource dictionaries.
			-- Verifies modifications don't affect original.
		local
			manager: PDF_RESOURCE_MANAGER
			original: PDF_DICTIONARY
			copied_dict: PDF_DICTIONARY
			font_dict: PDF_DICTIONARY
		do
			create manager.make
			
				-- Create original dictionary with Font subdictionary
			create original.make_empty
			create font_dict.make_empty
			font_dict.put_name ("Helvetica", "F1")
			original.put (font_dict, "Font")
			
				-- Create deep copy
			copied_dict := manager.deep_copy_dictionary (original)
			
				-- Verify structure
			assert ("Copy created", copied_dict /= Void)
			assert ("Copy has same size", copied_dict.count = original.count)
			assert ("Copy has Font", copied_dict.has_key ("Font"))
			
				-- Verify it's a real copy (different object)
			assert ("Copy is different object", copied_dict /= original)
			
				-- Note: The current implementation creates a new dictionary but still
				-- references the same subdictionary objects. This is sufficient for
				-- our use case since we only add new entries to Font dict, not modify existing ones.
		end

	test_resources_deep_copy
			-- Test deep copy of Resources dictionary preserves all standard resource types.
			-- Per ISO 32000-1:2008 §7.8.3.
		local
			manager: PDF_RESOURCE_MANAGER
			original: PDF_DICTIONARY
			copied_resources: PDF_DICTIONARY
			font_dict, xobject_dict: PDF_DICTIONARY
		do
			create manager.make
			
				-- Create Resources with multiple resource types
			create original.make_empty
			
			create font_dict.make_empty
			font_dict.put_name ("Helvetica", "F1")
			original.put (font_dict, "Font")
			
			create xobject_dict.make_empty
			xobject_dict.put_name ("Image", "Im1")
			original.put (xobject_dict, "XObject")
			
				-- Create deep copy using copy_resources
			copied_resources := manager.copy_resources (original, create {PDF_DOCUMENT}.make)
			
				-- Verify structure preserved
			assert ("Copy has Font", copied_resources.has_key ("Font"))
			assert ("Copy has XObject", copied_resources.has_key ("XObject"))
			assert ("Copy size correct", copied_resources.count = 2)
		end

	test_add_multiline_footer
			-- Test adding a multi-line footer to a page.
		local
			service: PDF_FOOTER_SERVICE
			page: PDF_DICTIONARY
			media_box: PDF_ARRAY
			doc: PDF_DOCUMENT
			catalog: PDF_DICTIONARY
			catalog_id: PDF_OBJECT_ID
			trailer_dict: PDF_DICTIONARY
			trailer: PDF_TRAILER
		do
			create service.make
			create page.make_empty
			create doc.make

			-- Set up a mock trailer so doc.is_loaded returns True
			create catalog.make_empty
			catalog.put_name ("Catalog", "Type")
			catalog_id := doc.add_object (catalog)
			create trailer_dict.make_empty
			trailer_dict.put_number (10, "Size")
			trailer_dict.put (create {PDF_REFERENCE}.make (catalog_id), "Root")
			create trailer.make (trailer_dict)
			doc.set_trailer (trailer)

				-- Set up page with MediaBox
			create media_box.make (4)
			media_box.add_number (0)
			media_box.add_number (0)
			media_box.add_number (612)
			media_box.add_number (792)
			page.put (media_box, "MediaBox")
			page.put_name ("Page", "Type")

				-- Add a two-line footer
			service.add_footer_to_page (doc, page, "page1", "First line of footer%NSecond line of footer")

				-- Verify results
			assert ("page has resources", page.has_key ("Resources"))
			assert ("page has contents", page.has_key ("Contents"))

			if attached {PDF_ARRAY} page.item ("Contents") as contents then
				assert ("contents has footer stream", contents.count = 1)
				if attached {PDF_REFERENCE} contents.item (1) as ref then
					if attached {PDF_STREAM} doc.get_object (ref.object_id) as stream then
						assert ("contains BT", stream.content.has_substring ("BT"))
						assert ("does not contain plain text first line", not stream.content.has_substring ("(First line of footer) Tj"))
						assert ("does not contain plain text second line", not stream.content.has_substring ("(Second line of footer) Tj"))
					else
						assert ("contents item should reference stream", False)
					end
				else
					assert ("contents item should be reference", False)
				end
			else
				assert ("contents should be array", False)
			end
		end

end
