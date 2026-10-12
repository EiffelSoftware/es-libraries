note
	description: "[
		Represents a PDF Image XObject.
		Image XObjects contain raster image data that can be painted
		using the Do operator in content streams.
		
		Per ISO 32000-1:2008 §8.9:
		- /Subtype /Image (required)
		- /Width, /Height (required) - dimensions in samples
		- /ColorSpace (required except for ImageMask)
		- /BitsPerComponent (required except for ImageMask and JPXDecode)
		- /Filter may include DCTDecode (JPEG), FlateDecode, etc.
	]"
	spec_reference: "ISO 32000-1:2008 Section 8.9 Images"
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_IMAGE_XOBJECT

inherit
	PDF_XOBJECT
		redefine
			make_with_dictionary
		end

create
	make_with_dictionary

feature -- Initialization

	make_with_dictionary (a_dictionary: PDF_DICTIONARY; a_content: STRING_8)
			-- Create image XObject from parsed stream.
			-- Extracts image properties from dictionary.
		do
			Precursor (a_dictionary, a_content)
			extract_properties
		ensure then
			width_extracted: width >= 0
			height_extracted: height >= 0
		end

feature -- Access

	subtype: STRING_8
			-- Returns "Image" per ISO 32000-1:2008 §8.9.
		once
			Result := "Image"
		end

	width: INTEGER
			-- Image width in samples.
			-- Per ISO 32000-1:2008 §8.9 Table 89.

	height: INTEGER
			-- Image height in samples.
			-- Per ISO 32000-1:2008 §8.9 Table 89.

	bits_per_component: INTEGER
			-- Number of bits per color component.
			-- Per ISO 32000-1:2008 §8.9 Table 89.
			-- Default is 8 for most color spaces.

	color_space_name: detachable STRING_8
			-- Color space name if directly specified.
			-- Can be DeviceGray, DeviceRGB, DeviceCMYK, or reference.

	is_image_mask: BOOLEAN
			-- Is this an image mask (stencil)?
			-- Per ISO 32000-1:2008 §8.9.6.2.

	filter_name: detachable STRING_8
			-- Primary filter name (e.g., "DCTDecode" for JPEG).

feature -- Query

	is_jpeg: BOOLEAN
			-- Is this a JPEG image (DCTDecode filter)?
		do
			Result := attached filter_name as fn and then fn.same_string ("DCTDecode")
		end

	is_flate_compressed: BOOLEAN
			-- Is this a FlateDecode compressed image?
		do
			Result := attached filter_name as fn and then fn.same_string ("FlateDecode")
		end

feature {NONE} -- Implementation

	extract_properties
			-- Extract image properties from stream dictionary.
		local
			dict: PDF_DICTIONARY
		do
			dict := stream_dictionary

				-- Width (required)
			if attached {PDF_NUMBER} dict.item ("Width") as w then
				width := w.int_value
			end

				-- Height (required)
			if attached {PDF_NUMBER} dict.item ("Height") as h then
				height := h.int_value
			end

				-- BitsPerComponent (required for most images)
			if attached {PDF_NUMBER} dict.item ("BitsPerComponent") as bpc then
				bits_per_component := bpc.int_value
			else
				bits_per_component := 8  -- Default for most color spaces
			end

				-- ColorSpace (can be name or array)
			if attached {PDF_NAME} dict.item ("ColorSpace") as cs_name then
				color_space_name := cs_name.value
			end

				-- ImageMask
			if attached {PDF_BOOLEAN} dict.item ("ImageMask") as im then
				is_image_mask := im.value
			end

				-- Filter (can be name or array)
			if attached {PDF_NAME} dict.item ("Filter") as filter then
				filter_name := filter.value
			elseif attached {PDF_ARRAY} dict.item ("Filter") as filter_array then
				if filter_array.count > 0 then
					if attached {PDF_NAME} filter_array.item (1) as first_filter then
						filter_name := first_filter.value
					end
				end
			end
		end

invariant
	valid_subtype: subtype.same_string ("Image")

end
