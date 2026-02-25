note
	description: "[
		BSON_ITERATOR provides a default implementation of BSON_VISITOR
		that recursively iterates through all nested documents and arrays.
		
		Override specific visit_* methods to process values of interest.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	BSON_ITERATOR

inherit
	BSON_VISITOR

feature -- Visitor

	visit_bson_document (a_document: BSON_DOCUMENT)
			-- Visit BSON document and recurse into elements.
		do
			across a_document as c loop
				c.accept (Current)
			end
		end

	visit_bson_array (an_array: BSON_ARRAY)
			-- Visit BSON array and recurse into elements.
		do
			across an_array as c loop
				c.accept (Current)
			end
		end

	visit_bson_string (a_string: BSON_STRING)
			-- Visit BSON string.
		do
			-- Override in descendants
		end

	visit_bson_double (a_double: BSON_DOUBLE)
			-- Visit BSON double.
		do
			-- Override in descendants
		end

	visit_bson_int32 (an_int32: BSON_INT32)
			-- Visit BSON int32.
		do
			-- Override in descendants
		end

	visit_bson_int64 (an_int64: BSON_INT64)
			-- Visit BSON int64.
		do
			-- Override in descendants
		end

	visit_bson_boolean (a_boolean: BSON_BOOLEAN)
			-- Visit BSON boolean.
		do
			-- Override in descendants
		end

	visit_bson_null (a_null: BSON_NULL)
			-- Visit BSON null.
		do
			-- Override in descendants
		end

	visit_bson_binary (a_binary: BSON_BINARY)
			-- Visit BSON binary.
		do
			-- Override in descendants
		end

	visit_bson_object_id (an_object_id: BSON_OBJECT_ID)
			-- Visit BSON ObjectId.
		do
			-- Override in descendants
		end

	visit_bson_datetime (a_datetime: BSON_DATETIME)
			-- Visit BSON datetime.
		do
			-- Override in descendants
		end

	visit_bson_timestamp (a_timestamp: BSON_TIMESTAMP)
			-- Visit BSON timestamp.
		do
			-- Override in descendants
		end

	visit_bson_regex (a_regex: BSON_REGEX)
			-- Visit BSON regex.
		do
			-- Override in descendants
		end

	visit_bson_javascript (a_javascript: BSON_JAVASCRIPT)
			-- Visit BSON JavaScript.
		do
			-- Override in descendants
		end

	visit_bson_min_key (a_min_key: BSON_MIN_KEY)
			-- Visit BSON min key.
		do
			-- Override in descendants
		end

	visit_bson_max_key (a_max_key: BSON_MAX_KEY)
			-- Visit BSON max key.
		do
			-- Override in descendants
		end

note
	copyright: "2026, Jocelyn Fiat and Eiffel Software"
	license: "MIT License"
end
