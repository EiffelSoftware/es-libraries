note
	description: "[
		Event of a streamed answer of a model, the same for every provider: a block starting (text
		or tool call), text, a part of the JSON input of a tool call, data of the provider to send
		back, token usage, the reason of the end, the end, or an error. Blocks are numbered (`index').
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	AI_STREAM_EVENT

create
	make_text_block_start,
	make_tool_block_start,
	make_text_delta,
	make_tool_input_delta,
	make_provider_data,
	make_usage,
	make_stop,
	make_done,
	make_error

feature {NONE} -- Initialization

	make_text_block_start (a_index: INTEGER)
			-- Start of text block `a_index'.
		do
			make_kind (Kind_text_block_start, a_index)
		end

	make_tool_block_start (a_index: INTEGER; a_id, a_name: READABLE_STRING_GENERAL)
			-- Start of the call `a_id' of tool `a_name', block `a_index'.
		do
			make_kind (Kind_tool_block_start, a_index)
			id := a_id.to_string_32
			name := a_name.to_string_32
		end

	make_text_delta (a_index: INTEGER; a_text: READABLE_STRING_GENERAL)
			-- Text `a_text' of block `a_index'.
		do
			make_kind (Kind_text_delta, a_index)
			text := a_text.to_string_32
		end

	make_tool_input_delta (a_index: INTEGER; a_json: READABLE_STRING_GENERAL)
			-- Part `a_json' of the JSON input of the tool call of block `a_index'.
		do
			make_kind (Kind_tool_input_delta, a_index)
			text := a_json.to_string_32
		end

	make_provider_data (a_index: INTEGER; a_data: JSON_OBJECT)
			-- Data `a_data' of the provider, block `a_index'.
		do
			make_kind (Kind_provider_data, a_index)
			data := a_data
		end

	make_usage (a_input_tokens, a_output_tokens: INTEGER)
			-- Tokens used: `a_input_tokens' read, `a_output_tokens' written (0 if not given).
		do
			make_kind (Kind_usage, 0)
			input_tokens := a_input_tokens
			output_tokens := a_output_tokens
		end

	make_stop (a_reason: READABLE_STRING_GENERAL)
			-- Reason `a_reason' of the end of the answer (see {AI_STREAM_DECODER}.Stop_*).
		do
			make_kind (Kind_stop, 0)
			text := a_reason.to_string_32
		end

	make_done
			-- End of the answer.
		do
			make_kind (Kind_done, 0)
		end

	make_error (a_message: READABLE_STRING_GENERAL)
			-- Error `a_message'.
		do
			make_kind (Kind_error, 0)
			text := a_message.to_string_32
		end

	make_kind (a_kind, a_index: INTEGER)
			-- Event of kind `a_kind' for block `a_index'.
		do
			kind := a_kind
			index := a_index
			create text.make_empty
			create id.make_empty
			create name.make_empty
		end

feature -- Access

	kind: INTEGER
			-- Kind (see `Kind_*')

	index: INTEGER
			-- Number of the block

	text: STRING_32
			-- Text, JSON part, stop reason or error message

	id: STRING_32
			-- Identifier of a tool call

	name: STRING_32
			-- Name of the tool called

	data: detachable JSON_OBJECT
			-- Data of the provider

	input_tokens, output_tokens: INTEGER
			-- Token usage

feature -- Kinds

	Kind_text_block_start: INTEGER = 1
	Kind_tool_block_start: INTEGER = 2
	Kind_text_delta: INTEGER = 3
	Kind_tool_input_delta: INTEGER = 4
	Kind_provider_data: INTEGER = 5
	Kind_usage: INTEGER = 6
	Kind_stop: INTEGER = 7
	Kind_done: INTEGER = 8
	Kind_error: INTEGER = 9

invariant
	valid_kind: kind >= Kind_text_block_start and kind <= Kind_error

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
