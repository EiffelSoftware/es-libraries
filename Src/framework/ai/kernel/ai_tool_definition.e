note
	description: "Tool the model may call: its name, description and the JSON schema of its input."
	date: "$Date$"
	revision: "$Revision$"

class
	AI_TOOL_DEFINITION

create
	make

feature {NONE} -- Initialization

	make (a_name: READABLE_STRING_8; a_description: READABLE_STRING_GENERAL; a_input_schema: JSON_OBJECT)
			-- Tool `a_name', described by `a_description', whose input follows `a_input_schema'.
		require
			a_name_not_empty: not a_name.is_empty
		do
			name := a_name.to_string_8
			description := a_description.to_string_32
			input_schema := a_input_schema
		end

feature -- Access

	name: STRING_8
			-- Name of the tool

	description: STRING_32
			-- What the tool does, for the model

	input_schema: JSON_OBJECT
			-- JSON schema of the input

invariant
	name_not_empty: not name.is_empty

note
	copyright: "Copyright (c) 1984-2026, Eiffel Software"
	license: "GPL version 2 (see http://www.eiffel.com/licensing/gpl.txt)"
	licensing_options: "http://www.eiffel.com/licensing"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"

end
