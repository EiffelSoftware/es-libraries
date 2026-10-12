note
	description: "[
		DCTDecode filter implementation for PDF streams.
		Implements JPEG decompression per ISO 32000-1:2008 §7.4.8.
		
		DCTDecode is used for JPEG-compressed image data in PDFs.
		Supports baseline and progressive JPEG (via stb_image).
	]"
	spec_reference: "ISO 32000-1:2008 Section 7.4.8 (DCTDecode Filter)"
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_DCT_DECODER

create
	make

feature -- Initialization

	make
			-- Create a new DCTDecode decoder.
		do
			-- Nothing to initialize
		end

feature -- Status

	last_error_message: detachable STRING_8
			-- Error message from last decode operation (Void if successful)

	has_error_message: BOOLEAN
			-- Is an error message available?
		do
			Result := last_error_message /= Void
		end

feature -- Access

	image_width: INTEGER
			-- Width of last successfully decoded image in pixels

	image_height: INTEGER
			-- Height of last successfully decoded image in pixels

	image_components: INTEGER
			-- Number of color components in decoded image
			-- 1 = Grayscale
			-- 3 = RGB
			-- 4 = RGBA (rare for JPEG)

feature -- Basic Operations

	decode (compressed_data: STRING_8): detachable STRING_8
			-- Decode DCTDecode (JPEG) compressed data.
			-- Returns decompressed raw pixel data, or Void if decompression fails.
			-- Check `last_error_message` for failure details.
			-- Check `image_width`, `image_height`, `image_components` for image metadata.
		require
			data_not_empty: not compressed_data.is_empty
			reasonable_size: compressed_data.count < 100_000_000  -- 100MB limit
		local
			decompressor: JPEG_UNCOMPRESS
		do
			last_error_message := Void
			image_width := 0
			image_height := 0
			image_components := 0

			create decompressor
			decompressor.uncompress_jpeg (compressed_data)

			if decompressor.is_last_operation_ok then
				Result := decompressor.last_uncompressed_data
				image_width := decompressor.image_width
				image_height := decompressor.image_height
				image_components := decompressor.image_components
			else
					-- Capture error details
				Result := Void
				if attached decompressor.last_error_message as err then
					last_error_message := err.twin
				else
					last_error_message := "JPEG decompression failed (unknown reason)"
				end
			end
		ensure
			failure_means_error: (Result = Void) implies has_error_message
			success_means_metadata: (Result /= Void) implies (image_width > 0 and image_height > 0)
		end

	decode_with_params (compressed_data: STRING_8; params: PDF_DICTIONARY): detachable STRING_8
			-- Decode DCTDecode compressed data with DecodeParms.
			-- Per ISO 32000-1:2008 §7.4.8, DCTDecode supports:
			--   ColorTransform: 0 = RGB, 1 = YCbCr (default handled by decoder)
			-- Returns Void if decompression fails.
		require
			data_not_empty: not compressed_data.is_empty
			params_valid: params /= Void
		local
			color_transform: INTEGER
		do
				-- Check for ColorTransform parameter (0=RGB, 1=YCbCr)
				-- stb_image handles this automatically based on JPEG markers
			if attached {PDF_NUMBER} params.item ("ColorTransform") as ct then
				color_transform := ct.int_value
					-- Currently stb_image handles this internally
					-- Future: could pass to decoder if needed
			end

				-- Decode using standard method
				-- stb_image handles color space conversion automatically
			Result := decode (compressed_data)
		ensure
			failure_means_error: (Result = Void) implies has_error_message
		end

end
