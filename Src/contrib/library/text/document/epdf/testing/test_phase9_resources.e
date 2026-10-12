note
	description: "[
		Test suite for Phase 9: XObject and ExtGState Resource Support.
		Tests image XObject, form XObject, graphics state, and resource management.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_PHASE9_RESOURCES

inherit
	EQA_TEST_SET

feature -- Test: PDF_IMAGE_XOBJECT

	test_image_xobject_creation
			-- Test creating image XObject from stream dictionary.
		local
			dict: PDF_DICTIONARY
			image: PDF_IMAGE_XOBJECT
		do
			create dict.make (6)
			dict.put_name ("XObject", "Type")
			dict.put_name ("Image", "Subtype")
			dict.put_number (100, "Width")
			dict.put_number (200, "Height")
			dict.put_number (8, "BitsPerComponent")
			dict.put_name ("DeviceRGB", "ColorSpace")
			dict.put_name ("DCTDecode", "Filter")
			dict.put_number (5000, "Length")

			create image.make_with_dictionary (dict, "fake jpeg data")

			assert ("subtype is Image", image.subtype.same_string ("Image"))
			assert ("is_image true", image.is_image)
			assert ("is_form false", not image.is_form)
			assert ("width correct", image.width = 100)
			assert ("height correct", image.height = 200)
			assert ("bits per component", image.bits_per_component = 8)
			assert ("is JPEG", image.is_jpeg)
		end

	test_image_xobject_flate_compressed
			-- Test image XObject with FlateDecode filter.
		local
			dict: PDF_DICTIONARY
			image: PDF_IMAGE_XOBJECT
		do
			create dict.make (5)
			dict.put_name ("XObject", "Type")
			dict.put_name ("Image", "Subtype")
			dict.put_number (50, "Width")
			dict.put_number (50, "Height")
			dict.put_name ("FlateDecode", "Filter")

			create image.make_with_dictionary (dict, "compressed data")

			assert ("is flate compressed", image.is_flate_compressed)
			assert ("not JPEG", not image.is_jpeg)
		end

feature -- Test: PDF_FORM_XOBJECT

	test_form_xobject_creation
			-- Test creating form XObject from stream dictionary.
		local
			dict: PDF_DICTIONARY
			bbox: PDF_ARRAY
			form: PDF_FORM_XOBJECT
		do
			create dict.make (4)
			dict.put_name ("XObject", "Type")
			dict.put_name ("Form", "Subtype")
			dict.put_number (1, "FormType")

				-- BBox [0 0 100 100]
			create bbox.make (4)
			bbox.add_number (0)
			bbox.add_number (0)
			bbox.add_number (100)
			bbox.add_number (100)
			dict.put (bbox, "BBox")

			create form.make_with_dictionary (dict, "q BT /F1 12 Tf ET Q")

			assert ("subtype is Form", form.subtype.same_string ("Form"))
			assert ("is_form true", form.is_form)
			assert ("is_image false", not form.is_image)
			assert ("form_type is 1", form.form_type = 1)
			assert ("has bounding box", form.bounding_box /= Void)
			assert ("no own resources", not form.has_own_resources)
		end

	test_form_xobject_with_resources
			-- Test form XObject with its own resources.
		local
			dict: PDF_DICTIONARY
			bbox: PDF_ARRAY
			resources: PDF_DICTIONARY
			form: PDF_FORM_XOBJECT
		do
			create dict.make (5)
			dict.put_name ("XObject", "Type")
			dict.put_name ("Form", "Subtype")

			create bbox.make (4)
			bbox.add_number (0)
			bbox.add_number (0)
			bbox.add_number (200)
			bbox.add_number (150)
			dict.put (bbox, "BBox")

				-- Add own resources
			create resources.make_empty
			dict.put (resources, "Resources")

			create form.make_with_dictionary (dict, "content stream")

			assert ("has own resources", form.has_own_resources)
		end

feature -- Test: PDF_GRAPHICS_STATE

	test_graphics_state_creation
			-- Test creating graphics state from dictionary.
		local
			dict: PDF_DICTIONARY
			gs: PDF_GRAPHICS_STATE
		do
			create dict.make (4)
			dict.put_real (2.0, "LW")  -- Line width
			dict.put_number (1, "LC")    -- Line cap (round)
			dict.put_number (0, "LJ")    -- Line join (miter)

			create gs.make_from_dictionary (dict)

			assert ("has line style", gs.has_line_style)
			assert ("no transparency", not gs.has_transparency)
			assert ("line width set", gs.has_line_width and then gs.line_width = 2.0)
			assert ("line cap set", gs.has_line_cap and then gs.line_cap = 1)
		end

	test_graphics_state_transparency
			-- Test graphics state with transparency settings.
		local
			dict: PDF_DICTIONARY
			gs: PDF_GRAPHICS_STATE
		do
			create dict.make (3)
			dict.put_real (0.5, "CA")  -- Stroke alpha
			dict.put_real (0.7, "ca")  -- Fill alpha (lowercase!)
			dict.put_name ("Multiply", "BM")  -- Blend mode

			create gs.make_from_dictionary (dict)

			assert ("has transparency", gs.has_transparency)
			assert ("stroke alpha", gs.has_stroke_alpha and then gs.stroke_alpha = 0.5)
			assert ("fill alpha", gs.has_fill_alpha and then gs.fill_alpha = 0.7)
			assert ("blend mode", attached gs.blend_mode as bm and then bm.same_string ("Multiply"))
		end

	test_graphics_state_empty
			-- Test empty graphics state.
		local
			gs: PDF_GRAPHICS_STATE
		do
			create gs.make_empty

			assert ("no line style", not gs.has_line_style)
			assert ("no transparency", not gs.has_transparency)
		end

feature -- Test: PDF_RESOURCE_MANAGER XObject

	test_ensure_xobject_dict
			-- Test ensuring XObject dictionary exists in resources.
		local
			manager: PDF_RESOURCE_MANAGER
			resources: PDF_DICTIONARY
			xobject_dict: PDF_DICTIONARY
		do
			create manager.make
			create resources.make_empty

				-- First call should create XObject dict
			xobject_dict := manager.ensure_xobject_dict (resources)
			assert ("xobject dict created", xobject_dict /= Void)
			assert ("resources has XObject", resources.has_key ("XObject"))

				-- Second call should return same dict
			xobject_dict := manager.ensure_xobject_dict (resources)
			assert ("xobject dict still exists", xobject_dict /= Void)
		end

	test_allocate_xobject_name
			-- Test XObject name allocation (Im1, Im2, etc.).
		local
			manager: PDF_RESOURCE_MANAGER
			xobject_dict: PDF_DICTIONARY
			name1, name2, name3: STRING_8
		do
			create manager.make
			create xobject_dict.make_empty

				-- Allocate first name
			name1 := manager.allocate_xobject_name ("page1", xobject_dict)
			assert ("first name is Im1", name1.is_equal ("Im1"))

				-- Add to dict and allocate next
			xobject_dict.put_name ("placeholder", name1)
			name2 := manager.allocate_xobject_name ("page1", xobject_dict)
			assert ("second name is Im2", name2.is_equal ("Im2"))

				-- Add to dict and allocate next
			xobject_dict.put_name ("placeholder", name2)
			name3 := manager.allocate_xobject_name ("page1", xobject_dict)
			assert ("third name is Im3", name3.is_equal ("Im3"))
		end

	test_allocate_xobject_name_collision
			-- Test XObject name allocation with pre-existing names.
		local
			manager: PDF_RESOURCE_MANAGER
			xobject_dict: PDF_DICTIONARY
			name: STRING_8
		do
			create manager.make
			create xobject_dict.make_empty

				-- Pre-populate with Im1 and Im2
			xobject_dict.put_name ("existing", "Im1")
			xobject_dict.put_name ("existing", "Im2")

				-- Should skip to Im3
			name := manager.allocate_xobject_name ("page1", xobject_dict)
			assert ("skips to Im3", name.is_equal ("Im3"))
		end

feature -- Test: PDF_RESOURCE_MANAGER ExtGState

	test_ensure_extgstate_dict
			-- Test ensuring ExtGState dictionary exists in resources.
		local
			manager: PDF_RESOURCE_MANAGER
			resources: PDF_DICTIONARY
			gs_dict: PDF_DICTIONARY
		do
			create manager.make
			create resources.make_empty

				-- First call should create ExtGState dict
			gs_dict := manager.ensure_extgstate_dict (resources)
			assert ("extgstate dict created", gs_dict /= Void)
			assert ("resources has ExtGState", resources.has_key ("ExtGState"))

				-- Second call should return same dict
			gs_dict := manager.ensure_extgstate_dict (resources)
			assert ("extgstate dict still exists", gs_dict /= Void)
		end

	test_allocate_extgstate_name
			-- Test ExtGState name allocation (GS1, GS2, etc.).
		local
			manager: PDF_RESOURCE_MANAGER
			gs_dict: PDF_DICTIONARY
			name1, name2: STRING_8
		do
			create manager.make
			create gs_dict.make_empty

				-- Allocate first name
			name1 := manager.allocate_extgstate_name ("page1", gs_dict)
			assert ("first name is GS1", name1.is_equal ("GS1"))

				-- Add to dict and allocate next
			gs_dict.put_name ("placeholder", name1)
			name2 := manager.allocate_extgstate_name ("page1", gs_dict)
			assert ("second name is GS2", name2.is_equal ("GS2"))
		end

feature -- Test: Integration

	test_resources_preserve_xobject
			-- Test that copy_resources preserves XObject dictionary.
		local
			manager: PDF_RESOURCE_MANAGER
			original: PDF_DICTIONARY
			xobject_dict: PDF_DICTIONARY
			copied: PDF_DICTIONARY
		do
			create manager.make
			create original.make_empty

				-- Add XObject subdictionary
			create xobject_dict.make_empty
			xobject_dict.put_name ("ImageRef", "Im1")
			original.put (xobject_dict, "XObject")

				-- Copy resources
			copied := manager.copy_resources (original, create {PDF_DOCUMENT}.make)

			assert ("copy has XObject", copied.has_key ("XObject"))
			if attached {PDF_DICTIONARY} copied.item ("XObject") as copied_xo then
				assert ("XObject has Im1", copied_xo.has_key ("Im1"))
			else
				assert ("XObject is dictionary", False)
			end
		end

	test_resources_preserve_extgstate
			-- Test that copy_resources preserves ExtGState dictionary.
		local
			manager: PDF_RESOURCE_MANAGER
			original: PDF_DICTIONARY
			gs_dict: PDF_DICTIONARY
			copied: PDF_DICTIONARY
		do
			create manager.make
			create original.make_empty

				-- Add ExtGState subdictionary
			create gs_dict.make_empty
			gs_dict.put_real (0.5, "CA")
			original.put (gs_dict, "ExtGState")

				-- Copy resources
			copied := manager.copy_resources (original, create {PDF_DOCUMENT}.make)

			assert ("copy has ExtGState", copied.has_key ("ExtGState"))
		end

feature -- Test: Edge Cases (ISO 32000 Compliance)

	test_image_mask_validation
			-- Test image mask per ISO 32000-1:2008 §8.9.6.2.
			-- ImageMask=true requires BitsPerComponent=1 and no ColorSpace.
		local
			dict: PDF_DICTIONARY
			image: PDF_IMAGE_XOBJECT
		do
			create dict.make (5)
			dict.put_name ("XObject", "Type")
			dict.put_name ("Image", "Subtype")
			dict.put_boolean (True, "ImageMask")
			dict.put_number (1, "BitsPerComponent")
			dict.put_number (10, "Width")
			dict.put_number (10, "Height")
				-- ColorSpace should be omitted for image masks

			create image.make_with_dictionary (dict, "mask data")

			assert ("is image mask", image.is_image_mask)
			assert ("bits per component is 1", image.bits_per_component = 1)
			assert ("no color space", image.color_space_name = Void)
		end

	test_image_with_filter_array
			-- Test image XObject with multiple filters (array).
			-- Per ISO 32000-1:2008 §7.3.8, /Filter can be array.
		local
			dict: PDF_DICTIONARY
			filter_array: PDF_ARRAY
			image: PDF_IMAGE_XOBJECT
		do
			create dict.make (6)
			dict.put_name ("XObject", "Type")
			dict.put_name ("Image", "Subtype")
			dict.put_number (100, "Width")
			dict.put_number (100, "Height")

				-- Filter array: [ASCII85Decode FlateDecode]
			create filter_array.make (2)
			filter_array.add (create {PDF_NAME}.make ("ASCII85Decode"))
			filter_array.add (create {PDF_NAME}.make ("FlateDecode"))
			dict.put (filter_array, "Filter")

			create image.make_with_dictionary (dict, "compressed data")

				-- Should detect first filter
			assert ("has filter name", image.filter_name /= Void)
			assert ("first filter is ASCII85", attached image.filter_name as fn and then
				fn.same_string ("ASCII85Decode"))
			assert ("not detected as simple flate", not image.is_flate_compressed)
		end

	test_graphics_state_dash_pattern
			-- Test dash pattern parsing per ISO 32000-1:2008 §8.4.3.6.
			-- /D entry: [ [dash gap...] phase ]
		local
			dict: PDF_DICTIONARY
			dash_entry: PDF_ARRAY
			dash_pattern: PDF_ARRAY
			gs: PDF_GRAPHICS_STATE
		do
			create dict.make (2)

				-- /D [ [3 1] 0 ] means: 3 on, 1 off, starting at phase 0
			create dash_pattern.make (2)
			dash_pattern.add_number (3)  -- dash
			dash_pattern.add_number (1)  -- gap

			create dash_entry.make (2)
			dash_entry.add (dash_pattern)
			dash_entry.add_number (0)  -- phase
			dict.put (dash_entry, "D")

			create gs.make_from_dictionary (dict)

			assert ("has dash array", gs.dash_array /= Void)
			assert ("has line style", gs.has_line_style)
		end

	test_xobject_name_collision_non_prefixed
			-- Test XObject naming with non-prefixed existing names.
			-- Allocator should not overwrite /MyLogo etc.
		local
			manager: PDF_RESOURCE_MANAGER
			xobject_dict: PDF_DICTIONARY
			name: STRING_8
		do
			create manager.make
			create xobject_dict.make_empty

				-- Pre-populate with non-Im prefixed names
			xobject_dict.put_name ("SomeRef", "MyLogo")
			xobject_dict.put_name ("SomeRef", "CompanyBanner")
			xobject_dict.put_name ("SomeRef", "Im1")  -- Also has Im1

				-- Should skip Im1 and allocate Im2
			name := manager.allocate_xobject_name ("page1", xobject_dict)
			assert ("skips to Im2 not overwriting MyLogo", name.is_equal ("Im2"))
			assert ("MyLogo still exists", xobject_dict.has_key ("MyLogo"))
			assert ("CompanyBanner still exists", xobject_dict.has_key ("CompanyBanner"))
		end

	test_extgstate_name_collision_non_prefixed
			-- Test ExtGState naming with non-prefixed existing names.
		local
			manager: PDF_RESOURCE_MANAGER
			gs_dict: PDF_DICTIONARY
			name: STRING_8
		do
			create manager.make
			create gs_dict.make_empty

				-- Pre-populate with non-GS prefixed names
			gs_dict.put_name ("SomeRef", "Transparency1")
			gs_dict.put_name ("SomeRef", "GS1")  -- Also has GS1

				-- Should skip GS1 and allocate GS2
			name := manager.allocate_extgstate_name ("page1", gs_dict)
			assert ("skips to GS2", name.is_equal ("GS2"))
			assert ("Transparency1 still exists", gs_dict.has_key ("Transparency1"))
		end

	test_form_xobject_with_matrix
			-- Test Form XObject with transformation matrix.
			-- Default matrix is identity [1 0 0 1 0 0].
		local
			dict: PDF_DICTIONARY
			bbox: PDF_ARRAY
			matrix: PDF_ARRAY
			form: PDF_FORM_XOBJECT
		do
			create dict.make (5)
			dict.put_name ("XObject", "Type")
			dict.put_name ("Form", "Subtype")

				-- BBox
			create bbox.make (4)
			bbox.add_number (0)
			bbox.add_number (0)
			bbox.add_number (100)
			bbox.add_number (100)
			dict.put (bbox, "BBox")

				-- Custom Matrix: scale 2x, translate (50, 50)
			create matrix.make (6)
			matrix.add_number (2)   -- a: scale x
			matrix.add_number (0)   -- b
			matrix.add_number (0)   -- c
			matrix.add_number (2)   -- d: scale y
			matrix.add_number (50)  -- e: translate x
			matrix.add_number (50)  -- f: translate y
			dict.put (matrix, "Matrix")

			create form.make_with_dictionary (dict, "content")

			assert ("has transformation", form.has_transformation)
			assert ("matrix is attached", form.matrix /= Void)
			if attached form.matrix as m then
				assert ("matrix has 6 elements", m.count = 6)
			end
		end

	test_image_color_spaces
			-- Test various color space names per ISO 32000-1:2008 §8.6.
		local
			dict: PDF_DICTIONARY
			image: PDF_IMAGE_XOBJECT
		do
				-- Test DeviceGray
			create dict.make (5)
			dict.put_name ("Image", "Subtype")
			dict.put_number (100, "Width")
			dict.put_number (100, "Height")
			dict.put_number (8, "BitsPerComponent")
			dict.put_name ("DeviceGray", "ColorSpace")

			create image.make_with_dictionary (dict, "gray data")
			assert ("DeviceGray detected", attached image.color_space_name as cs and then
				cs.same_string ("DeviceGray"))

				-- Test DeviceCMYK
			create dict.make (5)
			dict.put_name ("Image", "Subtype")
			dict.put_number (100, "Width")
			dict.put_number (100, "Height")
			dict.put_number (8, "BitsPerComponent")
			dict.put_name ("DeviceCMYK", "ColorSpace")

			create image.make_with_dictionary (dict, "cmyk data")
			assert ("DeviceCMYK detected", attached image.color_space_name as cs2 and then
				cs2.same_string ("DeviceCMYK"))
		end

	test_resources_page_isolation
			-- Test that resource allocation is isolated per page.
			-- Im1 on page1 should not prevent Im1 on page2.
		local
			manager: PDF_RESOURCE_MANAGER
			xobject_dict1, xobject_dict2: PDF_DICTIONARY
			name_page1, name_page2: STRING_8
		do
			create manager.make
			create xobject_dict1.make_empty
			create xobject_dict2.make_empty

				-- Allocate on page1
			name_page1 := manager.allocate_xobject_name ("page1", xobject_dict1)
			assert ("page1 gets Im1", name_page1.is_equal ("Im1"))

				-- Allocate on page2 (different page, empty dict)
			name_page2 := manager.allocate_xobject_name ("page2", xobject_dict2)
			assert ("page2 also gets Im1", name_page2.is_equal ("Im1"))

				-- They are independent because each page has its own /Resources
		end

end

