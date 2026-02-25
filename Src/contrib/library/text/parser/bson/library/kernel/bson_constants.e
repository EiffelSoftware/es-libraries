note
	description: "BSON type constants as defined in the BSON specification."
	date: "$Date$"
	revision: "$Revision$"
	EIS: "name=BSON Specification", "protocol=URI", "src=https://bsonspec.org/spec.html"

class
	BSON_CONSTANTS

feature -- BSON Type Codes

	bson_type_double: INTEGER_8 = 0x01
			-- 64-bit binary floating point

	bson_type_string: INTEGER_8 = 0x02
			-- UTF-8 string

	bson_type_document: INTEGER_8 = 0x03
			-- Embedded document

	bson_type_array: INTEGER_8 = 0x04
			-- Array

	bson_type_binary: INTEGER_8 = 0x05
			-- Binary data

	bson_type_undefined: INTEGER_8 = 0x06
			-- Undefined (deprecated)

	bson_type_object_id: INTEGER_8 = 0x07
			-- ObjectId (12 bytes)

	bson_type_boolean: INTEGER_8 = 0x08
			-- Boolean

	bson_type_datetime: INTEGER_8 = 0x09
			-- UTC datetime (int64 milliseconds since Unix epoch)

	bson_type_null: INTEGER_8 = 0x0A
			-- Null value

	bson_type_regex: INTEGER_8 = 0x0B
			-- Regular expression

	bson_type_db_pointer: INTEGER_8 = 0x0C
			-- DBPointer (deprecated)

	bson_type_javascript: INTEGER_8 = 0x0D
			-- JavaScript code

	bson_type_symbol: INTEGER_8 = 0x0E
			-- Symbol (deprecated)

	bson_type_javascript_with_scope: INTEGER_8 = 0x0F
			-- JavaScript code with scope (deprecated)

	bson_type_int32: INTEGER_8 = 0x10
			-- 32-bit integer

	bson_type_timestamp: INTEGER_8 = 0x11
			-- Timestamp (used internally by MongoDB)

	bson_type_int64: INTEGER_8 = 0x12
			-- 64-bit integer

	bson_type_decimal128: INTEGER_8 = 0x13
			-- 128-bit decimal floating point

	bson_type_min_key: INTEGER_8 = 0xFF
			-- Min key (compares lower than all other values)

	bson_type_max_key: INTEGER_8 = 0x7F
			-- Max key (compares higher than all other values)

feature -- Binary Subtypes

	binary_subtype_generic: NATURAL_8 = 0x00
			-- Generic binary subtype (default)

	binary_subtype_function: NATURAL_8 = 0x01
			-- Function

	binary_subtype_binary_old: NATURAL_8 = 0x02
			-- Binary (old, deprecated)

	binary_subtype_uuid_old: NATURAL_8 = 0x03
			-- UUID (old, deprecated)

	binary_subtype_uuid: NATURAL_8 = 0x04
			-- UUID

	binary_subtype_md5: NATURAL_8 = 0x05
			-- MD5

	binary_subtype_encrypted: NATURAL_8 = 0x06
			-- Encrypted BSON value

	binary_subtype_compressed: NATURAL_8 = 0x07
			-- Compressed BSON column

	binary_subtype_sensitive: NATURAL_8 = 0x08
			-- Sensitive

	binary_subtype_vector: NATURAL_8 = 0x09
			-- Vector

note
	copyright: "2026, Jocelyn Fiat and Eiffel Software"
	license: "MIT License"
end
