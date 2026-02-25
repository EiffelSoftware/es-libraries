note
	description: "[
		BSON_BOOLEAN represents a boolean value in BSON.
		
		In BSON, a boolean is serialized as:
		- unsigned_byte(0) for false
		- unsigned_byte(1) for true
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	BSON_BOOLEAN

inherit
	BSON_VALUE
		redefine
			is_boolean
		end

	BSON_CONSTANTS
		undefine
			is_equal
		end

create
	make,
	make_true,
	make_false

feature {NONE} -- Initialization

	make (a_value: BOOLEAN)
			-- Initialize with `a_value'.
		do
			value := a_value
		ensure
			value_set: value = a_value
		end

	make_true
			-- Initialize with True.
		do
			make (True)
		ensure
			is_true: value = True
		end

	make_false
			-- Initialize with False.
		do
			make (False)
		ensure
			is_false: value = False
		end

feature -- Status report

	is_boolean: BOOLEAN = True
			-- <Precursor>

feature -- Access

	bson_type: INTEGER_8
			-- <Precursor>
		do
			Result := bson_type_boolean
		end

	value: BOOLEAN
			-- Boolean value.

	item: BOOLEAN
			-- Alias for `value'.
		do
			Result := value
		end

feature -- Visitor pattern

	accept (a_visitor: BSON_VISITOR)
			-- Accept `a_visitor'.
		do
			a_visitor.visit_bson_boolean (Current)
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
