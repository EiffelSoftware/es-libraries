note
	description: "[
		Tests of the MCP client: the configuration files, the names of the tools, and a session with
		the fake server `mcp_fake_server.py' (python3, found from the variable EIFFEL_SRC or
		ISE_LIBRARY, or in the folder of the tests).
	]"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	AI_MCP_TEST_SET

inherit
	EQA_TEST_SET

feature -- Tests: configuration

	test_configuration
			-- Servers read from a configuration: command, arguments, environment (with variables), options.
		local
			c: AI_MCP_CONFIGURATION
		do
			create c.make
			c.load_text ("[
				{"mcpServers": {
					"zeta": {"command": "zeta-server"},
					"files": {"command": "npx", "args": ["-y", "server-files", "${HOME}/docs"], "env": {"TOKEN": "x${NO_SUCH_VARIABLE_HERE}y"},
						"tools": ["read"], "timeout": 5, "cwd": "sub"},
					"remote": {"type": "http", "url": "https://example.com/mcp"},
					"off": {"command": "off", "disabled": true},
					"bad": 3
				}}
			]", "project")
			assert ("four servers", c.servers.count = 4)
			assert ("sorted", c.servers.first.name.same_string ("files") and c.servers.last.name.same_string ("zeta"))
			assert ("one error", c.errors.count = 1)
			if attached c.server ("files") as f then
				assert ("command", f.command.same_string ("npx"))
				assert ("arguments", f.arguments.count = 3 and then f.arguments [3].ends_with ("/docs") and then not f.arguments [3].has ('$'))
				assert ("variable unset: empty", attached f.environment.item ("TOKEN") as t and then t.same_string ("xy"))
				assert ("tools", f.is_tool_given ("read") and not f.is_tool_given ("write"))
				assert ("timeout", f.timeout = 5)
				assert ("folder", attached f.working_directory as d and then d.same_string ("sub"))
				assert ("source", f.source.same_string ("project"))
				assert ("definition kept", f.definition_text.has_substring ("server-files"))
				assert ("stdio", f.is_stdio)
			else
				assert ("files", False)
			end
			if attached c.server ("remote") as r then
				assert ("http", not r.is_stdio and attached r.url)
			else
				assert ("remote", False)
			end
			assert ("disabled", attached c.server ("off") as o and then o.is_disabled)
			assert ("all tools", attached c.server ("zeta") as z and then z.is_tool_given ("anything"))
		end

	test_configuration_replaced
			-- A server of a file read later replaces the server of the same name.
		local
			c: AI_MCP_CONFIGURATION
		do
			create c.make
			c.load_text ("{%"mcpServers%": {%"a%": {%"command%": %"one%"}, %"b%": {%"command%": %"b%"}}}", "user")
			c.load_text ("{%"mcpServers%": {%"a%": {%"command%": %"two%"}}}", "project")
			assert ("two servers", c.servers.count = 2)
			assert ("replaced", attached c.server ("a") as a and then a.command.same_string ("two") and then a.source.same_string ("project"))
			c.load_text ("not json", "broken")
			c.load_text ("{%"servers%": {}}", "other")
			assert ("errors", c.errors.count = 2)
		end

	test_qualified_names
			-- The names of the tools for the model: prefixed, only letters, digits, _ and -, at most 64 characters.
		do
			assert ("simple", {AI_MCP_TOOL}.qualified_name_of ("files", "read_file").same_string ("mcp__files__read_file"))
			assert ("replaced", {AI_MCP_TOOL}.qualified_name_of ("my server", "get.page/x").same_string ("mcp__my_server__get_page_x"))
			assert ("cut", {AI_MCP_TOOL}.qualified_name_of ("s", create {STRING_8}.make_filled ('a', 100)).count = 64)
		end

feature -- Tests: session

	test_session
			-- Start the fake server, list its tools (two pages), call them, then stop it.
		local
			c: AI_MCP_CLIENT
			i: INTEGER
			r: TUPLE [text: STRING_32; is_error: BOOLEAN]
		do
			if attached fake_server ("s", Void, 5) as d then
				create c.make (d)
				c.start
				wait_until (c, agent c.is_starting, 200)
				assert ("ready", c.is_ready)
				assert ("six tools (two pages)", c.tools.count = 6)
				assert ("server info", attached c.server_info as s and then s.same_string ("fake 1.0"))
				if attached c.tool_named ("mcp__s__echo") as t then
					assert ("read only", t.is_read_only)
					assert ("definition", t.definition.name.same_string ("mcp__s__echo") and t.definition.description.has_substring ("Echo a text."))
					i := c.call_tool (t, json_object ("{%"text%": %"hi%"}"))
					wait_until (c, agent c.is_waiting (i), 200)
					r := c.take_result (i)
					assert ("echo", r.text.same_string ("echo: hi") and not r.is_error)
				else
					assert ("echo listed", False)
				end
				r := called (c, "mcp__s__fail", Void)
				assert ("error result", r.is_error and r.text.same_string ("this tool always fails"))
				r := called (c, "mcp__s__image", Void)
				assert ("image named", r.text.same_string ("[image: image/png]%Nan image") and not r.is_error)
				r := called (c, "mcp__s__add", json_object ("{%"a%": 2, %"b%": 3}"))
				assert ("add", r.text.same_string ("5"))
					-- (The ping of the server was answered.)
				wait_until (c, agent (a_client: AI_MCP_CLIENT): BOOLEAN do Result := not across a_client.log as l some l.has_substring ("ping answered") end end (c), 100)
				assert ("ping answered", across c.log as l some l.has_substring ("ping answered") end)
				c.stop
				assert ("stopped", c.is_stopped and c.tools.is_empty)
			end
		end

	test_timeout_and_crash
			-- A call longer than the timeout ends with an error; a server that stops fails, ending its calls.
		local
			c: AI_MCP_CLIENT
			r: TUPLE [text: STRING_32; is_error: BOOLEAN]
		do
			if attached fake_server ("s", Void, 1) as d then
				create c.make (d)
				c.start
				wait_until (c, agent c.is_starting, 200)
				assert ("ready", c.is_ready)
				r := called (c, "mcp__s__slow", json_object ("{%"seconds%": 3}"))
				assert ("timeout", r.is_error and r.text.has_substring ("did not answer within 1 seconds"))
					-- (The server, busy with `slow' for 2 more seconds, then answers it late: ignored.)
				(create {EXECUTION_ENVIRONMENT}).sleep (2_500_000_000)
				r := called (c, "mcp__s__crash", Void)
				assert ("crash: error", r.is_error)
				assert ("failed", c.is_failed and c.status_message.has_substring ("stopped"))
				c.start
				wait_until (c, agent c.is_starting, 200)
				assert ("started again", c.is_ready)
				c.stop
			end
		end

	test_tools_filter_and_missing_program
			-- Only the tools named in the configuration are given; a missing program fails at once.
		local
			c: AI_MCP_CLIENT
			l_tools: ARRAYED_LIST [STRING_32]
			d: AI_MCP_SERVER_DEFINITION
		do
			create l_tools.make (2)
			l_tools.extend ("echo")
			l_tools.extend ("crash")
			if attached fake_server ("f", l_tools, 5) as l_definition then
				create c.make (l_definition)
				c.start
				wait_until (c, agent c.is_starting, 200)
				assert ("two tools", c.tools.count = 2)
				c.stop
			end
			create d.make ("none", "test")
			d.set_command ("no_such_program_for_mcp_tests")
			create c.make (d)
			c.start
			assert ("failed at once", c.is_failed and c.status_message.has_substring ("not found"))
		end

feature {NONE} -- Implementation

	fake_server (a_name: STRING; a_tools: detachable ARRAYED_LIST [STRING_32]; a_timeout: INTEGER): detachable AI_MCP_SERVER_DEFINITION
			-- Definition of the fake server, named `a_name' (Void if python3 or the script is not found)
		local
			l_script: detachable PATH
			l_env: EXECUTION_ENVIRONMENT
		do
			create l_env
			across <<"EIFFEL_SRC", "ISE_LIBRARY">> as v until l_script /= Void loop
				if attached l_env.item (v) as l_root then
					l_script := (create {PATH}.make_from_string (l_root)).extended ("framework").extended ("ai").extended ("tests").extended ("mcp_fake_server.py")
					if not (create {RAW_FILE}.make_with_path (l_script)).exists then
						l_script := Void
					end
				end
			end
			if attached l_script then
				create Result.make (a_name, "test")
				Result.set_command ("python3")
				Result.arguments.extend (l_script.name)
				Result.set_tool_names (a_tools)
				Result.set_timeout (a_timeout)
			else
				assert ("fake server script found (EIFFEL_SRC)", False)
			end
		end

	called (c: AI_MCP_CLIENT; a_name: STRING; a_arguments: detachable JSON_OBJECT): TUPLE [text: STRING_32; is_error: BOOLEAN]
			-- Result of the call of the tool `a_name' of `c' with `a_arguments'
		local
			i: INTEGER
		do
			if attached c.tool_named (a_name) as t and then c.is_ready then
				i := c.call_tool (t, a_arguments)
				wait_until (c, agent c.is_waiting (i), 400)
				if c.has_result (i) then
					Result := c.take_result (i)
				else
					Result := [{STRING_32} "no result", True]
				end
			else
				Result := [{STRING_32} "no such tool", True]
			end
		end

	wait_until (c: AI_MCP_CLIENT; a_waiting: FUNCTION [BOOLEAN]; a_count: INTEGER)
			-- Poll `c' every 20 ms while `a_waiting' holds, at most `a_count' times.
		local
			n: INTEGER
		do
			from
				c.poll
			until
				not a_waiting.item ([]) or n >= a_count
			loop
				(create {EXECUTION_ENVIRONMENT}).sleep (20_000_000)
				c.poll
				n := n + 1
			end
		end

	json_object (s: STRING_8): detachable JSON_OBJECT
			-- Object of the JSON text `s'
		do
			Result := (create {AI_JSON_HELPER}).parsed_json_object (s)
		end

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
