note
	description: "[
		Client of an MCP server (Model Context Protocol, JSON-RPC 2.0), started as a program (stdio).

		Nothing here waits: `start' launches the server and sends `initialize'; `poll', called
		often (by a user interface, on its own thread), takes the messages received, and moves on:
		`initialized', then `tools/list' (all its pages), then the client is ready (`is_ready')
		with its `tools'. `call_tool' sends `tools/call' and gives the id of the request, whose
		result (`has_result', `take_result') is set by a later `poll': the text contents of the
		answer, its other contents named only, or the error (also when the server takes longer than
		its `timeout', or stops).

		The requests of the server (`ping', the others refused) and its notifications (the list of
		tools changed: listed again; log messages) are handled by `poll' too.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	AI_MCP_CLIENT

inherit
	AI_JSON_HELPER

create
	make

feature {NONE} -- Initialization

	make (a_definition: AI_MCP_SERVER_DEFINITION)
			-- Client of the server `a_definition' (not started).
		require
			stdio: a_definition.is_stdio
		do
			definition := a_definition
			create tools.make (0)
			create listed_tools.make (0)
			create pending_calls.make (2)
			create results.make (2)
			create log.make (Max_log_count)
			create status_message.make_from_string ({STRING_32} "stopped")
			next_id := 1
		ensure
			definition_set: definition = a_definition
			stopped: is_stopped
		end

feature -- Access

	definition: AI_MCP_SERVER_DEFINITION
			-- Server

	tools: ARRAYED_LIST [AI_MCP_TOOL]
			-- Tools of the server given to the model (once ready)

	status_message: STRING_32
			-- State of the server, as told to the user

	server_info: detachable STRING_32
			-- Name and version the server gave, if any

	log: ARRAYED_LIST [STRING_32]
			-- Last lines of the log of the server (its standard error, its log messages) and of the client

	tool_named (a_qualified_name: READABLE_STRING_GENERAL): detachable AI_MCP_TOOL
			-- Tool whose name for the model is `a_qualified_name', if any
		do
			across tools as t until Result /= Void loop
				if t.qualified_name.same_string_general (a_qualified_name) then
					Result := t
				end
			end
		end

	Protocol_version: STRING_8 = "2025-06-18"
			-- Version of the protocol asked for

	Start_timeout: INTEGER = 60
			-- Seconds a server may take to start and list its tools (a first `npx' may download it)

	Max_result_count: INTEGER = 60_000
			-- Most characters of a result given back

	Max_log_count: INTEGER = 200
			-- Most lines kept in `log'

feature -- Status report

	is_stopped: BOOLEAN
			-- Is the server not running (never started, or stopped)?
		do
			Result := state = State_stopped
		end

	is_starting: BOOLEAN
			-- Is the server starting (before its tools are known)?
		do
			Result := state = State_starting
		end

	is_ready: BOOLEAN
			-- Can its tools be called?
		do
			Result := state = State_ready
		end

	is_failed: BOOLEAN
			-- Did the server fail to start, or stop by itself?
		do
			Result := state = State_failed
		end

	has_result (a_id: INTEGER): BOOLEAN
			-- Did the call `a_id' end?
		do
			Result := results.has (a_id)
		end

	is_waiting (a_id: INTEGER): BOOLEAN
			-- Is the call `a_id' still running?
		do
			Result := pending_calls.has (a_id)
		end

feature -- Basic operations

	start
			-- Launch the server and start the initialization.
		require
			not_running: is_stopped or is_failed
		local
			l_transport: AI_MCP_STDIO_TRANSPORT
			l_params, l_info: JSON_OBJECT
		do
			tools.wipe_out
			server_info := Void
			create l_transport.make (definition)
			l_transport.start
			if attached l_transport.last_error as e then
				fail (e)
			else
				transport := l_transport
				state := State_starting
				status_message := {STRING_32} "starting"
				start_deadline := deadline (Start_timeout)
				add_log ({STRING_32} "(started: " + definition.command + {STRING_32} ")")
				create l_params.make_with_capacity (3)
				l_params.put_string (Protocol_version, "protocolVersion")
				l_params.put (create {JSON_OBJECT}.make_with_capacity (0), "capabilities")
				create l_info.make_with_capacity (2)
				l_info.put_string ("EiffelStudio", "name")
				l_info.put_string ("1.0", "version")
				l_params.put (l_info, "clientInfo")
				initialize_id := send_request ("initialize", l_params)
			end
		ensure
			starting_or_failed: is_starting or is_failed
		end

	call_tool (a_tool: AI_MCP_TOOL; a_arguments: detachable JSON_OBJECT): INTEGER
			-- Call `a_tool' with `a_arguments'; the id of the request (see `has_result').
		require
			ready: is_ready
			tool_of_server: tools.has (a_tool)
		local
			l_params: JSON_OBJECT
		do
			create l_params.make_with_capacity (2)
			l_params.put_string (a_tool.name, "name")
			if attached a_arguments then
				l_params.put (a_arguments, "arguments")
			else
				l_params.put (create {JSON_OBJECT}.make_with_capacity (0), "arguments")
			end
			Result := send_request ("tools/call", l_params)
			pending_calls.force (deadline (definition.timeout), Result)
		ensure
			waiting: is_waiting (Result)
		end

	take_result (a_id: INTEGER): TUPLE [text: STRING_32; is_error: BOOLEAN]
			-- Result of the call `a_id' (removed)
		require
			has_result: has_result (a_id)
		do
			if attached results.item (a_id) as r then
				Result := r
			else
				Result := [{STRING_32} "No result.", True]
			end
			results.remove (a_id)
		ensure
			removed: not has_result (a_id)
		end

	poll
			-- Take into account what the server sent, and the calls that took too long.
		local
			l_now: DATE_TIME
			l_late: ARRAYED_LIST [INTEGER]
		do
			if attached transport as t then
				across t.take_log_lines as l loop
					add_log (l)
				end
				across t.take_messages as m loop
					handle_message (m)
				end
				create l_now.make_now_utc
				if is_starting and then attached start_deadline as d and then l_now > d then
					fail ({STRING_32} "no answer after " + Start_timeout.out + {STRING_32} " seconds")
				end
				create l_late.make (0)
				across pending_calls as d loop
					if l_now > d then
						l_late.extend (@d.key)
					end
				end
				across l_late as i loop
					pending_calls.remove (i)
					results.force ([{STRING_32} "The MCP server " + definition.name + {STRING_32} " did not answer within " + definition.timeout.out + {STRING_32} " seconds.", True], i)
				end
				if (is_starting or is_ready) and then transport = t and then not t.is_running then
						-- (The messages sent just before the end were taken above.)
					across t.take_messages as m loop
						handle_message (m)
					end
					fail ("the server stopped")
				end
			end
		end

	stop
			-- Stop the server (the calls running end with an error).
		do
			if attached transport as t then
				t.stop
				transport := Void
				add_log ({STRING_32} "(stopped)")
			end
			end_calls ({STRING_32} "The MCP server " + definition.name + {STRING_32} " was stopped.")
			tools.wipe_out
			state := State_stopped
			status_message := {STRING_32} "stopped"
		ensure
			stopped: is_stopped
		end

feature {NONE} -- Implementation: messages

	handle_message (a_message: STRING_8)
			-- Take into account the message `a_message' of the server.
		local
			l_id: INTEGER
		do
			if attached parsed_json_object (a_message) as o then
				if attached string_item (o, "method") as l_method then
					if attached {JSON_NUMBER} o.item (create {JSON_STRING}.make_from_string ("id")) as n then
						answer_request (n, l_method)
					elseif l_method.same_string ({STRING_32} "notifications/tools/list_changed") and is_ready then
						list_tools (Void)
					elseif l_method.same_string ({STRING_32} "notifications/message") and then attached object_item (o, "params") as p then
						if attached string_item (p, "data") as l_data then
							add_log (l_data)
						elseif attached {JSON_VALUE} p.item (create {JSON_STRING}.make_from_string ("data")) as v then
							add_log ({UTF_CONVERTER}.utf_8_string_8_to_string_32 (v.representation))
						end
					end
				elseif attached {JSON_NUMBER} o.item (create {JSON_STRING}.make_from_string ("id")) as n and then n.is_integer then
					l_id := n.integer_64_item.to_integer
					if l_id = initialize_id then
						end_initialization (o)
					elseif l_id = list_id then
						add_listed_tools (o)
					elseif pending_calls.has (l_id) then
						pending_calls.remove (l_id)
						results.force (call_result (o), l_id)
					end
				end
			else
				add_log ({STRING_32} "(not a JSON message: " + {UTF_CONVERTER}.utf_8_string_8_to_string_32 (a_message.head (200)) + {STRING_32} ")")
			end
		end

	answer_request (a_id: JSON_NUMBER; a_method: STRING_32)
			-- Answer the request `a_id' of the server, of method `a_method': `ping', or not supported.
		local
			o, l_error: JSON_OBJECT
		do
			create o.make_with_capacity (3)
			o.put_string ("2.0", "jsonrpc")
			o.put (a_id, "id")
			if a_method.same_string ({STRING_32} "ping") then
				o.put (create {JSON_OBJECT}.make_with_capacity (0), "result")
			else
				create l_error.make_with_capacity (2)
				l_error.put_integer (-32601, "code")
				l_error.put_string ({STRING_32} "Method not supported by the client: " + a_method, "message")
				o.put (l_error, "error")
			end
			send (o)
		end

	end_initialization (o: JSON_OBJECT)
			-- Take into account the answer `o' to `initialize'.
		local
			l_notification: JSON_OBJECT
		do
			if attached object_item (o, "error") as e then
				fail ({STRING_32} "initialization refused: " + error_text (e))
			elseif attached object_item (o, "result") as r then
				if attached object_item (r, "serverInfo") as l_info and then attached string_item (l_info, "name") as l_name then
					server_info := l_name
					if attached string_item (l_info, "version") as v then
						server_info := l_name + {STRING_32} " " + v
					end
				end
				create l_notification.make_with_capacity (2)
				l_notification.put_string ("2.0", "jsonrpc")
				l_notification.put_string ("notifications/initialized", "method")
				send (l_notification)
				list_tools (Void)
			end
		end

	list_tools (a_cursor: detachable READABLE_STRING_GENERAL)
			-- Ask for the tools of the server (from `a_cursor', the next page, if any).
		local
			l_params: JSON_OBJECT
		do
			create l_params.make_with_capacity (1)
			if attached a_cursor then
				l_params.put_string (a_cursor, "cursor")
			else
				listed_tools.wipe_out
			end
			list_id := send_request ("tools/list", l_params)
		end

	add_listed_tools (o: JSON_OBJECT)
			-- Take into account the answer `o' to `tools/list'.
		local
			l_schema: JSON_OBJECT
		do
			if attached object_item (o, "error") as e then
				fail ({STRING_32} "tools not listed: " + error_text (e))
			elseif attached object_item (o, "result") as r then
				if attached array_item (r, "tools") as l_tools then
					across l_tools as v loop
						if attached string_item (v, "name") as l_name and then not l_name.is_empty and then definition.is_tool_given (l_name) then
							if attached object_item (v, "inputSchema") as s then
								l_schema := s
							else
								create l_schema.make_with_capacity (1)
								l_schema.put_string ("object", "type")
							end
							listed_tools.extend (create {AI_MCP_TOOL}.make (definition.name, l_name,
								if attached string_item (v, "description") as d then d else {STRING_32} "" end,
								l_schema, boolean_item (object_item (v, "annotations"), "readOnlyHint")))
						end
					end
				end
				if attached string_item (r, "nextCursor") as l_cursor and then not l_cursor.is_empty then
					list_tools (l_cursor)
				else
					tools := listed_tools.twin
					listed_tools.wipe_out
					state := State_ready
					status_message := {STRING_32} "running, " + tools.count.out + {STRING_32} " tool(s)"
				end
			end
		end

	call_result (o: JSON_OBJECT): TUPLE [text: STRING_32; is_error: BOOLEAN]
			-- Result of a call answered by `o': the text contents of the result (the others named only), or the error
		local
			l_text: STRING_32
		do
			if attached object_item (o, "error") as e then
				Result := [{STRING_32} "Error of the MCP server " + definition.name + {STRING_32} ": " + error_text (e), True]
			elseif attached object_item (o, "result") as r then
				create l_text.make (200)
				if attached array_item (r, "content") as l_content then
					across l_content as c loop
						if not l_text.is_empty then
							l_text.append_character ('%N')
						end
						l_text.append (content_text (c))
					end
				end
				if l_text.is_empty and then attached object_item (r, "structuredContent") as s then
					l_text.append ({UTF_CONVERTER}.utf_8_string_8_to_string_32 (s.representation))
				end
				if l_text.count > Max_result_count then
					l_text.keep_head (Max_result_count)
					l_text.append ({STRING_32} "%N[... cut: the result is longer than " + Max_result_count.out + {STRING_32} " characters]")
				end
				Result := [l_text, boolean_item (r, "isError")]
			else
				Result := [{STRING_32} "The MCP server " + definition.name + {STRING_32} " gave no result.", True]
			end
		end

	content_text (c: JSON_VALUE): STRING_32
			-- Text of the content `c' of a result: its text, or what it is
		do
			if attached string_item (c, "type") as t then
				if t.same_string ({STRING_32} "text") and then attached string_item (c, "text") as s then
					Result := s
				elseif t.same_string ({STRING_32} "resource") and then attached object_item (c, "resource") as r then
					if attached string_item (r, "text") as s then
						Result := s
					else
						Result := {STRING_32} "[resource: " + if attached string_item (r, "uri") as u then u else {STRING_32} "?" end + {STRING_32} "]"
					end
				elseif t.same_string ({STRING_32} "resource_link") then
					Result := {STRING_32} "[resource: " + if attached string_item (c, "uri") as u then u else {STRING_32} "?" end + {STRING_32} "]"
				else
					Result := {STRING_32} "[" + t
					if attached string_item (c, "mimeType") as m then
						Result.append ({STRING_32} ": " + m)
					end
					Result.append_character (']')
				end
			else
				Result := {STRING_32} "[unknown content]"
			end
		end

	error_text (e: JSON_OBJECT): STRING_32
			-- Message of the error `e'
		do
			if attached string_item (e, "message") as m then
				Result := m
			else
				Result := {UTF_CONVERTER}.utf_8_string_8_to_string_32 (e.representation)
			end
		end

	send_request (a_method: READABLE_STRING_8; a_params: JSON_OBJECT): INTEGER
			-- Send the request `a_method' with `a_params'; its id.
		local
			o: JSON_OBJECT
		do
			Result := next_id
			next_id := next_id + 1
			create o.make_with_capacity (4)
			o.put_string ("2.0", "jsonrpc")
			o.put_integer (Result, "id")
			o.put_string (a_method, "method")
			o.put (a_params, "params")
			send (o)
		end

	send (o: JSON_OBJECT)
			-- Send the message `o'.
		do
			if attached transport as t then
				t.send (o.representation)
			end
		end

feature {NONE} -- Implementation: state

	transport: detachable AI_MCP_STDIO_TRANSPORT
			-- Connection to the running server

	state: INTEGER
			-- One of `State_*'

	State_stopped: INTEGER = 0
	State_starting: INTEGER = 1
	State_ready: INTEGER = 2
	State_failed: INTEGER = 3
			-- States

	next_id: INTEGER
			-- Id of the next request

	initialize_id, list_id: INTEGER
			-- Ids of the requests `initialize' and `tools/list'

	start_deadline: detachable DATE_TIME
			-- Time by which the server must be ready

	listed_tools: ARRAYED_LIST [AI_MCP_TOOL]
			-- Tools of the pages of `tools/list' received so far

	pending_calls: HASH_TABLE [DATE_TIME, INTEGER]
			-- Calls waiting for their answer, with the time by which it must come

	results: HASH_TABLE [TUPLE [text: STRING_32; is_error: BOOLEAN], INTEGER]
			-- Results of the calls, not taken yet

	deadline (a_seconds: INTEGER): DATE_TIME
			-- Time in `a_seconds' seconds
		do
			create Result.make_now_utc
			Result.second_add (a_seconds)
		end

	fail (a_reason: READABLE_STRING_GENERAL)
			-- The server cannot be used, because of `a_reason'.
		do
			if attached transport as t then
				t.stop
				transport := Void
			end
			state := State_failed
			status_message := {STRING_32} "failed: " + a_reason.to_string_32
			add_log ({STRING_32} "(failed: " + a_reason.to_string_32 + {STRING_32} ")")
			end_calls ({STRING_32} "The MCP server " + definition.name + {STRING_32} " failed: " + a_reason.to_string_32)
			tools.wipe_out
		ensure
			failed: is_failed
		end

	end_calls (a_message: STRING_32)
			-- End the calls running with the error `a_message'.
		do
			across pending_calls as d loop
				results.force ([a_message, True], @d.key)
			end
			pending_calls.wipe_out
		end

	add_log (a_line: READABLE_STRING_GENERAL)
			-- Add `a_line' to `log' (forgetting the oldest lines).
		do
			if log.count >= Max_log_count then
				log.start
				log.remove
			end
			log.extend (a_line.to_string_32)
		end

invariant
	tools_attached: tools /= Void
	log_bounded: log.count <= Max_log_count

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
