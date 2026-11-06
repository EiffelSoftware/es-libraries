# es_ai: access to AI models

Library used by the EiffelStudio tools (first `ec -tui`) to talk to AI models. It does not depend on any
user interface, nor on the compiler.

## Providers

| Kind | Protocol | Examples |
|------|----------|----------|
| `anthropic` | Messages API (`POST /v1/messages`, `GET /v1/models`) | Anthropic (Claude) |
| `openai` | Chat Completions (`POST /v1/chat/completions`, `GET /v1/models`) | OpenAI, NVIDIA, llama-server, LM Studio, vLLM |
| `ollama` | Chat Completions, models by `GET /api/tags` | Ollama |

The default settings (`{AI_SETTINGS}.make_default`) declare `anthropic`, `openai`, `nvidia` (keys in
`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `NVIDIA_API_KEY`) and a local `ollama`; the default model is
`anthropic/claude-opus-5-5`. A key can also be kept in the settings file, which is then readable by its owner only.

## Classes

- `kernel`: conversations (`AI_CONVERSATION`, `AI_MESSAGE`, `AI_CONTENT`: text, tool calls and results, data
  the provider needs back such as thinking blocks), tools (`AI_TOOL_DEFINITION`), models (`AI_MODEL`).
- `providers`: `AI_PROVIDER` builds the requests (`models_request`, `chat_request`) and reads the answers
  (`models`, `error_message`, `new_stream_decoder`); `AI_PROVIDER_FACTORY` creates the provider of some settings.
- `stream`: decoding of streamed answers (`AI_SSE_PARSER`, `AI_*_STREAM_DECODER` producing `AI_STREAM_EVENT`s)
  and `AI_RESPONSE_BUILDER`, which builds the message (texts, tool calls with their input) from the events.
- `transport`: `AI_REQUEST_JOB` performs a request in a thread with the `http_client` library; the user interface
  polls it (`take_events`, `is_finished`) and can stop it (`cancel`).
- `settings`: `AI_SETTINGS` and `AI_PROVIDER_SETTINGS`, saved as JSON.

```eiffel
	p := (create {AI_PROVIDER_FACTORY}).new_provider (settings.provider_named ("anthropic"))
	create conversation.make ("You help with Eiffel code.")
	conversation.extend_user_text ("What does {LIST}.forth do?")
	create job.make (p.chat_request (conversation, "claude-opus-5-5", Void, 0), p.new_stream_decoder)
	create builder.make (p.settings.kind)
	job.start
		-- Then, at each tick of the user interface:
	builder.apply_all (job.take_events)
	if job.is_finished then
		builder.apply_all (job.take_events)
		if not job.is_success then
			... p.error_message (job.status, job.body) ...
		end
		conversation.extend (builder.message)
	end
```

## Tests

The tests use answers recorded from the providers, and a local server for the requests (no network access, no key):

```bash
ec -batch -config Src/framework/ai/ai.ecf -target es_ai_tests -project_path <dir> -tests
```
