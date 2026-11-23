note
	description: "[
		Definition of an MCP server, as read from an MCP configuration file (`.mcp.json`): a program
		started by the client (stdio transport: `command`, `args`, `env`, `cwd`), or the address of a
		remote server (`type` "http", `url`, `headers`: not supported yet). Its own options:
		`tools` (only these tools are given to the model), `timeout` (seconds a call may take),
		`disabled`.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	AI_MCP_SERVER_DEFINITION

create
	make

feature {NONE} -- Initialization

	make (a_name, a_source: READABLE_STRING_GENERAL)
			-- Server `a_name', defined in `a_source' (the name of its configuration file), with no command yet.
		require
			a_name_not_empty: not a_name.is_empty
		do
			name := a_name.to_string_32
			source := a_source.to_string_32
			create command.make_empty
			create arguments.make (3)
			create environment.make (3)
			create kind.make_from_string ({STRING_32} "stdio")
			create definition_text.make_empty
			timeout := Default_timeout
		ensure
			name_set: name.same_string_general (a_name)
			source_set: source.same_string_general (a_source)
			stdio: is_stdio
		end

feature -- Access

	name: STRING_32
			-- Name of the server (key of `mcpServers')

	source: STRING_32
			-- Configuration file defining the server

	kind: STRING_32
			-- Transport: "stdio" or "http"

	command: STRING_32
			-- Program started (stdio)

	arguments: ARRAYED_LIST [STRING_32]
			-- Arguments of `command'

	environment: STRING_TABLE [STRING_32]
			-- Environment variables added to those of the client

	working_directory: detachable STRING_32
			-- Folder in which `command' runs (Void: that of the client)

	url: detachable STRING_32
			-- Address of a remote server (http)

	tool_names: detachable ARRAYED_LIST [STRING_32]
			-- Tools given to the model (Void: all)

	timeout: INTEGER
			-- Seconds a call may take

	definition_text: STRING_32
			-- Definition as written in the configuration file (JSON), to tell when it changes

	Default_timeout: INTEGER = 60
			-- Default of `timeout'

feature -- Status report

	is_stdio: BOOLEAN
			-- Is the server a program started by the client?
		do
			Result := kind.same_string ({STRING_32} "stdio")
		end

	is_disabled: BOOLEAN
			-- Is the server disabled in its configuration file?

	is_tool_given (a_tool: READABLE_STRING_GENERAL): BOOLEAN
			-- Is the tool `a_tool' of the server given to the model?
		do
			Result := not attached tool_names as l_names or else across l_names as n some n.same_string_general (a_tool) end
		end

feature -- Element change

	set_kind (a_kind: READABLE_STRING_GENERAL)
			-- Set `kind' to `a_kind'.
		do
			kind := a_kind.to_string_32
		end

	set_command (a_command: READABLE_STRING_GENERAL)
			-- Set `command' to `a_command'.
		do
			command := a_command.to_string_32
		end

	set_working_directory (a_directory: detachable READABLE_STRING_GENERAL)
			-- Set `working_directory' to `a_directory'.
		do
			if attached a_directory then
				working_directory := a_directory.to_string_32
			else
				working_directory := Void
			end
		end

	set_url (a_url: detachable READABLE_STRING_GENERAL)
			-- Set `url' to `a_url'.
		do
			if attached a_url then
				url := a_url.to_string_32
			else
				url := Void
			end
		end

	set_tool_names (a_names: detachable ARRAYED_LIST [STRING_32])
			-- Set `tool_names' to `a_names'.
		do
			tool_names := a_names
		end

	set_timeout (a_seconds: INTEGER)
			-- Set `timeout' to `a_seconds'.
		require
			positive: a_seconds > 0
		do
			timeout := a_seconds
		end

	set_disabled (b: BOOLEAN)
			-- Set `is_disabled' to `b'.
		do
			is_disabled := b
		end

	set_definition_text (a_text: READABLE_STRING_GENERAL)
			-- Set `definition_text' to `a_text'.
		do
			definition_text := a_text.to_string_32
		end

invariant
	name_not_empty: not name.is_empty
	positive_timeout: timeout > 0

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
