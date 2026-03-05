note
	description: "Summary description for {YAML_NULL}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	YAML_NULL

inherit
	YAML_SCALAR
		redefine
			default_create,
			is_null
		end

create
	default_create

feature {NONE} -- Initialization	

	default_create
		do
			style := Style_plain
		ensure then
			is_null
		end

feature -- Conversion

	to_string_value: STRING_32 = "null"

feature -- Status report		

	is_null: BOOLEAN = True

note
	copyright: "Copyright (c) 1984-2026, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"
end
