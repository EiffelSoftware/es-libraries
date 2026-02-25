note
	description: "[
		BSON_JAVASCRIPT represents JavaScript code in BSON.
		
		In BSON, JavaScript code is serialized as a string.
		Note: JavaScript code with scope (type 0x0F) is deprecated.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	BSON_JAVASCRIPT

inherit
	BSON_VALUE
		redefine
			is_javascript
		end

	BSON_CONSTANTS
		undefine
			is_equal
		end

create
	make

feature {NONE} -- Initialization

	make (a_code: READABLE_STRING_GENERAL)
			-- Initialize with JavaScript code.
		require
			a_code_not_void: a_code /= Void
		do
			create code.make_from_string (a_code.to_string_32)
		ensure
			code_set: code.same_string (a_code)
		end

feature -- Status report

	is_javascript: BOOLEAN = True
			-- <Precursor>

feature -- Access

	bson_type: INTEGER_8
			-- <Precursor>
		do
			Result := bson_type_javascript
		end

	code: STRING_32
			-- JavaScript code.

feature -- Conversion

	to_utf8: STRING_8
			-- UTF-8 encoded representation.
		do
			Result := {UTF_CONVERTER}.utf_32_string_to_utf_8_string_8 (code)
		ensure
			result_not_void: Result /= Void
		end

feature -- Visitor pattern

	accept (a_visitor: BSON_VISITOR)
			-- Accept `a_visitor'.
		do
			a_visitor.visit_bson_javascript (Current)
		end

feature -- Report

	hash_code: INTEGER
			-- Hash code value.
		do
			Result := code.hash_code
		end

feature -- Status report

	debug_output: STRING
			-- String that should be displayed in debugger.
		do
			if code.count > 50 then
				Result := "JavaScript(" + code.substring (1, 47).to_string_8 + "...)"
			else
				Result := "JavaScript(" + code.to_string_8 + ")"
			end
		end

invariant
	code_not_void: code /= Void

note
	copyright: "2026, Jocelyn Fiat and Eiffel Software"
	license: "MIT License"
end
