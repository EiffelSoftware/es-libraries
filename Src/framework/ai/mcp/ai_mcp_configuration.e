note
	description: "[
		MCP servers configured in files in the format of `.mcp.json', shared with other agents:

			{"mcpServers": {
				"files": {"command": "npx", "args": ["-y", "@modelcontextprotocol/server-filesystem", "docs"],
					"env": {"TOKEN": "${MY_TOKEN}"}, "tools": ["read_file"], "timeout": 30},
				"tracker": {"type": "http", "url": "https://mcp.example.com/mcp"}
			}}

		`${NAME}' in a command, an argument, an environment variable, a folder or an address is
		replaced by the environment variable NAME (empty if not set). A server of a file read later
		replaces the server of the same name read before (so a project replaces the user's).
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	AI_MCP_CONFIGURATION

inherit
	AI_JSON_HELPER

create
	make

feature {NONE} -- Initialization

	make
			-- Configuration without servers.
		do
			create servers.make (3)
			create errors.make (0)
		ensure
			no_server: servers.is_empty
		end

feature -- Access

	servers: ARRAYED_LIST [AI_MCP_SERVER_DEFINITION]
			-- Servers configured, in the order of their names

	errors: ARRAYED_LIST [STRING_32]
			-- Problems found in the files read

	server (a_name: READABLE_STRING_GENERAL): detachable AI_MCP_SERVER_DEFINITION
			-- Server named `a_name', if any
		do
			across servers as s until Result /= Void loop
				if s.name.same_string_general (a_name) then
					Result := s
				end
			end
		end

feature -- Basic operations

	load_file (a_path: PATH; a_source: READABLE_STRING_GENERAL)
			-- Add the servers of the file `a_path' (named `a_source' in `errors' and in the servers), if it exists.
		local
			f: RAW_FILE
			l_bytes: STRING_8
			retried: BOOLEAN
		do
			if not retried then
				create f.make_with_path (a_path)
				if f.exists and then not f.is_directory then
					if f.is_readable then
						f.open_read
						if f.count > 0 then
							f.read_stream (f.count)
						end
						l_bytes := f.last_string
						f.close
						if l_bytes.starts_with ({UTF_CONVERTER}.utf_8_bom_to_string_8) then
							l_bytes.remove_head (3)
						end
						load_text (l_bytes, a_source)
					else
						errors.extend ({STRING_32} "" + a_source.to_string_32 + {STRING_32} ": cannot be read")
					end
				end
			end
		rescue
			retried := True
			errors.extend ({STRING_32} "" + a_source.to_string_32 + {STRING_32} ": cannot be read")
			retry
		end

	load_text (a_text: READABLE_STRING_8; a_source: READABLE_STRING_GENERAL)
			-- Add the servers of the configuration `a_text' (UTF-8), named `a_source'.
		local
			l_definition: AI_MCP_SERVER_DEFINITION
		do
			if attached parsed_json_object (a_text) as o then
				if attached object_item (o, "mcpServers") as l_servers then
					across l_servers as v loop
						if attached {JSON_OBJECT} v as l_object then
							l_definition := new_definition (@v.key.unescaped_string_32, l_object, a_source)
							if attached server (l_definition.name) as l_old then
								servers.prune_all (l_old)
							end
							servers.extend (l_definition)
						else
							errors.extend ({STRING_32} "" + a_source.to_string_32 + {STRING_32} ": server " + @v.key.unescaped_string_32 + {STRING_32} " is not an object")
						end
					end
					sort_servers
				else
					errors.extend ({STRING_32} "" + a_source.to_string_32 + {STRING_32} ": no %"mcpServers%" object")
				end
			else
				errors.extend ({STRING_32} "" + a_source.to_string_32 + {STRING_32} ": not a JSON object")
			end
		end

	expanded_text (a_text: READABLE_STRING_GENERAL): STRING_32
			-- `a_text' with each `${NAME}' replaced by the environment variable NAME (empty if not set)
		local
			i, j: INTEGER
			l_env: EXECUTION_ENVIRONMENT
		do
			create l_env
			create Result.make (a_text.count)
			from
				i := 1
			until
				i > a_text.count
			loop
				if a_text [i] = '$' and then i < a_text.count and then a_text [i + 1] = '{' then
					j := a_text.index_of ('}', i + 2)
					if j > i + 2 then
						if attached l_env.item (a_text.substring (i + 2, j - 1)) as v then
							Result.append_string_general (v)
						end
						i := j + 1
					else
						Result.append_character (a_text [i])
						i := i + 1
					end
				else
					Result.append_character (a_text [i])
					i := i + 1
				end
			end
		end

feature {NONE} -- Implementation

	new_definition (a_name: STRING_32; o: JSON_OBJECT; a_source: READABLE_STRING_GENERAL): AI_MCP_SERVER_DEFINITION
			-- Server `a_name' defined by `o' in `a_source'
		local
			l_tools: ARRAYED_LIST [STRING_32]
		do
			create Result.make (a_name, a_source)
			Result.set_definition_text ({UTF_CONVERTER}.utf_8_string_8_to_string_32 (o.representation))
			if attached string_item (o, "type") as t then
				Result.set_kind (t)
			end
			if attached string_item (o, "command") as c then
				Result.set_command (expanded_text (c))
			end
			if attached array_item (o, "args") as a then
				across a as v loop
					if attached {JSON_STRING} v as s then
						Result.arguments.extend (expanded_text (s.unescaped_string_32))
					end
				end
			end
			if attached object_item (o, "env") as e then
				across e as v loop
					if attached {JSON_STRING} v as s then
						Result.environment.force (expanded_text (s.unescaped_string_32), @v.key.unescaped_string_32)
					end
				end
			end
			if attached string_item (o, "cwd") as d then
				Result.set_working_directory (expanded_text (d))
			end
			if attached string_item (o, "url") as u then
				Result.set_url (expanded_text (u))
				if not attached string_item (o, "type") then
					Result.set_kind ({STRING_32} "http")
				end
			end
			if attached array_item (o, "tools") as a then
				create l_tools.make (a.count)
				across a as v loop
					if attached {JSON_STRING} v as s then
						l_tools.extend (s.unescaped_string_32)
					end
				end
				Result.set_tool_names (l_tools)
			end
			if integer_item (o, "timeout") > 0 then
				Result.set_timeout (integer_item (o, "timeout"))
			end
			Result.set_disabled (boolean_item (o, "disabled"))
			if Result.is_stdio and Result.command.is_empty then
				errors.extend ({STRING_32} "" + a_source.to_string_32 + {STRING_32} ": server " + a_name + {STRING_32} " has no %"command%"")
			end
		ensure
			named: Result.name.same_string (a_name)
		end

	sort_servers
			-- Sort `servers' by name.
		local
			i, j: INTEGER
			l_server: AI_MCP_SERVER_DEFINITION
		do
				-- (Insertion sort: a few servers.)
			from i := 2 until i > servers.count loop
				l_server := servers [i]
				from j := i - 1 until j < 1 or else servers [j].name <= l_server.name loop
					servers [j + 1] := servers [j]
					j := j - 1
				end
				servers [j + 1] := l_server
				i := i + 1
			end
		end

invariant
	servers_attached: servers /= Void
	errors_attached: errors /= Void

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
