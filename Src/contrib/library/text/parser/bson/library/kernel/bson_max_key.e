note
	description: "[
		BSON_MAX_KEY represents the maximum key value in BSON.
		
		Max key is a special type that compares higher than all other 
		possible BSON element values. It has no data, only the type code (0x7F / 127).
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	BSON_MAX_KEY

inherit
	BSON_VALUE
		redefine
			is_max_key
		end

	BSON_CONSTANTS
		undefine
			is_equal
		end

feature -- Status report

	is_max_key: BOOLEAN = True
			-- <Precursor>

feature -- Access

	bson_type: INTEGER_8
			-- <Precursor>
		do
			Result := bson_type_max_key
		end

feature -- Visitor pattern

	accept (a_visitor: BSON_VISITOR)
			-- Accept `a_visitor'.
		do
			a_visitor.visit_bson_max_key (Current)
		end

feature -- Report

	hash_code: INTEGER
			-- Hash code value.
		do
			Result := max_key_value.hash_code
		end

feature -- Status report

	debug_output: STRING
			-- String that should be displayed in debugger.
		do
			Result := max_key_value
		end

feature {NONE} -- Implementation

	max_key_value: STRING = "MaxKey"

note
	copyright: "2026, Jocelyn Fiat and Eiffel Software"
	license: "MIT License"
end
