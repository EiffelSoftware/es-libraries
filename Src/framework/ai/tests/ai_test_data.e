note
	description: "Answers recorded from the providers (shortened), for the tests."
	date: "$Date$"
	revision: "$Revision$"

class
	AI_TEST_DATA

feature -- Streams

	anthropic_stream: STRING_8
			-- Streamed answer of the Messages API: thinking, text (with a UTF-8 character), a tool call
		once
			Result := "[
event: message_start
data: {"type":"message_start","message":{"id":"msg_01","type":"message","role":"assistant","model":"claude-opus-5-5","content":[],"stop_reason":null,"usage":{"input_tokens":472,"cache_creation_input_tokens":0,"cache_read_input_tokens":10,"output_tokens":1}}}

event: content_block_start
data: {"type":"content_block_start","index":0,"content_block":{"type":"thinking","thinking":"","signature":""}}

event: content_block_delta
data: {"type":"content_block_delta","index":0,"delta":{"type":"thinking_delta","thinking":"Let me look "}}

event: ping
data: {"type": "ping"}

event: content_block_delta
data: {"type":"content_block_delta","index":0,"delta":{"type":"thinking_delta","thinking":"at the class."}}

event: content_block_delta
data: {"type":"content_block_delta","index":0,"delta":{"type":"signature_delta","signature":"EqQBCgIYAhIM"}}

event: content_block_stop
data: {"type":"content_block_stop","index":0}

event: content_block_start
data: {"type":"content_block_start","index":1,"content_block":{"type":"text","text":""}}

event: content_block_delta
data: {"type":"content_block_delta","index":1,"delta":{"type":"text_delta","text":"I will read "}}

event: content_block_delta
data: {"type":"content_block_delta","index":1,"delta":{"type":"text_delta","text":"{LIST}. 
]" + "%/0xE2/%/0x9C/%/0x93/" + "[
"}}

event: content_block_stop
data: {"type":"content_block_stop","index":1}

event: content_block_start
data: {"type":"content_block_start","index":2,"content_block":{"type":"tool_use","id":"toolu_01","name":"class_text","input":{}}}

event: content_block_delta
data: {"type":"content_block_delta","index":2,"delta":{"type":"input_json_delta","partial_json":""}}

event: content_block_delta
data: {"type":"content_block_delta","index":2,"delta":{"type":"input_json_delta","partial_json":"{\"class\": \"LI"}}

event: content_block_delta
data: {"type":"content_block_delta","index":2,"delta":{"type":"input_json_delta","partial_json":"ST\"}"}}

event: content_block_stop
data: {"type":"content_block_stop","index":2}

event: message_delta
data: {"type":"message_delta","delta":{"stop_reason":"tool_use","stop_sequence":null},"usage":{"output_tokens":89}}

event: message_stop
data: {"type":"message_stop"}


]"
		end

	openai_stream: STRING_8
			-- Streamed answer of the Chat Completions API: text, then two tool calls, then the usage
		once
			Result := "[
data: {"id":"c1","object":"chat.completion.chunk","choices":[{"index":0,"delta":{"role":"assistant","content":""},"finish_reason":null}]}

data: {"id":"c1","object":"chat.completion.chunk","choices":[{"index":0,"delta":{"content":"Looking "},"finish_reason":null}]}

data: {"id":"c1","object":"chat.completion.chunk","choices":[{"index":0,"delta":{"content":"at both."},"finish_reason":null}]}

data: {"id":"c1","object":"chat.completion.chunk","choices":[{"index":0,"delta":{"tool_calls":[{"index":0,"id":"call_a","type":"function","function":{"name":"class_text","arguments":""}}]},"finish_reason":null}]}

data: {"id":"c1","object":"chat.completion.chunk","choices":[{"index":0,"delta":{"tool_calls":[{"index":0,"function":{"arguments":"{\"class\":\"LIST\"}"}}]},"finish_reason":null}]}

data: {"id":"c1","object":"chat.completion.chunk","choices":[{"index":0,"delta":{"tool_calls":[{"index":1,"id":"call_b","type":"function","function":{"name":"class_text","arguments":"{\"cla"}}]},"finish_reason":null}]}

data: {"id":"c1","object":"chat.completion.chunk","choices":[{"index":0,"delta":{"tool_calls":[{"index":1,"function":{"arguments":"ss\":\"ARRAY\"}"}}]},"finish_reason":null}]}

data: {"id":"c1","object":"chat.completion.chunk","choices":[{"index":0,"delta":{},"finish_reason":"tool_calls"}]}

data: {"id":"c1","object":"chat.completion.chunk","choices":[],"usage":{"prompt_tokens":120,"completion_tokens":33,"total_tokens":153}}

data: [DONE]


]"
		end

feature -- Lists of models

	anthropic_models: STRING_8 = "[
		{"data":[{"type":"model","id":"claude-opus-5-5","display_name":"Claude Opus 5.5","created_at":"2026-08-01T00:00:00Z","max_input_tokens":1000000,"max_tokens":128000},{"type":"model","id":"claude-haiku-5-5","display_name":"Claude Haiku 5.5","created_at":"2026-08-01T00:00:00Z"}],"has_more":false,"first_id":"claude-opus-5-5","last_id":"claude-haiku-5-5"}
	]"
			-- Answer of GET /v1/models (Anthropic)

	openai_models: STRING_8 = "[
		{"object":"list","data":[{"id":"gpt-5","object":"model","created":1,"owned_by":"system"},{"id":"meta/llama-4","object":"model","created":1,"owned_by":"meta"}]}
	]"
			-- Answer of GET /v1/models (OpenAI-compatible)

	openrouter_models: STRING_8 = "[
		{"data":[{"id":"anthropic/claude-opus-5-5","canonical_slug":"anthropic/claude-opus-5-5","name":"Anthropic: Claude Opus 5.5","context_length":1000000,"architecture":{"modality":"text+image->text"},"pricing":{"prompt":"0.000005","completion":"0.000025"},"top_provider":{"context_length":1000000,"max_completion_tokens":128000,"is_moderated":false}},{"id":"qwen/qwen3-coder","name":"Qwen: Qwen3 Coder","top_provider":{"is_moderated":false}}]}
	]"
			-- Answer of GET /api/v1/models (OpenRouter)

	ollama_models: STRING_8 = "[
		{"models":[{"name":"qwen3:8b","model":"qwen3:8b","size":5200000000},{"name":"llama3.2:latest","model":"llama3.2:latest","size":2000000000}]}
	]"
			-- Answer of GET /api/tags (Ollama)

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
