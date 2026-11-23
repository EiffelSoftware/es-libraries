note
	description: "Tests of the requests of the providers, and of the reading of their lists of models."
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	AI_PROVIDER_TEST_SET

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

feature -- Tests: Anthropic

	test_anthropic_workspace
			-- The workspace of the settings (or of ANTHROPIC_WORKSPACE_ID) is sent in a header.
		local
			s: AI_PROVIDER_SETTINGS
			l_env: EXECUTION_ENVIRONMENT
			l_old: detachable STRING_32
		do
			create l_env
			l_old := l_env.item ({AI_PROVIDER_SETTINGS}.Workspace_variable)
			l_env.put ("", {AI_PROVIDER_SETTINGS}.Workspace_variable)
			create s.make ("test", {AI_PROVIDER_SETTINGS}.Kind_anthropic, "https://api.anthropic.com", Void)
			s.set_key ("sk-test")
			assert ("no workspace", header ((create {AI_PROVIDER_FACTORY}).new_provider (s).models_request, "anthropic-workspace-id") = Void)
			l_env.put ("wrkspc_env", {AI_PROVIDER_SETTINGS}.Workspace_variable)
			assert ("from the environment", header ((create {AI_PROVIDER_FACTORY}).new_provider (s).models_request, "anthropic-workspace-id") ~ "wrkspc_env")
			s.set_workspace_id ("wrkspc_01")
			assert ("models", header ((create {AI_PROVIDER_FACTORY}).new_provider (s).models_request, "anthropic-workspace-id") ~ "wrkspc_01")
			assert ("chat", header ((create {AI_PROVIDER_FACTORY}).new_provider (s).chat_request (conversation, "claude-opus-5-5", Void, 0), "anthropic-workspace-id") ~ "wrkspc_01")
			assert ("invalid", not s.is_valid_workspace_id ("a b") and not s.is_valid_workspace_id ("a%Nb") and not s.is_valid_workspace_id (""))
			s.set_workspace_id (Void)
			l_env.put ("", {AI_PROVIDER_SETTINGS}.Workspace_variable)
			assert ("none again", header ((create {AI_PROVIDER_FACTORY}).new_provider (s).models_request, "anthropic-workspace-id") = Void)
			if attached l_old then
				l_env.put (l_old, {AI_PROVIDER_SETTINGS}.Workspace_variable)
			end
		end

	test_anthropic_request
			-- Headers and body of a request with a system prompt, tools, a tool call and its result.
		local
			p: AI_PROVIDER
			r: AI_HTTP_REQUEST
		do
			p := provider ({AI_PROVIDER_SETTINGS}.Kind_anthropic, "https://api.anthropic.com/v1/")
			r := p.chat_request (conversation, "claude-opus-5-5", tools, 0)
			assert ("post", r.method.same_string ("POST"))
			assert ("url", r.url.same_string ("https://api.anthropic.com/v1/messages"))
			assert ("streamed", r.is_streamed)
			assert ("version", header (r, "anthropic-version") ~ {AI_ANTHROPIC_PROVIDER}.Api_version)
			assert ("key", header (r, "x-api-key") ~ "sk-test")
			if attached r.body as l_body and then attached parsed_json_object (l_body) as o then
				assert ("two cache marks (at most 4)", occurrence_count (l_body, "cache_control") = 2)
				assert ("model", string_item (o, "model") ~ {STRING_32} "claude-opus-5-5")
				assert ("max_tokens", integer_item (o, "max_tokens") = {AI_ANTHROPIC_PROVIDER}.Default_max_tokens)
				assert ("stream", boolean_item (o, "stream"))
				if attached array_item (o, "system") as l_system and then l_system.count = 1 then
					assert ("system text", string_item (l_system [1], "text") ~ {STRING_32} "You help with Eiffel.")
					assert ("cached", string_item (object_item (l_system [1], "cache_control"), "type") ~ {STRING_32} "ephemeral")
				else
					assert ("system", False)
				end
				if attached array_item (o, "tools") as l_tools and then l_tools.count = 1 then
					assert ("tool name", string_item (l_tools [1], "name") ~ {STRING_32} "class_text")
					assert ("tool schema", string_item (object_item (l_tools [1], "input_schema"), "type") ~ {STRING_32} "object")
				else
					assert ("tools", False)
				end
				if attached array_item (o, "messages") as l_messages and then l_messages.count = 3 then
					assert ("user", string_item (l_messages [1], "role") ~ {STRING_32} "user")
					assert ("assistant", string_item (l_messages [2], "role") ~ {STRING_32} "assistant")
					if attached array_item (l_messages [2], "content") as c and then c.count = 3 then
						assert ("thinking as received", string_item (c [1], "signature") ~ {STRING_32} "sig")
						assert ("text", string_item (c [2], "type") ~ {STRING_32} "text")
						assert ("tool_use", string_item (c [3], "type") ~ {STRING_32} "tool_use" and string_item (c [3], "id") ~ {STRING_32} "toolu_01")
						assert ("input", string_item (object_item (c [3], "input"), "class") ~ {STRING_32} "LIST")
					else
						assert ("assistant content", False)
					end
					assert ("assistant not marked", attached array_item (l_messages [2], "content") as c and then
						across c as x all not attached object_item (x, "cache_control") end)
					if attached array_item (l_messages [3], "content") as c and then c.count = 1 then
						assert ("last message cached", string_item (object_item (c [1], "cache_control"), "type") ~ {STRING_32} "ephemeral")
						assert ("tool_result", string_item (c [1], "type") ~ {STRING_32} "tool_result")
						assert ("tool_use_id", string_item (c [1], "tool_use_id") ~ {STRING_32} "toolu_01")
						assert ("result", string_item (c [1], "content") ~ {STRING_32} "class LIST ...")
					else
						assert ("result content", False)
					end
				else
					assert ("messages", False)
				end
			else
				assert ("JSON body", False)
			end
		end

	test_anthropic_models
			-- Models listed, with their limits when given.
		local
			l_models: LIST [AI_MODEL]
		do
			l_models := provider ({AI_PROVIDER_SETTINGS}.Kind_anthropic, "https://api.anthropic.com").models (anthropic_models)
			assert ("two", l_models.count = 2)
			assert ("id", l_models [1].id.same_string_general ("claude-opus-5-5"))
			assert ("display", l_models [1].display_name.same_string_general ("Claude Opus 5.5"))
			assert ("context", l_models [1].context_size = 1_000_000)
			assert ("output", l_models [1].output_limit = 128_000)
			assert ("unknown limits", l_models [2].context_size = 0 and l_models [2].output_limit = 0)
			assert ("full name", l_models [2].full_name.same_string_general ("test/claude-haiku-5-5"))
		end

feature -- Tests: OpenAI-compatible

	test_openai_request
			-- Body of a request: system message, tool call of the assistant, result as a "tool" message.
		local
			p: AI_PROVIDER
			r: AI_HTTP_REQUEST
		do
			p := provider ({AI_PROVIDER_SETTINGS}.Kind_openai, "https://integrate.api.nvidia.com/v1")
			r := p.chat_request (conversation, "meta/llama-4", tools, 0)
			assert ("url", r.url.same_string ("https://integrate.api.nvidia.com/v1/chat/completions"))
			assert ("bearer", header (r, "Authorization") ~ "Bearer sk-test")
			if attached r.body as l_body and then attached parsed_json_object (l_body) as o then
				assert ("usage asked", boolean_item (object_item (o, "stream_options"), "include_usage"))
				if attached array_item (o, "tools") as l_tools and then l_tools.count = 1 then
					assert ("function", string_item (object_item (l_tools [1], "function"), "name") ~ {STRING_32} "class_text")
				else
					assert ("tools", False)
				end
				if attached array_item (o, "messages") as l_messages and then l_messages.count = 4 then
					assert ("system", string_item (l_messages [1], "role") ~ {STRING_32} "system")
					assert ("user", string_item (l_messages [2], "content") ~ {STRING_32} "Show LIST")
					assert ("assistant text", string_item (l_messages [3], "content") ~ {STRING_32} "Reading it.")
					if attached array_item (l_messages [3], "tool_calls") as l_calls and then l_calls.count = 1 then
						assert ("call id", string_item (l_calls [1], "id") ~ {STRING_32} "toolu_01")
						assert ("arguments", attached string_item (object_item (l_calls [1], "function"), "arguments") as a and then
							attached parsed_json_object (utf_8 (a)) as l_arguments and then string_item (l_arguments, "class") ~ {STRING_32} "LIST")
					else
						assert ("tool calls", False)
					end
					assert ("tool", string_item (l_messages [4], "role") ~ {STRING_32} "tool")
					assert ("tool id", string_item (l_messages [4], "tool_call_id") ~ {STRING_32} "toolu_01")
				else
					assert ("messages", False)
				end
			else
				assert ("JSON body", False)
			end
		end

	test_openai_models
			-- Models listed by an OpenAI-compatible server and by Ollama.
		local
			l_models: LIST [AI_MODEL]
		do
			l_models := provider ({AI_PROVIDER_SETTINGS}.Kind_openai, "https://api.openai.com").models (openai_models)
			assert ("two", l_models.count = 2 and then l_models [2].id.same_string_general ("meta/llama-4"))
			l_models := provider ({AI_PROVIDER_SETTINGS}.Kind_ollama, "http://localhost:11434").models (ollama_models)
			assert ("ollama", l_models.count = 2 and then l_models [1].id.same_string_general ("qwen3:8b"))
			l_models := provider ({AI_PROVIDER_SETTINGS}.Kind_openai, "https://openrouter.ai/api/v1").models (openrouter_models)
			assert ("openrouter", l_models.count = 2 and then l_models [1].id.same_string_general ("anthropic/claude-opus-5-5"))
			assert ("openrouter name", l_models [1].display_name.same_string_general ("Anthropic: Claude Opus 5.5"))
			assert ("openrouter limits", l_models [1].context_size = 1_000_000 and l_models [1].output_limit = 128_000)
			assert ("openrouter without limits", l_models [2].context_size = 0 and l_models [2].output_limit = 0)
			assert ("openrouter url", provider ({AI_PROVIDER_SETTINGS}.Kind_openai, "https://openrouter.ai/api/v1").models_request.url.same_string ("https://openrouter.ai/api/v1/models"))
			assert ("ollama tags", provider ({AI_PROVIDER_SETTINGS}.Kind_ollama, "http://localhost:11434/").models_request.url.same_string ("http://localhost:11434/api/tags"))
		end

	test_error_message
			-- Message of an error answer.
		local
			p: AI_PROVIDER
		do
			p := provider ({AI_PROVIDER_SETTINGS}.Kind_anthropic, "https://api.anthropic.com")
			assert ("anthropic", p.error_message (401, "{%"type%":%"error%",%"error%":{%"type%":%"authentication_error%",%"message%":%"invalid x-api-key%"}}").has_substring ("invalid x-api-key"))
			assert ("not JSON", not p.error_message (502, "Bad gateway").is_empty)
		end

feature {NONE} -- Implementation

	provider (a_kind, a_url: READABLE_STRING_8): AI_PROVIDER
			-- Provider of kind `a_kind' at `a_url', with key "sk-test"
		local
			s: AI_PROVIDER_SETTINGS
		do
			create s.make ("test", a_kind, a_url, Void)
			s.set_key ("sk-test")
			Result := (create {AI_PROVIDER_FACTORY}).new_provider (s)
		end

	conversation: AI_CONVERSATION
			-- Conversation: a question, an answer with thinking and a tool call, the result of the call
		local
			m: AI_MESSAGE
			l_thinking, l_input: JSON_OBJECT
		do
			create Result.make ("You help with Eiffel.")
			Result.extend_user_text ("Show LIST")
			create m.make_assistant
			create l_thinking.make_with_capacity (3)
			l_thinking.put_string ("thinking", "type")
			l_thinking.put_string ("Read it.", "thinking")
			l_thinking.put_string ("sig", "signature")
			m.extend (create {AI_CONTENT}.make_provider_data ({AI_PROVIDER_SETTINGS}.Kind_anthropic, l_thinking))
			m.extend_text ("Reading it.")
			create l_input.make_with_capacity (1)
			l_input.put_string ("LIST", "class")
			m.extend (create {AI_CONTENT}.make_tool_call ("toolu_01", "class_text", l_input))
			Result.extend (m)
			create m.make_user
			m.extend_tool_result ("toolu_01", "class LIST ...", False)
			Result.extend (m)
		end

	tools: ARRAYED_LIST [AI_TOOL_DEFINITION]
			-- One tool
		local
			l_schema, l_properties, l_class: JSON_OBJECT
		do
			create l_class.make_with_capacity (1)
			l_class.put_string ("string", "type")
			create l_properties.make_with_capacity (1)
			l_properties.put (l_class, "class")
			create l_schema.make_with_capacity (2)
			l_schema.put_string ("object", "type")
			l_schema.put (l_properties, "properties")
			create Result.make (1)
			Result.extend (create {AI_TOOL_DEFINITION}.make ("class_text", "Text of a class", l_schema))
		end

	header (r: AI_HTTP_REQUEST; a_name: READABLE_STRING_8): detachable STRING_8
			-- Value of header `a_name' of `r', if any
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > r.headers.count or Result /= Void
			loop
				if r.headers [i].name.is_case_insensitive_equal (a_name) then
					Result := r.headers [i].value
				end
				i := i + 1
			end
		end

feature {NONE} -- Counting

	occurrence_count (s, a_part: READABLE_STRING_8): INTEGER
			-- Number of occurrences of `a_part' in `s'
		local
			i: INTEGER
		do
			from
				i := s.substring_index (a_part, 1)
			until
				i = 0
			loop
				Result := Result + 1
				i := s.substring_index (a_part, i + a_part.count)
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
