note
	description: "[
		BSON_NULL represents a null value in BSON.
		
		In BSON, null has no value data - only the type code.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	BSON_NULL

inherit
	BSON_VALUE
		redefine
			is_null
		end

	BSON_CONSTANTS
		undefine
			is_equal
		end

feature -- Status report

	is_null: BOOLEAN = True
			-- <Precursor>

feature -- Access

	bson_type: INTEGER_8
			-- <Precursor>
		do
			Result := bson_type_null
		end

feature -- Visitor pattern

	accept (a_visitor: BSON_VISITOR)
			-- Accept `a_visitor'.
		do
			a_visitor.visit_bson_null (Current)
		end

feature -- Report

	hash_code: INTEGER
			-- Hash code value.
		do
			Result := null_value.hash_code
		end

feature -- Status report

	debug_output: STRING
			-- String that should be displayed in debugger.
		do
			Result := null_value
		end

feature {NONE} -- Implementation

	null_value: STRING = "null"

note
	copyright: "2026, Jocelyn Fiat and Eiffel Software"
	license: "MIT License"
end
