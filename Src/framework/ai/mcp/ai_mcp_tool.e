note
	description: "[
		Tool of an MCP server, as listed by `tools/list': its name, description and the JSON schema of
		its arguments. It is given to the model under `qualified_name' (`mcp__SERVER__TOOL').
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	AI_MCP_TOOL

create
	make

feature {NONE} -- Initialization

	make (a_server, a_name: READABLE_STRING_GENERAL; a_description: READABLE_STRING_GENERAL; a_schema: JSON_OBJECT; a_read_only: BOOLEAN)
			-- Tool `a_name' of server `a_server'.
		require
			a_server_not_empty: not a_server.is_empty
			a_name_not_empty: not a_name.is_empty
		do
			server_name := a_server.to_string_32
			name := a_name.to_string_32
			description := a_description.to_string_32
			input_schema := a_schema
			is_read_only := a_read_only
			qualified_name := qualified_name_of (a_server, a_name)
		ensure
			server_set: server_name.same_string_general (a_server)
			name_set: name.same_string_general (a_name)
		end

feature -- Access

	server_name: STRING_32
			-- Name of the server

	name: STRING_32
			-- Name of the tool, for its server

	description: STRING_32
			-- What the tool does

	input_schema: JSON_OBJECT
			-- JSON schema of the arguments

	qualified_name: STRING_8
			-- Name of the tool for the model

	definition: AI_TOOL_DEFINITION
			-- Definition given to the model
		local
			l_description: STRING_32
		do
			create l_description.make (description.count + 40)
			l_description.append ({STRING_32} "(Tool " + name + {STRING_32} " of the MCP server " + server_name + {STRING_32} ".) ")
			l_description.append (description)
			create Result.make (qualified_name, l_description, input_schema)
		end

	Prefix_text: STRING_8 = "mcp__"
			-- Start of the names of the tools of MCP servers, for the model

	Max_name_count: INTEGER = 64
			-- Longest name of a tool for the APIs of the models

	qualified_name_of (a_server, a_name: READABLE_STRING_GENERAL): STRING_8
			-- Name of the tool `a_name' of server `a_server' for the model: `mcp__SERVER__TOOL', with only letters,
			-- digits, `_' and `-', cut to `Max_name_count' characters
		local
			l_text: STRING_32
			c: CHARACTER_32
			i: INTEGER
		do
			l_text := {STRING_32} "" + a_server.to_string_32 + {STRING_32} "__" + a_name.to_string_32
			create Result.make (Prefix_text.count + l_text.count)
			Result.append (Prefix_text)
			from i := 1 until i > l_text.count loop
				c := l_text [i]
				if c.is_character_8 and then (c.to_character_8.is_alpha_numeric or c = '_' or c = '-') then
					Result.append_character (c.to_character_8)
				else
					Result.append_character ('_')
				end
				i := i + 1
			end
			if Result.count > Max_name_count then
				Result.keep_head (Max_name_count)
			end
		ensure
			instance_free: class
			prefixed: Result.starts_with (Prefix_text)
			short_enough: Result.count <= Max_name_count
		end

feature -- Status report

	is_read_only: BOOLEAN
			-- Does the server say the tool only reads (annotation `readOnlyHint')?

invariant
	name_not_empty: not name.is_empty
	qualified_name_prefixed: qualified_name.starts_with (Prefix_text)

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
