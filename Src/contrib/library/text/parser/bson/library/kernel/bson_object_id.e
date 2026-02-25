note
	description: "[
		BSON_OBJECT_ID represents a 12-byte ObjectId in BSON.
		
		An ObjectId consists of:
		- 4 bytes: timestamp (seconds since Unix epoch)
		- 5 bytes: random value (unique per machine/process)
		- 3 bytes: incrementing counter
		
		Total: 12 bytes, typically represented as 24-character hex string.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	BSON_OBJECT_ID

inherit
	BSON_VALUE
		redefine
			is_object_id
		end

	BSON_CONSTANTS
		undefine
			is_equal
		end

create
	make_from_bytes,
	make_from_hex_string,
	make_new

feature {NONE} -- Initialization

	make_from_bytes (a_bytes: ARRAY [NATURAL_8])
			-- Initialize from 12 bytes.
		require
			a_bytes_not_void: a_bytes /= Void
			valid_size: a_bytes.count = 12
		do
			bytes := a_bytes
		ensure
			bytes_set: bytes = a_bytes
		end

	make_from_hex_string (a_hex: READABLE_STRING_8)
			-- Initialize from 24-character hex string.
		require
			a_hex_not_void: a_hex /= Void
			valid_length: a_hex.count = 24
		local
			i, j: INTEGER
			l_byte: NATURAL_8
		do
			create bytes.make_filled (0, 1, 12)
			from
				i := 1
				j := 1
			until
				i > 24
			loop
				l_byte := hex_char_to_nibble (a_hex.item (i)) |<< 4
				l_byte := l_byte + hex_char_to_nibble (a_hex.item (i + 1))
				bytes [j] := l_byte
				i := i + 2
				j := j + 1
			end
		ensure
			bytes_created: bytes /= Void
			bytes_size: bytes.count = 12
		end

	make_new
			-- Create a new ObjectId with current timestamp.
		local
			l_time: DATE_TIME
			l_timestamp: INTEGER_32
			l_random: RANDOM
			i: INTEGER
		do
			create l_time.make_now_utc
			l_timestamp := (l_time.definite_duration (create {DATE_TIME}.make_from_epoch (0))).seconds_count.to_integer_32

			create bytes.make_filled (0, 1, 12)

				-- First 4 bytes: timestamp (big-endian for sorting)
			bytes [1] := ((l_timestamp |>> 24) & 0xFF).to_natural_8
			bytes [2] := ((l_timestamp |>> 16) & 0xFF).to_natural_8
			bytes [3] := ((l_timestamp |>> 8) & 0xFF).to_natural_8
			bytes [4] := (l_timestamp & 0xFF).to_natural_8

				-- Next 5 bytes: random
			create l_random.set_seed (l_time.time.compact_time)
			from
				i := 5
			until
				i > 9
			loop
				l_random.forth
				bytes [i] := (l_random.item \\ 256).to_natural_8
				i := i + 1
			end

				-- Last 3 bytes: counter (using random for simplicity)
			from
				i := 10
			until
				i > 12
			loop
				l_random.forth
				bytes [i] := (l_random.item \\ 256).to_natural_8
				i := i + 1
			end
		ensure
			bytes_created: bytes /= Void
			bytes_size: bytes.count = 12
		end

feature -- Status report

	is_object_id: BOOLEAN = True
			-- <Precursor>

feature -- Access

	bson_type: INTEGER_8
			-- <Precursor>
		do
			Result := bson_type_object_id
		end

	bytes: ARRAY [NATURAL_8]
			-- 12 bytes of the ObjectId.

	timestamp: INTEGER_32
			-- Unix timestamp portion (first 4 bytes).
		do
			Result := (bytes [1].to_integer_32 |<< 24)
				+ (bytes [2].to_integer_32 |<< 16)
				+ (bytes [3].to_integer_32 |<< 8)
				+ bytes [4].to_integer_32
		end

feature -- Conversion

	to_hex_string: STRING
			-- 24-character hexadecimal string representation.
		local
			i: INTEGER
			l_hex: STRING
		do
			create Result.make (24)
			from
				i := 1
			until
				i > 12
			loop
				l_hex := bytes [i].to_hex_string.as_lower
				if l_hex.count = 1 then
					Result.append_character ('0')
				end
				Result.append (l_hex)
				i := i + 1
			end
		ensure
			result_not_void: Result /= Void
			correct_length: Result.count = 24
		end

feature -- Visitor pattern

	accept (a_visitor: BSON_VISITOR)
			-- Accept `a_visitor'.
		do
			a_visitor.visit_bson_object_id (Current)
		end

feature -- Report

	hash_code: INTEGER
			-- Hash code value.
		do
			Result := to_hex_string.hash_code
		end

feature -- Status report

	debug_output: STRING
			-- String that should be displayed in debugger.
		do
			Result := "ObjectId(" + to_hex_string + ")"
		end

feature {NONE} -- Implementation

	hex_char_to_nibble (c: CHARACTER): NATURAL_8
			-- Convert hex character to 4-bit value.
		require
			valid_hex_char: c.is_hexa_digit
		do
			if c >= '0' and c <= '9' then
				Result := (c.code - ('0').code).to_natural_8
			elseif c >= 'a' and c <= 'f' then
				Result := (c.code - ('a').code + 10).to_natural_8
			elseif c >= 'A' and c <= 'F' then
				Result := (c.code - ('A').code + 10).to_natural_8
			end
		ensure
			valid_range: Result <= 15
		end

invariant
	bytes_not_void: bytes /= Void
	bytes_size: bytes.count = 12

note
	copyright: "2026, Jocelyn Fiat and Eiffel Software"
	license: "MIT License"
end
