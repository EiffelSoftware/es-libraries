note
	description: "Summary description for {YAML_BOOLEAN}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	YAML_BOOLEAN

inherit
	YAML_SCALAR
		rename
			to_boolean as value
		redefine
			is_boolean,
			value
		end


create
	make

convert
	make ({BOOLEAN})

feature {NONE} -- Initialization	

	make (a_value: BOOLEAN)
			-- Initialize with boolean `a_value`.
		do
			value := a_value
			style := Style_plain
		ensure
			is_boolean: is_boolean
		end

feature -- Access

	value: BOOLEAN

feature -- Conversion

	to_string_value: STRING_32
		do
			if value then
				Result := "true"
			else
				Result := "false"
			end
		end

feature -- Status report

	is_boolean: BOOLEAN = True

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
