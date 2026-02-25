note
	description: "Tests for BSON parsing and writing roundtrip."
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_BSON_ROUNDTRIP

inherit
	EQA_TEST_SET

feature -- Roundtrip tests

	test_simple_document_roundtrip
			-- Test writing and parsing a simple document.
		local
			doc, parsed_doc: BSON_DOCUMENT
			writer: BSON_WRITER_TO_BYTES
			parser: BSON_PARSER
			bytes: ARRAY [NATURAL_8]
		do
			create doc.make_empty
			doc.put_string ("Hello", "greeting")
			doc.put_int32 (42, "number")
			doc.put_boolean (True, "flag")

			create writer.make
			bytes := writer.to_bytes (doc)

			create parser.make
			parsed_doc := parser.parse (bytes)

			assert ("parsed_not_void", parsed_doc /= Void)
			if attached parsed_doc as pd then
				assert ("has_greeting", pd.has_key ("greeting"))
				assert ("greeting_value", attached pd.string_value ("greeting") as s and then s.same_string ("Hello"))
				assert ("has_number", pd.has_key ("number"))
				assert ("number_value", pd.int32_value ("number") = 42)
				assert ("has_flag", pd.has_key ("flag"))
				assert ("flag_value", pd.boolean_value ("flag") = True)
			end
		end

	test_nested_document_roundtrip
			-- Test writing and parsing nested documents.
		local
			doc, nested, parsed_doc: BSON_DOCUMENT
			writer: BSON_WRITER_TO_BYTES
			parser: BSON_PARSER
			bytes: ARRAY [NATURAL_8]
		do
			create nested.make_empty
			nested.put_string ("inner_value", "inner_key")

			create doc.make_empty
			doc.put (nested, "nested")
			doc.put_string ("outer_value", "outer_key")

			create writer.make
			bytes := writer.to_bytes (doc)

			create parser.make
			parsed_doc := parser.parse (bytes)

			assert ("parsed_not_void", parsed_doc /= Void)
			if attached parsed_doc as pd then
				assert ("has_nested", pd.has_key ("nested"))
				assert ("has_outer_key", pd.has_key ("outer_key"))
				if attached pd.document_item ("nested") as nd then
					assert ("nested_has_inner", nd.has_key ("inner_key"))
					assert ("inner_value", attached nd.string_value ("inner_key") as s and then s.same_string ("inner_value"))
				else
					assert ("nested_is_document", False)
				end
			end
		end

	test_array_roundtrip
			-- Test writing and parsing arrays.
		local
			doc, parsed_doc: BSON_DOCUMENT
			arr: BSON_ARRAY
			writer: BSON_WRITER_TO_BYTES
			parser: BSON_PARSER
			bytes: ARRAY [NATURAL_8]
		do
			create arr.make_empty
			arr.extend_string ("one")
			arr.extend_string ("two")
			arr.extend_string ("three")

			create doc.make_empty
			doc.put (arr, "items")

			create writer.make
			bytes := writer.to_bytes (doc)

			create parser.make
			parsed_doc := parser.parse (bytes)

			assert ("parsed_not_void", parsed_doc /= Void)
			if attached parsed_doc as pd then
				assert ("has_items", pd.has_key ("items"))
				if attached pd.array_item ("items") as pa then
					assert ("array_count", pa.count = 3)
					assert ("first_is_string", pa [1].is_string)
				else
					assert ("items_is_array", False)
				end
			end
		end

	test_all_types_roundtrip
			-- Test roundtrip of all supported types.
		local
			doc, parsed_doc: BSON_DOCUMENT
			writer: BSON_WRITER_TO_BYTES
			parser: BSON_PARSER
			bytes: ARRAY [NATURAL_8]
			bin_data: ARRAY [NATURAL_8]
		do
			create doc.make_empty
			doc.put_string ("test", "str")
			doc.put_int32 (-123, "i32")
			doc.put_int64 (9876543210, "i64")
			doc.put_double (3.14159, "dbl")
			doc.put_boolean (True, "bool")
			doc.put_null ("null")

			bin_data := <<1, 2, 3, 4, 5>>
			doc.put (create {BSON_BINARY}.make (bin_data), "binary")
			doc.put (create {BSON_OBJECT_ID}.make_from_hex_string ("507f1f77bcf86cd799439011"), "oid")
			doc.put (create {BSON_DATETIME}.make (1234567890000), "datetime")
			doc.put (create {BSON_TIMESTAMP}.make (1234567890, 1), "timestamp")
			doc.put (create {BSON_REGEX}.make_with_options ("^test$", "i"), "regex")
			doc.put (create {BSON_JAVASCRIPT}.make ("return 1;"), "js")
			doc.put (create {BSON_MIN_KEY}, "minkey")
			doc.put (create {BSON_MAX_KEY}, "maxkey")

			create writer.make
			bytes := writer.to_bytes (doc)

			create parser.make
			parsed_doc := parser.parse (bytes)

			assert ("parsed_not_void", parsed_doc /= Void)
			if attached parsed_doc as pd then
				assert ("has_str", pd.has_key ("str"))
				assert ("has_i32", pd.has_key ("i32"))
				assert ("has_i64", pd.has_key ("i64"))
				assert ("has_dbl", pd.has_key ("dbl"))
				assert ("has_bool", pd.has_key ("bool"))
				assert ("has_null", pd.has_key ("null"))
				assert ("has_binary", pd.has_key ("binary"))
				assert ("has_oid", pd.has_key ("oid"))
				assert ("has_datetime", pd.has_key ("datetime"))
				assert ("has_timestamp", pd.has_key ("timestamp"))
				assert ("has_regex", pd.has_key ("regex"))
				assert ("has_js", pd.has_key ("js"))
				assert ("has_minkey", pd.has_key ("minkey"))
				assert ("has_maxkey", pd.has_key ("maxkey"))

				assert ("str_value", attached pd.string_value ("str") as s and then s.same_string ("test"))
				assert ("i32_value", pd.int32_value ("i32") = -123)
				assert ("i64_value", pd.int64_value ("i64") = 9876543210)
				assert ("bool_value", pd.boolean_value ("bool") = True)
				assert ("null_is_null", attached {BSON_NULL} pd.item ("null"))
				assert ("minkey_is_minkey", attached {BSON_MIN_KEY} pd.item ("minkey"))
				assert ("maxkey_is_maxkey", attached {BSON_MAX_KEY} pd.item ("maxkey"))
			end
		end

	test_empty_document_roundtrip
			-- Test roundtrip of empty document.
		local
			doc, parsed_doc: BSON_DOCUMENT
			writer: BSON_WRITER_TO_BYTES
			parser: BSON_PARSER
			bytes: ARRAY [NATURAL_8]
		do
			create doc.make_empty

			create writer.make
			bytes := writer.to_bytes (doc)

			-- Empty document should be 5 bytes: int32(5) + terminator(0)
			assert ("empty_doc_size", bytes.count = 5)

			create parser.make
			parsed_doc := parser.parse (bytes)

			assert ("parsed_not_void", parsed_doc /= Void)
			if attached parsed_doc as pd then
				assert ("is_empty", pd.is_empty)
			end
		end

note
	copyright: "2026, Jocelyn Fiat and Eiffel Software"
	license: "MIT License"
end
