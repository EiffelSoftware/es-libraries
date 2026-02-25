note
	description: "[
		BSON_BINARY represents binary data in BSON.
		
		In BSON, binary is serialized as:
		int32 subtype (byte*)
		where int32 is the number of bytes, subtype indicates the kind of data.
		
		Subtypes:
		0x00 - Generic binary (default)
		0x01 - Function
		0x02 - Binary (old, deprecated)
		0x03 - UUID (old, deprecated)
		0x04 - UUID
		0x05 - MD5
		0x06 - Encrypted BSON value
		0x07 - Compressed BSON column
		0x08 - Sensitive
		0x09 - Vector
		0x80-0xFF - User-defined
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	BSON_BINARY

inherit
	BSON_VALUE
		redefine
			is_binary
		end

	BSON_CONSTANTS
		undefine
			is_equal
		end

create
	make,
	make_with_subtype,
	make_uuid,
	make_md5

feature {NONE} -- Initialization

	make (a_data: ARRAY [NATURAL_8])
			-- Initialize with `a_data' using generic subtype.
		require
			a_data_not_void: a_data /= Void
		do
			data := a_data
			subtype := binary_subtype_generic
		ensure
			data_set: data = a_data
			generic_subtype: subtype = binary_subtype_generic
		end

	make_with_subtype (a_data: ARRAY [NATURAL_8]; a_subtype: NATURAL_8)
			-- Initialize with `a_data' and `a_subtype'.
		require
			a_data_not_void: a_data /= Void
		do
			data := a_data
			subtype := a_subtype
		ensure
			data_set: data = a_data
			subtype_set: subtype = a_subtype
		end

	make_uuid (a_uuid_bytes: ARRAY [NATURAL_8])
			-- Initialize as UUID with `a_uuid_bytes'.
		require
			a_uuid_bytes_not_void: a_uuid_bytes /= Void
			valid_uuid_size: a_uuid_bytes.count = 16
		do
			data := a_uuid_bytes
			subtype := binary_subtype_uuid
		ensure
			data_set: data = a_uuid_bytes
			uuid_subtype: subtype = binary_subtype_uuid
		end

	make_md5 (a_md5_bytes: ARRAY [NATURAL_8])
			-- Initialize as MD5 with `a_md5_bytes'.
		require
			a_md5_bytes_not_void: a_md5_bytes /= Void
			valid_md5_size: a_md5_bytes.count = 16
		do
			data := a_md5_bytes
			subtype := binary_subtype_md5
		ensure
			data_set: data = a_md5_bytes
			md5_subtype: subtype = binary_subtype_md5
		end

feature -- Status report

	is_binary: BOOLEAN = True
			-- <Precursor>

feature -- Access

	bson_type: INTEGER_8
			-- <Precursor>
		do
			Result := bson_type_binary
		end

	data: ARRAY [NATURAL_8]
			-- Binary data.

	subtype: NATURAL_8
			-- Binary subtype.

	count: INTEGER
			-- Number of bytes.
		do
			Result := data.count
		end

feature -- Status report

	is_generic: BOOLEAN
			-- Is this generic binary?
		do
			Result := subtype = binary_subtype_generic
		end

	is_uuid: BOOLEAN
			-- Is this a UUID?
		do
			Result := subtype = binary_subtype_uuid or subtype = binary_subtype_uuid_old
		end

	is_md5: BOOLEAN
			-- Is this an MD5 hash?
		do
			Result := subtype = binary_subtype_md5
		end

	is_user_defined: BOOLEAN
			-- Is this a user-defined subtype?
		do
			Result := subtype >= 0x80
		end

feature -- Conversion

	to_hex_string: STRING
			-- Hexadecimal string representation of the binary data.
		local
			i: INTEGER
		do
			create Result.make (data.count * 2)
			from
				i := data.lower
			until
				i > data.upper
			loop
				Result.append (data [i].to_hex_string)
				i := i + 1
			end
		ensure
			result_not_void: Result /= Void
			correct_length: Result.count = data.count * 2
		end

feature -- Visitor pattern

	accept (a_visitor: BSON_VISITOR)
			-- Accept `a_visitor'.
		do
			a_visitor.visit_bson_binary (Current)
		end

feature -- Report

	hash_code: INTEGER
			-- Hash code value.
		local
			i: INTEGER
		do
			Result := subtype.to_integer_32
			from
				i := data.lower
			until
				i > data.upper
			loop
				Result := ((Result \\ 8388593) |<< 8) + data [i].to_integer_32
				i := i + 1
			end
		end

feature -- Status report

	debug_output: STRING
			-- String that should be displayed in debugger.
		do
			create Result.make (20)
			Result.append ("Binary(")
			Result.append_integer (data.count)
			Result.append (" bytes, subtype=0x")
			Result.append (subtype.to_hex_string)
			Result.append_character (')')
		end

invariant
	data_not_void: data /= Void

note
	copyright: "2026, Jocelyn Fiat and Eiffel Software"
	license: "MIT License"
end
