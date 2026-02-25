note
	description: "Summary description for {YAML_STRING}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	YAML_STRING

inherit
	YAML_SCALAR

create
	make,
	make_string

convert
	make ({READABLE_STRING_8, STRING_8, IMMUTABLE_STRING_8, READABLE_STRING_GENERAL, STRING_GENERAL, IMMUTABLE_STRING_GENERAL})


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
