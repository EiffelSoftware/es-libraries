note
	description: "[
		BSON_INT64 represents a 64-bit signed integer in BSON.
		
		In BSON, an int64 is serialized as 8 bytes in little-endian format,
		using two's complement representation.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	BSON_INT64

inherit
	BSON_VALUE
		redefine
			is_int64
		end

	BSON_CONSTANTS
		undefine
			is_equal
		end

create
	make

convert
	make ({INTEGER_64})

feature {NONE} -- Initialization

	make (a_value: INTEGER_64)
			-- Initialize with `a_value'.
		do
			value := a_value
		ensure
			value_set: value = a_value
		end

feature -- Status report

	is_int64: BOOLEAN = True
			-- <Precursor>

feature -- Access

	bson_type: INTEGER_8
			-- <Precursor>
		do
			Result := bson_type_int64
		end

	value: INTEGER_64
			-- Integer value.

	item: INTEGER_64
			-- Alias for `value'.
		do
			Result := value
		end

feature -- Visitor pattern

	accept (a_visitor: BSON_VISITOR)
			-- Accept `a_visitor'.
		do
			a_visitor.visit_bson_int64 (Current)
		end

feature -- Report

	hash_code: INTEGER
			-- Hash code value.
		do
			Result := value.hash_code
		end

feature -- Status report

	debug_output: STRING
			-- String that should be displayed in debugger.
		do
			Result := value.out
		end

note
	copyright: "2026, Jocelyn Fiat and Eiffel Software"
	license: "MIT License"
end
