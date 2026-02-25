note
	description: "[
		BSON_DOUBLE represents a 64-bit IEEE 754 floating point value in BSON.
		
		In BSON, a double is serialized as 8 bytes in little-endian format.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	BSON_DOUBLE

inherit
	BSON_VALUE
		redefine
			is_double
		end

	BSON_CONSTANTS
		undefine
			is_equal
		end

create
	make

convert
	make ({REAL_64})

feature {NONE} -- Initialization

	make (a_value: REAL_64)
			-- Initialize with `a_value'.
		do
			value := a_value
		ensure
			value_set: value = a_value
		end

feature -- Status report

	is_double: BOOLEAN = True
			-- <Precursor>

feature -- Access

	bson_type: INTEGER_8
			-- <Precursor>
		do
			Result := bson_type_double
		end

	value: REAL_64
			-- Double value.

	item: REAL_64
			-- Alias for `value'.
		do
			Result := value
		end

feature -- Status report

	is_nan: BOOLEAN
			-- Is value NaN (Not a Number)?
		do
			Result := value.is_nan
		end

	is_positive_infinity: BOOLEAN
			-- Is value positive infinity?
		do
			Result := value.is_positive_infinity
		end

	is_negative_infinity: BOOLEAN
			-- Is value negative infinity?
		do
			Result := value.is_negative_infinity
		end

feature -- Visitor pattern

	accept (a_visitor: BSON_VISITOR)
			-- Accept `a_visitor'.
		do
			a_visitor.visit_bson_double (Current)
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
