note
	description: "Tests for BSON_DOCUMENT class."
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_BSON_DOCUMENT

inherit
	EQA_TEST_SET

feature -- Tests

	test_empty_document
			-- Test empty document creation.
		local
			doc: BSON_DOCUMENT
		do
			create doc.make_empty
			assert ("is_empty", doc.is_empty)
			assert ("count_zero", doc.count = 0)
			assert ("is_document", doc.is_document)
		end

	test_document_put_and_get
			-- Test putting and getting values.
		local
			doc: BSON_DOCUMENT
		do
			create doc.make_empty

			doc.put_string ("Hello", "greeting")
			assert ("has_greeting", doc.has_key ("greeting"))
			assert ("greeting_value", attached doc.string_value ("greeting") as s and then s.same_string ("Hello"))

			doc.put_int32 (42, "number")
			assert ("has_number", doc.has_key ("number"))
			assert ("number_value", doc.int32_value ("number") = 42)

			doc.put_boolean (True, "flag")
			assert ("has_flag", doc.has_key ("flag"))
			assert ("flag_value", doc.boolean_value ("flag") = True)

			assert ("count_three", doc.count = 3)
		end

	test_document_replace
			-- Test replacing values.
		local
			doc: BSON_DOCUMENT
		do
			create doc.make_empty
			doc.put_string ("original", "key")
			assert ("original_value", attached doc.string_value ("key") as s and then s.same_string ("original"))

			doc.replace_with_string ("replaced", "key")
			assert ("replaced_value", attached doc.string_value ("key") as s and then s.same_string ("replaced"))

			assert ("count_one", doc.count = 1)
		end

	test_document_remove
			-- Test removing values.
		local
			doc: BSON_DOCUMENT
		do
			create doc.make_empty
			doc.put_string ("value1", "key1")
			doc.put_string ("value2", "key2")
			assert ("count_two", doc.count = 2)

			doc.remove ("key1")
			assert ("key1_removed", not doc.has_key ("key1"))
			assert ("key2_exists", doc.has_key ("key2"))
			assert ("count_one", doc.count = 1)
		end

	test_nested_document
			-- Test nested documents.
		local
			doc, nested: BSON_DOCUMENT
		do
			create nested.make_empty
			nested.put_string ("nested_value", "nested_key")

			create doc.make_empty
			doc.put (nested, "nested")

			assert ("has_nested", doc.has_key ("nested"))
			assert ("nested_is_document", attached doc.document_item ("nested") as d and then d.has_key ("nested_key"))
		end

	test_document_wipe_out
			-- Test wiping out document.
		local
			doc: BSON_DOCUMENT
		do
			create doc.make_empty
			doc.put_string ("value", "key")
			assert ("not_empty", not doc.is_empty)

			doc.wipe_out
			assert ("is_empty", doc.is_empty)
		end

note
	copyright: "2026, Jocelyn Fiat and Eiffel Software"
	license: "MIT License"
end
