note
	description: "[
		BSON to JSON visitor that outputs JSON representation using MongoDB Extended JSON format.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	BSON_JSON_VISITOR

inherit
	BSON_VISITOR

create
	make_with_writer

feature {NONE} -- Initialization

	make_with_writer (a_writer: JSON_STREAM_WRITER)
		do
			writer := a_writer
		end

feature -- Access

	writer: JSON_STREAM_WRITER

feature -- Visitor

	visit_bson_document (a_doc: BSON_DOCUMENT)
		do
			writer.enter_object
			across a_doc as i loop
				visit_element ((@i.key), i)
			end
			writer.leave_object
		end

	visit_bson_array (a_arr: BSON_ARRAY)
		do
			writer.enter_array
			across a_arr as i loop
				i.accept (Current)
			end
			writer.leave_array
		end

	visit_bson_string (a_str: BSON_STRING)
		do
			writer.put_string_value (a_str.value)
		end

	visit_bson_double (a_double: BSON_DOUBLE)
		do
			writer.put_real_64_value (a_double.value)
		end

	visit_bson_boolean (a_bool: BSON_BOOLEAN)
		do
			writer.put_boolean_value (a_bool.value)
		end

	visit_bson_null (a_null: BSON_NULL)
		do
			writer.put_null_value
		end

	visit_bson_int32 (a_int32: BSON_INT32)
		do
			writer.put_integer_64_value (a_int32.value)
		end

	visit_bson_int64 (a_int64: BSON_INT64)
		do
			writer.put_integer_64_value (a_int64.value)
		end

	visit_bson_binary (a_bin: BSON_BINARY)
		do
			-- Extended JSON: {"$binary": {"base64": "encoded", "subType": "xx"}}
			writer.enter_object
			writer.put_property_name ("$binary")
			writer.enter_object
			writer.put_property_name ("base64")
			writer.put_string_value (base64_encode (a_bin.data))
			writer.put_property_name ("subType")
			writer.put_string_value (('0'+ (a_bin.subtype - 1)).out)
			writer.leave_object
			writer.leave_object
		end

	visit_bson_object_id (a_oid: BSON_OBJECT_ID)
		do
			-- Extended JSON: {"$oid": "hexstring"}
			writer.enter_object
			writer.put_property_name ("$oid")
			writer.put_string_value (object_id_to_hex (a_oid))
			writer.leave_object
		end

	visit_bson_datetime (a_dt: BSON_DATETIME)
		do
			-- Extended JSON: {"$date": {"$numberLong": "ms"}}
			writer.enter_object
			writer.put_property_name ("$date")
			writer.enter_object
			writer.put_property_name ("$numberLong")
			writer.put_string_value (a_dt.milliseconds.out)
			writer.leave_object
			writer.leave_object
		end

	visit_bson_regex (a_regex: BSON_REGEX)
		do
			-- Extended JSON: {"$regularExpression": {"pattern": "", "options": ""}}
			writer.enter_object
			writer.put_property_name ("$regularExpression")
			writer.enter_object
			writer.put_property_name ("pattern")
			writer.put_string_value (a_regex.pattern)
			writer.put_property_name ("options")
			writer.put_string_value (a_regex.options)
			writer.leave_object
			writer.leave_object
		end

	visit_bson_javascript (a_js: BSON_JAVASCRIPT)
		do
			-- Extended JSON: {"$code": "code"}
			writer.enter_object
			writer.put_property_name ("$code")
			writer.put_string_value (a_js.code)
			writer.leave_object
		end

	visit_bson_timestamp (a_ts: BSON_TIMESTAMP)
		do
			-- Extended JSON: {"$timestamp": {"t": 0, "i": 0}}
			writer.enter_object
			writer.put_property_name ("$timestamp")
			writer.enter_object
			writer.put_property_name ("t")
			writer.put_integer_64_value (a_ts.seconds.to_integer_64)
			writer.put_property_name ("i")
			writer.put_integer_64_value (a_ts.increment)
			writer.leave_object
			writer.leave_object
		end

	visit_bson_min_key (a_min_key: BSON_MIN_KEY)
		do
			writer.enter_object
			writer.put_property_name ("$minKey")
			writer.put_integer_64_value (1)
			writer.leave_object
		end

	visit_bson_max_key (a_max_key: BSON_MAX_KEY)
		do
			writer.enter_object
			writer.put_property_name ("$maxKey")
			writer.put_integer_64_value (1)
			writer.leave_object
		end

feature {NONE} -- Implementation

	visit_element (a_key: READABLE_STRING_GENERAL; a_val: BSON_VALUE)
		do
			writer.put_property_name (a_key.as_string_32)
			a_val.accept (Current)
		end

	base64_encode (a_data: ARRAY [NATURAL_8]): STRING
		local
			b64: BASE64
			mp: MANAGED_POINTER
		do
			create b64
			create mp.make_from_array (a_data)
			Result := b64.encoded_string (create {STRING_8}.make_from_c_byte_array (mp.item, a_data.count))
		end

	object_id_to_hex (a_oid: BSON_OBJECT_ID): STRING
		do
			Result := a_oid.to_hex_string
		end

note
	copyright: "2026, Jocelyn Fiat and Eiffel Software"
	license: "MIT License"
end
