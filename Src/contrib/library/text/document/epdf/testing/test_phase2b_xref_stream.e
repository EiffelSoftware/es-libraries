note
	description: "Test suite for Phase 2B: Cross-Reference Streams support."
	testing: "type/manual/expert"

class
	TEST_PHASE2B_XREF_STREAM

inherit
	EQA_TEST_SET
	TEST_PATH_HELPER

feature -- Test: FlateDecode

	test_flate_decoder_basic
			-- Test basic FlateDecode decompression.
		local
			decoder: PDF_FLATE_DECODER
			decompressed: detachable STRING_8
			compressor: ZLIB_COMPRESS
		do
			create decoder.make
			create compressor

				-- Compress a test string
			compressor.compress_string ("Hello, PDF World!")
			if compressor.is_last_operation_ok and then attached compressor.last_compressed_string as l_compressed then

					-- Decompress it
				decompressed := decoder.decode (l_compressed)

				assert ("decompression succeeded", decompressed /= Void)
				if decompressed /= Void then
					assert ("correct decompression", decompressed.is_equal ("Hello, PDF World!"))
				end
			end
		end

feature -- Test: XRef Stream Parsing

	test_xref_stream_detection
			-- Test detection of XRef stream type.
		local
			stream: PDF_STREAM
			dict: PDF_DICTIONARY
			xref_stream: PDF_XREF_STREAM
		do
			create dict.make (5)
			dict.put_name ("XRef", "Type")
			dict.put_number (10, "Size")

			create stream.make_with_dictionary (dict, "dummy content")
			create xref_stream.make (stream)

			assert ("is xref stream", xref_stream.is_xref_stream)
			assert ("correct size", xref_stream.size = 10)
		end

	test_xref_stream_w_array
			-- Test parsing of /W array.
		local
			stream: PDF_STREAM
			dict: PDF_DICTIONARY
			xref_stream: PDF_XREF_STREAM
			w_arr: PDF_ARRAY
			w: detachable ARRAY [INTEGER]
		do
			create dict.make (5)
			dict.put_name ("XRef", "Type")
			dict.put_number (10, "Size")

				-- Create /W array [1 2 1]
			create w_arr.make (3)
			w_arr.add_number (1)
			w_arr.add_number (2)
			w_arr.add_number (1)
			dict.put (w_arr, "W")

			create stream.make_with_dictionary (dict, "dummy content")
			create xref_stream.make (stream)

			w := xref_stream.w_array
			assert ("w array exists", w /= Void)
			if w /= Void then
				assert ("w has 3 elements", w.count = 3)
				assert ("w[1] = 1", w [1] = 1)
				assert ("w[2] = 2", w [2] = 2)
				assert ("w[3] = 1", w [3] = 1)
			end
		end

	test_xref_stream_index
			-- Test parsing of /Index array.
		local
			stream: PDF_STREAM
			dict: PDF_DICTIONARY
			xref_stream: PDF_XREF_STREAM
			idx_arr: PDF_ARRAY
			idx: detachable ARRAY [INTEGER]
		do
			create dict.make (5)
			dict.put_name ("XRef", "Type")
			dict.put_number (10, "Size")

				-- Create /Index array [0 5]
			create idx_arr.make (2)
			idx_arr.add_number (0)
			idx_arr.add_number (5)
			dict.put (idx_arr, "Index")

			create stream.make_with_dictionary (dict, "dummy content")
			create xref_stream.make (stream)

			idx := xref_stream.index
			assert ("index exists", idx /= Void)
			if idx /= Void then
				assert ("index has 2 elements", idx.count = 2)
				assert ("index[1] = 0", idx [1] = 0)
				assert ("index[2] = 5", idx [2] = 5)
			end
		end

	test_xref_stream_trailer_entries
			-- Test extraction of trailer entries from XRef stream dictionary.
		local
			stream: PDF_STREAM
			dict: PDF_DICTIONARY
			xref_stream: PDF_XREF_STREAM
			root_ref: PDF_REFERENCE
			root_id: PDF_OBJECT_ID
		do
			create dict.make (5)
			dict.put_name ("XRef", "Type")
			dict.put_number (10, "Size")

				-- Add /Root reference
			create root_id.make (1, 0)
			create root_ref.make (root_id)
			dict.put (root_ref, "Root")

			create stream.make_with_dictionary (dict, "dummy content")
			create xref_stream.make (stream)

			assert ("has root", xref_stream.root /= Void)
			if attached xref_stream.root as root then
				assert ("root object number is 1", root.object_id.object_number = 1)
			end
		end


end
