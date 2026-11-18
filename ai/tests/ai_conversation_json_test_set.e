note
	description: "Tests of the conversations kept in JSON (AI_CONVERSATION_JSON) and of their compaction."
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	AI_CONVERSATION_JSON_TEST_SET

inherit
	EQA_TEST_SET

	AI_TEST_DATA
		undefine
			default_create
		end

	AI_JSON_HELPER
		undefine
			default_create
		end

feature -- Tests

	test_round_trip
			-- A conversation with texts, a tool call, its result and provider data is read again as it was.
		local
			c, c2: AI_CONVERSATION
			m: AI_MESSAGE
			i, d: JSON_OBJECT
			j: AI_CONVERSATION_JSON
		do
			create c.make ({STRING_32} "Be brief (%/0xE9/t%/0xE9/).")
			c.extend_user_text ({STRING_32} "Read A, %"quoted%"%Nplease")
			create m.make_assistant
			m.extend_text ("I read it.")
			create i.make_empty
			i.put_string ("A", "class")
			m.extend (create {AI_CONTENT}.make_tool_call ("call_1", "read_class", i))
			create d.make_empty
			d.put_string ("sig", "signature")
			m.extend (create {AI_CONTENT}.make_provider_data ("anthropic", d))
			c.extend (m)
			create m.make_user
			m.extend_tool_result ("call_1", "class A end", False)
			m.extend_tool_result ("call_2", "Unknown", True)
			c.extend (m)
			create j
			check attached parsed_json_object (j.json (c).representation) as o then
				c2 := j.conversation (o)
			end
			assert ("prompt", c2.system_prompt.same_string (c.system_prompt))
			assert ("three messages", c2.messages.count = 3)
			assert ("question", not c2.messages [1].is_assistant and c2.messages [1].text.same_string ({STRING_32} "Read A, %"quoted%"%Nplease"))
			assert ("answer", c2.messages [2].is_assistant and c2.messages [2].text.same_string_general ("I read it."))
			assert ("tool call", c2.messages [2].has_tool_calls and then c2.messages [2].tool_calls [1].tool_name.same_string_general ("read_class")
				and then c2.messages [2].tool_calls [1].tool_call_id.same_string_general ("call_1")
				and then string_item (c2.messages [2].tool_calls [1].tool_input, "class") ~ {STRING_32} "A")
			assert ("provider data", c2.messages [2].contents [3].is_provider_data and then c2.messages [2].contents [3].text.same_string_general ("anthropic")
				and then string_item (c2.messages [2].contents [3].provider_data, "signature") ~ {STRING_32} "sig")
			assert ("results", c2.messages [3].contents.count = 2 and then c2.messages [3].contents [1].is_tool_result
				and then c2.messages [3].contents [1].text.same_string_general ("class A end") and then not c2.messages [3].contents [1].is_error
				and then c2.messages [3].contents [2].is_error)
		end

	test_invalid_contents_ignored
			-- Contents of unknown types, and messages without any, are ignored.
		local
			j: AI_CONVERSATION_JSON
			c: AI_CONVERSATION
		do
			create j
			check attached parsed_json_object ("{%"messages%": [{%"role%": %"user%", %"contents%": [{%"type%": %"image%"}]}, {%"role%": %"assistant%", %"contents%": [{%"type%": %"text%", %"text%": %"Hi%"}, {%"type%": %"tool_call%"}]}]}") as o then
				c := j.conversation (o)
			end
			assert ("one message", c.messages.count = 1 and then c.messages [1].is_assistant and then c.messages [1].contents.count = 1)
			assert ("no prompt", c.system_prompt.is_empty)
		end

	test_compact_and_set_conversation
			-- A session compacted keeps the summary only; a conversation read again replaces its own.
		local
			s: AI_CHAT_SESSION
			c: AI_CONVERSATION
		do
			create s.make (provider ("http://127.0.0.1:1"), "m1", "Be brief.")
			s.conversation.extend_user_text ("Q1")
			s.conversation.extend_user_text ("Q2")
			s.compact_with ("We talked about Q1 and Q2.")
			assert ("two messages", s.conversation.messages.count = 2)
			assert ("summary", s.conversation.messages [1].text.has_substring ("We talked about Q1 and Q2.") and not s.conversation.messages [1].is_assistant)
			assert ("agreement", s.conversation.messages [2].is_assistant)
			create c.make ("Other")
			c.extend_user_text ("Q3")
			s.set_conversation (c, 100, 20)
			assert ("replaced", s.conversation = c and s.total_input_tokens = 100 and s.total_output_tokens = 20)
		end

feature {NONE} -- Implementation

	provider (a_url: READABLE_STRING_8): AI_PROVIDER
			-- OpenAI-compatible provider "test" at `a_url'
		do
			create {AI_OPENAI_PROVIDER} Result.make (create {AI_PROVIDER_SETTINGS}.make ("test", {AI_PROVIDER_SETTINGS}.Kind_openai, a_url, Void))
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
