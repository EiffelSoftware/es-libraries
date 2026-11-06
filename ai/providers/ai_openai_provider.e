note
	description: "[
		Provider compatible with the OpenAI Chat Completions API: OpenAI, NVIDIA (API catalog, NIM),
		llama-server, LM Studio, vLLM...: GET /v1/models, POST /v1/chat/completions (streamed),
		with a Bearer key when one is set.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	AI_OPENAI_PROVIDER

inherit
	AI_PROVIDER

create
	make

feature -- Requests

	models_request: AI_HTTP_REQUEST
			-- <Precursor>
		do
			create Result.make_get (base_url, "/v1/models")
			add_headers (Result)
		end

	chat_request (a_conversation: AI_CONVERSATION; a_model: READABLE_STRING_GENERAL; a_tools: detachable ITERABLE [AI_TOOL_DEFINITION]; a_max_tokens: INTEGER): AI_HTTP_REQUEST
			-- <Precursor>
			-- (`a_max_tokens' is not sent: compatible servers differ on its name.)
		local
			o, l_options, l_message, l_tool, l_function: JSON_OBJECT
			l_tools, l_messages: JSON_ARRAY
		do
			create o.make_with_capacity (6)
			o.put_string (a_model, "model")
			o.put_boolean (True, "stream")
			create l_options.make_with_capacity (1)
			l_options.put_boolean (True, "include_usage")
			o.put (l_options, "stream_options")
			create l_messages.make (a_conversation.messages.count + 1)
			if not a_conversation.system_prompt.is_empty then
				create l_message.make_with_capacity (2)
				l_message.put_string ("system", "role")
				l_message.put_string (a_conversation.system_prompt, "content")
				l_messages.extend (l_message)
			end
			⟳ m: a_conversation.messages ¦
				append_message_json (m, l_messages)
			⟲
			o.put (l_messages, "messages")
			if a_tools /= Void then
				create l_tools.make (5)
				⟳ t: a_tools ¦
					create l_function.make_with_capacity (3)
					l_function.put_string (t.name, "name")
					l_function.put_string (t.description, "description")
					l_function.put (t.input_schema, "parameters")
					create l_tool.make_with_capacity (2)
					l_tool.put_string ("function", "type")
					l_tool.put (l_function, "function")
					l_tools.extend (l_tool)
				⟲
				if not l_tools.is_empty then
					o.put (l_tools, "tools")
				end
			end
			create Result.make_post (base_url, "/v1/chat/completions", o.representation, True)
			add_headers (Result)
		end

feature -- Answers

	models (a_body: READABLE_STRING_8): ARRAYED_LIST [AI_MODEL]
			-- <Precursor>
		do
			create Result.make (10)
			if attached array_item (parsed_json (a_body), "data") as l_data then
				⟳ d: l_data ¦
					if attached string_item (d, "id") as l_id and then not l_id.is_empty then
						Result.extend (create {AI_MODEL}.make (name, l_id))
					end
				⟲
			end
		end

	new_stream_decoder: AI_STREAM_DECODER
			-- <Precursor>
		do
			create {AI_OPENAI_STREAM_DECODER} Result.make
		end

feature {NONE} -- Implementation

	add_headers (r: AI_HTTP_REQUEST)
			-- Add the headers of the requests to `r'.
		do
			r.add_header ("Content-Type", "application/json")
			if attached settings.api_key as k then
				r.add_header ("Authorization", "Bearer " + utf_8 (k))
			end
		end

	append_message_json (m: AI_MESSAGE; a_messages: JSON_ARRAY)
			-- Append the JSON of message `m' to `a_messages' (the results of tool calls are messages of their own).
		local
			l_message, l_call, l_function: JSON_OBJECT
			l_calls: JSON_ARRAY
		do
			if m.is_assistant then
				create l_message.make_with_capacity (3)
				l_message.put_string ("assistant", "role")
				if m.text.is_empty then
					l_message.put_null ("content")
				else
					l_message.put_string (m.text, "content")
				end
				if m.has_tool_calls then
					create l_calls.make (2)
					⟳ c: m.tool_calls ¦
						create l_function.make_with_capacity (2)
						l_function.put_string (c.tool_name, "name")
						if attached c.tool_input as l_input then
							l_function.put_string (l_input.representation, "arguments")
						end
						create l_call.make_with_capacity (3)
						l_call.put_string (c.tool_call_id, "id")
						l_call.put_string ("function", "type")
						l_call.put (l_function, "function")
						l_calls.extend (l_call)
					⟲
					l_message.put (l_calls, "tool_calls")
				end
				a_messages.extend (l_message)
			else
				⟳ c: m.contents ¦
					if c.is_tool_result then
						create l_message.make_with_capacity (3)
						l_message.put_string ("tool", "role")
						l_message.put_string (c.tool_call_id, "tool_call_id")
						l_message.put_string (c.text, "content")
						a_messages.extend (l_message)
					end
				⟲
				if not m.text.is_empty then
					create l_message.make_with_capacity (2)
					l_message.put_string ("user", "role")
					l_message.put_string (m.text, "content")
					a_messages.extend (l_message)
				end
			end
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
