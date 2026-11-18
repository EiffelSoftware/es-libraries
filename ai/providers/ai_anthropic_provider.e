note
	description: "[
		Anthropic (Claude models), through the Messages API: GET /v1/models, POST /v1/messages
		(streamed). The instructions (and the tools) are marked to be cached, as they stay the same in a
		conversation, and so is the last message: each request reads the conversation sent by the previous
		one from the cache, and only the new messages are read in full.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	AI_ANTHROPIC_PROVIDER

inherit
	AI_PROVIDER

create
	make

feature -- Requests

	models_request: AI_HTTP_REQUEST
			-- <Precursor>
		do
			create Result.make_get (base_url, "/v1/models?limit=1000")
			add_headers (Result)
		end

	chat_request (a_conversation: AI_CONVERSATION; a_model: READABLE_STRING_GENERAL; a_tools: detachable ITERABLE [AI_TOOL_DEFINITION]; a_max_tokens: INTEGER): AI_HTTP_REQUEST
			-- <Precursor>
		local
			o, b, l_cache: JSON_OBJECT
			l_system, l_tools, l_messages: JSON_ARRAY
			l_tool: JSON_OBJECT
		do
			create o.make_with_capacity (7)
			o.put_string (a_model, "model")
			if a_max_tokens > 0 then
				o.put_integer (a_max_tokens, "max_tokens")
			else
				o.put_integer (Default_max_tokens, "max_tokens")
			end
			o.put_boolean (True, "stream")
			if not a_conversation.system_prompt.is_empty then
				create l_system.make (1)
				create b.make_with_capacity (3)
				b.put_string ("text", "type")
				b.put_string (a_conversation.system_prompt, "text")
				create l_cache.make_with_capacity (1)
				l_cache.put_string ("ephemeral", "type")
				b.put (l_cache, "cache_control")
				l_system.extend (b)
				o.put (l_system, "system")
			end
			if a_tools /= Void then
				create l_tools.make (5)
				⟳ t: a_tools ¦
					create l_tool.make_with_capacity (3)
					l_tool.put_string (t.name, "name")
					l_tool.put_string (t.description, "description")
					l_tool.put (t.input_schema, "input_schema")
					l_tools.extend (l_tool)
				⟲
				if not l_tools.is_empty then
					o.put (l_tools, "tools")
				end
			end
			create l_messages.make (a_conversation.messages.count)
			⟳ m: a_conversation.messages ¦
					-- (The last message marked to be cached: the next request, sending the same conversation
					-- followed by the answer and the next message, reads it from the cache.)
				l_messages.extend (message_json (m, @m.is_last))
			⟲
			o.put (l_messages, "messages")
			create Result.make_post (base_url, "/v1/messages", o.representation, True)
			add_headers (Result)
		end

feature -- Answers

	models (a_body: READABLE_STRING_8): ARRAYED_LIST [AI_MODEL]
			-- <Precursor>
		local
			m: AI_MODEL
		do
			create Result.make (10)
			if attached array_item (parsed_json (a_body), "data") as l_data then
				⟳ d: l_data ¦
					if attached string_item (d, "id") as l_id and then not l_id.is_empty then
						create m.make (name, l_id)
						if attached string_item (d, "display_name") as n then
							m.set_display_name (n)
						end
						m.set_context_size (integer_item (d, "max_input_tokens").max (0))
						m.set_output_limit (integer_item (d, "max_tokens").max (0))
						Result.extend (m)
					end
				⟲
			end
		end

	new_stream_decoder: AI_STREAM_DECODER
			-- <Precursor>
		do
			create {AI_ANTHROPIC_STREAM_DECODER} Result.make
		end

feature -- Constants

	Api_version: STRING = "2026-10-21"
			-- Version of the API (header anthropic-version)

	Default_max_tokens: INTEGER = 64000
			-- Maximum length of an answer when not given (streamed answers allow long ones)

feature {NONE} -- Implementation

	add_headers (r: AI_HTTP_REQUEST)
			-- Add the headers of the requests to `r'.
		do
			r.add_header ("Content-Type", "application/json")
			r.add_header ("anthropic-version", Api_version)
			if attached settings.api_key as k then
				r.add_header ("x-api-key", utf_8 (k))
			end
			if attached settings.workspace as w then
				r.add_header ("anthropic-workspace-id", utf_8 (w))
			end
		end

	message_json (m: AI_MESSAGE; a_cached: BOOLEAN): JSON_OBJECT
			-- JSON of message `m', its last block marked to be cached if `a_cached' (unless it is data of the
			-- provider sent back as received, e.g. a thinking block)
		local
			l_content: JSON_ARRAY
			b, l_cache: JSON_OBJECT
			l_last: detachable JSON_OBJECT
		do
			create Result.make_with_capacity (2)
			Result.put_string (m.role, "role")
			create l_content.make (m.contents.count)
			⟳ c: m.contents ¦
				if c.is_text then
					if not c.text.is_empty then
						create b.make_with_capacity (2)
						b.put_string ("text", "type")
						b.put_string (c.text, "text")
						l_content.extend (b)
						l_last := b
					end
				elseif c.is_tool_call and then attached c.tool_input as l_input then
					create b.make_with_capacity (4)
					b.put_string ("tool_use", "type")
					b.put_string (c.tool_call_id, "id")
					b.put_string (c.tool_name, "name")
					b.put (l_input, "input")
					l_content.extend (b)
					l_last := b
				elseif c.is_tool_result then
					create b.make_with_capacity (4)
					b.put_string ("tool_result", "type")
					b.put_string (c.tool_call_id, "tool_use_id")
					b.put_string (c.text, "content")
					if c.is_error then
						b.put_boolean (True, "is_error")
					end
					l_content.extend (b)
					l_last := b
				elseif c.is_provider_data and then c.text.same_string_general (settings.Kind_anthropic) and then attached c.provider_data as d then
						-- (As received, e.g. a thinking block.)
					l_content.extend (d)
					l_last := Void
				end
			⟲
			if a_cached and attached l_last then
				create l_cache.make_with_capacity (1)
				l_cache.put_string ("ephemeral", "type")
				l_last.put (l_cache, "cache_control")
			end
			Result.put (l_content, "content")
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
