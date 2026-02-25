note
	description: "Tests for BSON primitive and special types."
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_BSON_TYPES

inherit
	EQA_TEST_SET

feature -- String tests

	test_bson_string
			-- Test BSON_STRING.
		local
			s: BSON_STRING
		do
			create s.make_from_string ("Hello, World!")
			assert ("is_string", s.is_string)
			assert ("value_correct", s.value.same_string ("Hello, World!"))
			assert ("same_string", s.same_string ("Hello, World!"))
		end

	test_bson_string_unicode
			-- Test BSON_STRING with Unicode.
		local
			s: BSON_STRING
			unicode: STRING_32
		do
			unicode := {STRING_32} "Hello, 世界! 🌍"
			create s.make_from_string_32 (unicode)
			assert ("value_correct", s.value.same_string (unicode))
		end

feature -- Number tests

	test_bson_int32
			-- Test BSON_INT32.
		local
			i: BSON_INT32
		do
			create i.make (42)
			assert ("is_int32", i.is_int32)
			assert ("value_correct", i.value = 42)

			create i.make (-2147483648)
			assert ("min_value", i.value = {INTEGER_32}.Min_value)

			create i.make (2147483647)
			assert ("max_value", i.value = {INTEGER_32}.Max_value)
		end

	test_bson_int64
			-- Test BSON_INT64.
		local
			i: BSON_INT64
		do
			create i.make (9223372036854775807)
			assert ("is_int64", i.is_int64)
			assert ("max_value", i.value = {INTEGER_64}.Max_value)
		end

	test_bson_double
			-- Test BSON_DOUBLE.
		local
			d: BSON_DOUBLE
		do
			create d.make (3.14159)
			assert ("is_double", d.is_double)
			assert ("value_correct", (d.value - 3.14159).abs < 0.00001)
		end

feature -- Boolean and Null tests

	test_bson_boolean
			-- Test BSON_BOOLEAN.
		local
			bt, bf: BSON_BOOLEAN
		do
			create bt.make_true
			assert ("is_boolean", bt.is_boolean)
			assert ("is_true", bt.value = True)

			create bf.make_false
			assert ("is_false", bf.value = False)
		end

	test_bson_null
			-- Test BSON_NULL.
		local
			n: BSON_NULL
		do
			create n
			assert ("is_null", n.is_null)
		end

feature -- ObjectId tests

	test_bson_object_id_from_hex
			-- Test BSON_OBJECT_ID from hex string.
		local
			oid: BSON_OBJECT_ID
		do
			create oid.make_from_hex_string ("507f1f77bcf86cd799439011")
			assert ("is_object_id", oid.is_object_id)
			assert ("hex_roundtrip", oid.to_hex_string.is_case_insensitive_equal ("507f1f77bcf86cd799439011"))
		end

	test_bson_object_id_new
			-- Test creating new BSON_OBJECT_ID.
		local
			oid: BSON_OBJECT_ID
		do
			create oid.make_new
			assert ("is_object_id", oid.is_object_id)
			assert ("bytes_count", oid.bytes.count = 12)
			assert ("hex_length", oid.to_hex_string.count = 24)
		end

feature -- Binary tests

	test_bson_binary
			-- Test BSON_BINARY.
		local
			bin: BSON_BINARY
			data: ARRAY [NATURAL_8]
		do
			data := <<1, 2, 3, 4, 5>>
			create bin.make (data)
			assert ("is_binary", bin.is_binary)
			assert ("is_generic", bin.is_generic)
			assert ("count", bin.count = 5)
		end

	test_bson_binary_uuid
			-- Test BSON_BINARY UUID.
		local
			bin: BSON_BINARY
			uuid_bytes: ARRAY [NATURAL_8]
		do
			uuid_bytes := <<0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15>>
			create bin.make_uuid (uuid_bytes)
			assert ("is_uuid", bin.is_uuid)
		end

feature -- DateTime tests

	test_bson_datetime
			-- Test BSON_DATETIME.
		local
			dt: BSON_DATETIME
		do
			create dt.make (1234567890000)
			assert ("is_datetime", dt.is_datetime)
			assert ("milliseconds", dt.milliseconds = 1234567890000)
			assert ("seconds", dt.seconds = 1234567890)
		end

	test_bson_datetime_now
			-- Test BSON_DATETIME.make_now.
		local
			dt: BSON_DATETIME
		do
			create dt.make_now
			assert ("is_datetime", dt.is_datetime)
			assert ("positive_ms", dt.milliseconds > 0)
		end

feature -- Timestamp tests

	test_bson_timestamp
			-- Test BSON_TIMESTAMP.
		local
			ts: BSON_TIMESTAMP
		do
			create ts.make (1234567890, 42)
			assert ("is_timestamp", ts.is_timestamp)
			assert ("timestamp", ts.timestamp = 1234567890)
			assert ("increment", ts.increment = 42)
		end

feature -- Regex tests

	test_bson_regex
			-- Test BSON_REGEX.
		local
			rx: BSON_REGEX
		do
			create rx.make_with_options ("^test.*$", "im")
			assert ("is_regex", rx.is_regex)
			assert ("pattern", rx.pattern.same_string ("^test.*$"))
			assert ("is_case_insensitive", rx.is_case_insensitive)
			assert ("is_multiline", rx.is_multiline)
		end

feature -- JavaScript tests

	test_bson_javascript
			-- Test BSON_JAVASCRIPT.
		local
			js: BSON_JAVASCRIPT
		do
			create js.make ("function() { return 42; }")
			assert ("is_javascript", js.is_javascript)
			assert ("code", js.code.same_string ("function() { return 42; }"))
		end

feature -- MinKey/MaxKey tests

	test_bson_min_key
			-- Test BSON_MIN_KEY.
		local
			mk: BSON_MIN_KEY
		do
			create mk
			assert ("is_min_key", mk.is_min_key)
		end

	test_bson_max_key
			-- Test BSON_MAX_KEY.
		local
			mk: BSON_MAX_KEY
		do
			create mk
			assert ("is_max_key", mk.is_max_key)
		end

note
	copyright: "2026, Jocelyn Fiat and Eiffel Software"
	license: "MIT License"
end
