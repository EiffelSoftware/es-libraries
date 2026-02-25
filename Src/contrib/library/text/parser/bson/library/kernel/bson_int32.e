note
	description: "[
		BSON_INT32 represents a 32-bit signed integer in BSON.
		
		In BSON, an int32 is serialized as 4 bytes in little-endian format,
		using two's complement representation.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	BSON_INT32

inherit
	BSON_VALUE
		redefine
			is_int32
		end

	BSON_CONSTANTS
		undefine
			is_equal
		end

create
	make

convert
	make ({INTEGER_32})

feature {NONE} -- Initialization

	make (a_value: INTEGER_32)
			-- Initialize with `a_value'.
		do
			value := a_value
		ensure
			value_set: value = a_value
		end

feature -- Status report

	is_int32: BOOLEAN = True
			-- <Precursor>

feature -- Access

	bson_type: INTEGER_8
			-- <Precursor>
		do
			Result := bson_type_int32
		end

	value: INTEGER_32
			-- Integer value.

	item: INTEGER_32
			-- Alias for `value'.
		do
			Result := value
		end

feature -- Visitor pattern

	accept (a_visitor: BSON_VISITOR)
			-- Accept `a_visitor'.
		do
			a_visitor.visit_bson_int32 (Current)
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
