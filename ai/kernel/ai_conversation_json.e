note
	description: "[
		Conversations with an AI model in JSON, to keep them (and their tool calls and results) and read them again:
		{"system_prompt": "...", "messages": [{"role": "user", "contents": [{"type": "text", "text": "..."}, ...]}, ...]}.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	AI_CONVERSATION_JSON

inherit
	AI_JSON_HELPER

feature -- Conversion

	json (a_conversation: AI_CONVERSATION): JSON_OBJECT
			-- `a_conversation' as a JSON object
		local
			l_messages: JSON_ARRAY
		do
			create Result.make_with_capacity (2)
			Result.put_string (a_conversation.system_prompt, "system_prompt")
			create l_messages.make (a_conversation.messages.count)
			⟳ m: a_conversation.messages ¦
				l_messages.extend (message_json (m))
			⟲
			Result.put (l_messages, "messages")
		end

	conversation (a_object: JSON_OBJECT): AI_CONVERSATION
			-- Conversation of JSON object `a_object' (made by `json'; what it does not know is ignored)
		local
			m: AI_MESSAGE
		do
			if attached string_item (a_object, "system_prompt") as p then
				create Result.make (p)
			else
				create Result.make ("")
			end
			if attached array_item (a_object, "messages") as l_messages then
				⟳ v: l_messages ¦
					if attached {JSON_OBJECT} v as o then
						if attached string_item (o, "role") as r and then r.same_string ("assistant") then
							create m.make_assistant
						else
							create m.make_user
						end
						if attached array_item (o, "contents") as l_contents then
							⟳ cv: l_contents ¦
								if attached {JSON_OBJECT} cv as c and then attached content (c) as l_content then
									m.extend (l_content)
								end
							⟲
						end
						if not m.contents.is_empty then
							Result.extend (m)
						end
					end
				⟲
			end
		end

feature {NONE} -- Implementation

	message_json (m: AI_MESSAGE): JSON_OBJECT
			-- Message `m' as a JSON object
		local
			l_contents: JSON_ARRAY
			c: JSON_OBJECT
		do
			create Result.make_with_capacity (2)
			Result.put_string (m.role, "role")
			create l_contents.make (m.contents.count)
			⟳ x: m.contents ¦
				create c.make_with_capacity (5)
				if x.is_text then
					c.put_string ("text", "type")
					c.put_string (x.text, "text")
				elseif x.is_tool_call then
					c.put_string ("tool_call", "type")
					c.put_string (x.tool_call_id, "id")
					c.put_string (x.tool_name, "name")
					if attached x.tool_input as i then
						c.put (i, "input")
					end
				elseif x.is_tool_result then
					c.put_string ("tool_result", "type")
					c.put_string (x.tool_call_id, "id")
					c.put_string (x.text, "text")
					c.put_boolean (x.is_error, "is_error")
				elseif attached x.provider_data as d then
					c.put_string ("provider_data", "type")
					c.put_string (x.text, "provider")
					c.put (d, "data")
				end
				l_contents.extend (c)
			⟲
			Result.put (l_contents, "contents")
		end

	content (c: JSON_OBJECT): detachable AI_CONTENT
			-- Content of JSON object `c' (made by `message_json'), if valid
		local
			l_type: STRING_32
		do
			if attached string_item (c, "type") as t then
				l_type := t
				if l_type.same_string ("text") and then attached string_item (c, "text") as s then
					create Result.make_text (s)
				elseif l_type.same_string ("tool_call") and then attached string_item (c, "id") as l_id and then attached string_item (c, "name") as n then
					if attached object_item (c, "input") as i then
						create Result.make_tool_call (l_id, n, i)
					else
						create Result.make_tool_call (l_id, n, create {JSON_OBJECT}.make_empty)
					end
				elseif l_type.same_string ("tool_result") and then attached string_item (c, "id") as l_id and then attached string_item (c, "text") as s then
					create Result.make_tool_result (l_id, s, boolean_item (c, "is_error"))
				elseif l_type.same_string ("provider_data") and then attached string_item (c, "provider") as p and then attached object_item (c, "data") as d then
					create Result.make_provider_data (p, d)
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
