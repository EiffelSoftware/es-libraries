note
	description: "[
		BSON_MIN_KEY represents the minimum key value in BSON.
		
		Min key is a special type that compares lower than all other 
		possible BSON element values. It has no data, only the type code (0xFF / -1).
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	BSON_MIN_KEY

inherit
	BSON_VALUE
		redefine
			is_min_key
		end

	BSON_CONSTANTS
		undefine
			is_equal
		end

feature -- Status report

	is_min_key: BOOLEAN = True
			-- <Precursor>

feature -- Access

	bson_type: INTEGER_8
			-- <Precursor>
		do
			Result := bson_type_min_key
		end

feature -- Visitor pattern

	accept (a_visitor: BSON_VISITOR)
			-- Accept `a_visitor'.
		do
			a_visitor.visit_bson_min_key (Current)
		end

feature -- Report

	hash_code: INTEGER
			-- Hash code value.
		do
			Result := min_key_value.hash_code
		end

feature -- Status report

	debug_output: STRING
			-- String that should be displayed in debugger.
		do
			Result := min_key_value
		end

feature {NONE} -- Implementation

	min_key_value: STRING = "MinKey"

note
	copyright: "2026, Jocelyn Fiat and Eiffel Software"
	license: "MIT License"
end
