note
	description: "[
		BSON_VALUE represents a value in BSON (Binary JSON).
		A value can be:
			* a double (64-bit IEEE 754 floating point)
			* a string (UTF-8)
			* a document (embedded document)
			* an array
			* binary data
			* an ObjectId (12 bytes)
			* a boolean
			* a UTC datetime
			* null
			* a regular expression
			* JavaScript code
			* a 32-bit integer
			* a timestamp
			* a 64-bit integer
			* a Decimal128
			* Min key / Max key
	]"
	date: "$Date$"
	revision: "$Revision$"
	EIS: "name=BSON Specification", "protocol=URI", "src=https://bsonspec.org/spec.html"

deferred class
	BSON_VALUE

inherit
	HASHABLE

	DEBUG_OUTPUT

feature -- Status report

	is_string: BOOLEAN
			-- Is Current a string value?
		do
		end

	is_double: BOOLEAN
			-- Is Current a double value?
		do
		end

	is_document: BOOLEAN
			-- Is Current a document value?
		do
		end

	is_array: BOOLEAN
			-- Is Current an array value?
		do
		end

	is_binary: BOOLEAN
			-- Is Current a binary value?
		do
		end

	is_object_id: BOOLEAN
			-- Is Current an ObjectId value?
		do
		end

	is_boolean: BOOLEAN
			-- Is Current a boolean value?
		do
		end

	is_datetime: BOOLEAN
			-- Is Current a UTC datetime value?
		do
		end

	is_null: BOOLEAN
			-- Is Current a null value?
		do
		end

	is_regex: BOOLEAN
			-- Is Current a regular expression value?
		do
		end

	is_javascript: BOOLEAN
			-- Is Current a JavaScript code value?
		do
		end

	is_int32: BOOLEAN
			-- Is Current a 32-bit integer value?
		do
		end

	is_timestamp: BOOLEAN
			-- Is Current a timestamp value?
		do
		end

	is_int64: BOOLEAN
			-- Is Current a 64-bit integer value?
		do
		end

	is_decimal128: BOOLEAN
			-- Is Current a Decimal128 value?
		do
		end

	is_min_key: BOOLEAN
			-- Is Current a Min key value?
		do
		end

	is_max_key: BOOLEAN
			-- Is Current a Max key value?
		do
		end

feature -- Access

	bson_type: INTEGER_8
			-- BSON type code for this value.
		deferred
		end

feature -- Visitor pattern

	accept (a_visitor: BSON_VISITOR)
			-- Accept `a_visitor'.
			-- (Call `visit_*' procedure on `a_visitor'.)
		require
			a_visitor_not_void: a_visitor /= Void
		deferred
		end

note
	copyright: "2026, Jocelyn Fiat and Eiffel Software"
	license: "MIT License"
end
