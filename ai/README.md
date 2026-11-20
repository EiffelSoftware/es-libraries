# es_ai: access to AI models

Library used by the EiffelStudio tools (first `ec -tui`) to talk to AI models. It does not depend on any
user interface, nor on the compiler.

## Providers

| Kind | Protocol | Examples |
|------|----------|----------|
| `anthropic` | Messages API (`POST /v1/messages`, `GET /v1/models`) | Anthropic (Claude) |
| `openai` | Chat Completions (`POST /v1/chat/completions`, `GET /v1/models`) | OpenAI, NVIDIA, OpenRouter, llama-server, LM Studio, vLLM |
| `ollama` | Chat Completions, models by `GET /api/tags` | Ollama |

The default settings (`{AI_SETTINGS}.make_default`) declare `anthropic`, `openai`, `nvidia`, `openrouter` (keys in
`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `NVIDIA_API_KEY`, `OPENROUTER_API_KEY`), and the local `ollama` (port 11434) and `llama.app` (port 9931); the default model is
`anthropic/claude-opus-5-5`. A key can also be kept in the settings file, which is then readable by its owner only.
An Anthropic provider may have a `workspace_id` (or use the environment variable `ANTHROPIC_WORKSPACE_ID`), sent in the
`anthropic-workspace-id` header: needed by the API keys that are not scoped to a workspace.

## Classes

- `kernel`: conversations (`AI_CONVERSATION`, `AI_MESSAGE`, `AI_CONTENT`: text, tool calls and results, data
  the provider needs back such as thinking blocks), tools (`AI_TOOL_DEFINITION`), models (`AI_MODEL`).
- `providers`: `AI_PROVIDER` builds the requests (`models_request`, `chat_request`) and reads the answers
  (`models`, `error_message`, `new_stream_decoder`); `AI_PROVIDER_FACTORY` creates the provider of some settings.
- `stream`: decoding of streamed answers (`AI_SSE_PARSER`, `AI_*_STREAM_DECODER` producing `AI_STREAM_EVENT`s)
  and `AI_RESPONSE_BUILDER`, which builds the message (texts, tool calls with their input) from the events.
- `transport`: `AI_REQUEST_JOB` performs a request in a thread with the `http_client` library; the user interface
  polls it (`take_events`, `is_finished`) and can stop it (`cancel`).
- `settings`: `AI_SETTINGS` and `AI_PROVIDER_SETTINGS`, saved as JSON (with `keeps_transcripts`); `is_local`
  tells a provider on this machine.
- `session`: `AI_CHAT_SESSION`, a conversation with a model: `ask` sends a question with the conversation so far,
  `poll` takes the answer received into account (`answer_text`, `answer_version`), `stop` stops it; an answer is kept
  in the conversation, an error forgets the question. With `set_tools`, the model may call tools: after its answer,
  `pending_tool_calls` are run by the application, and `answer_tool_calls` sends their results (the model goes on, up to
  `max_rounds` times per question). `AI_TRANSCRIPT` appends the questions and answers to a Markdown file.
- `mcp`: clients of MCP servers (Model Context Protocol), started as programs (stdio). `AI_MCP_CONFIGURATION` reads
  configuration files in the format of `.mcp.json` (`command`, `args`, `env` with `${VARIABLE}`, `cwd`, and the
  options `tools`, `timeout`, `disabled`); `AI_MCP_STDIO_TRANSPORT` runs the server with pipes (the `process`
  library), its output and error read by threads, calling `Message_notification` after each line;
  `AI_MCP_CLIENT` never waits: `start`, then `poll` (initialization, `tools/list` with its pages, the
  notifications and requests of the server), `call_tool` and later `take_result`, with a timeout per call;
  `AI_MCP_TOOL` gives a tool to the model as `mcp__SERVER__TOOL` (`definition`).

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

The tests of the MCP client (`AI_MCP_TEST_SET`) run the fake server `tests/mcp_fake_server.py` with `python3`,
found from the variable `EIFFEL_SRC` (or `ISE_LIBRARY`).
