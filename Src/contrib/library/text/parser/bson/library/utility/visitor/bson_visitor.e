note
	description: "Visitor pattern for BSON values."
	date: "$Date$"
	revision: "$Revision$"

deferred class
	BSON_VISITOR

feature -- Visitor

	visit_bson_document (a_document: BSON_DOCUMENT)
			-- Visit BSON document.
		require
			a_document_not_void: a_document /= Void
		deferred
		end

	visit_bson_array (an_array: BSON_ARRAY)
			-- Visit BSON array.
		require
			an_array_not_void: an_array /= Void
		deferred
		end

	visit_bson_string (a_string: BSON_STRING)
			-- Visit BSON string.
		require
			a_string_not_void: a_string /= Void
		deferred
		end

	visit_bson_double (a_double: BSON_DOUBLE)
			-- Visit BSON double.
		require
			a_double_not_void: a_double /= Void
		deferred
		end

	visit_bson_int32 (an_int32: BSON_INT32)
			-- Visit BSON 32-bit integer.
		require
			an_int32_not_void: an_int32 /= Void
		deferred
		end

	visit_bson_int64 (an_int64: BSON_INT64)
			-- Visit BSON 64-bit integer.
		require
			an_int64_not_void: an_int64 /= Void
		deferred
		end

	visit_bson_boolean (a_boolean: BSON_BOOLEAN)
			-- Visit BSON boolean.
		require
			a_boolean_not_void: a_boolean /= Void
		deferred
		end

	visit_bson_null (a_null: BSON_NULL)
			-- Visit BSON null.
		require
			a_null_not_void: a_null /= Void
		deferred
		end

	visit_bson_binary (a_binary: BSON_BINARY)
			-- Visit BSON binary.
		require
			a_binary_not_void: a_binary /= Void
		deferred
		end

	visit_bson_object_id (an_object_id: BSON_OBJECT_ID)
			-- Visit BSON ObjectId.
		require
			an_object_id_not_void: an_object_id /= Void
		deferred
		end

	visit_bson_datetime (a_datetime: BSON_DATETIME)
			-- Visit BSON datetime.
		require
			a_datetime_not_void: a_datetime /= Void
		deferred
		end

	visit_bson_timestamp (a_timestamp: BSON_TIMESTAMP)
			-- Visit BSON timestamp.
		require
			a_timestamp_not_void: a_timestamp /= Void
		deferred
		end

	visit_bson_regex (a_regex: BSON_REGEX)
			-- Visit BSON regular expression.
		require
			a_regex_not_void: a_regex /= Void
		deferred
		end

	visit_bson_javascript (a_javascript: BSON_JAVASCRIPT)
			-- Visit BSON JavaScript code.
		require
			a_javascript_not_void: a_javascript /= Void
		deferred
		end

	visit_bson_min_key (a_min_key: BSON_MIN_KEY)
			-- Visit BSON min key.
		require
			a_min_key_not_void: a_min_key /= Void
		deferred
		end

	visit_bson_max_key (a_max_key: BSON_MAX_KEY)
			-- Visit BSON max key.
		require
			a_max_key_not_void: a_max_key /= Void
		deferred
		end

note
	copyright: "2026, Jocelyn Fiat and Eiffel Software"
	license: "MIT License"
end
