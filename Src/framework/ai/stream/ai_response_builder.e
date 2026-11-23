note
	description: "[
		Builder of the message of a model from the events of its streamed answer: its texts, tool
		calls (with their JSON input) and data of the provider, in the order of their blocks; the
		reason of the end, the tokens used, the error if any.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	AI_RESPONSE_BUILDER

inherit
	AI_JSON_HELPER

create
	make

feature {NONE} -- Initialization

	make (a_provider_kind: READABLE_STRING_GENERAL)
			-- Builder for the answer of a provider of kind `a_provider_kind'.
		do
			provider_kind := a_provider_kind.to_string_32
			create blocks.make (4)
			create tool_inputs.make (2)
			create stop_reason.make_empty
		end

feature -- Access

	provider_kind: STRING_32
			-- Kind of the provider

	message: AI_MESSAGE
			-- Message built so far
		local
			l_indexes: SORTED_TWO_WAY_LIST [INTEGER]
		do
			create Result.make_assistant
			create l_indexes.make
			⟳ k: blocks.current_keys ¦
				l_indexes.extend (k)
			⟲
			⟳ i: l_indexes ¦
				if attached blocks.item (i) as c then
					Result.extend (c)
				end
			⟲
		end

	stop_reason: STRING_32
			-- Reason of the end of the answer (see {AI_STREAM_DECODER}.Stop_*), empty if not known

	input_tokens: INTEGER
	output_tokens: INTEGER
			-- Tokens used (`input_tokens': all the tokens read, those of the cache included)

	cache_read_tokens, cache_write_tokens: INTEGER
			-- Tokens of `input_tokens' read from the cache of the provider, and written to it

	error_message: detachable STRING_32
			-- Error, if any

feature -- Status report

	is_complete: BOOLEAN
			-- Was the end of the answer received?

	has_error: BOOLEAN
			-- Did an error occur?
		do
			Result := error_message /= Void
		end

feature -- Basic operations

	apply (e: AI_STREAM_EVENT)
			-- Take event `e' into account.
		do
			inspect e.kind
			when {AI_STREAM_EVENT}.Kind_text_block_start then
				if not blocks.has (e.index) then
					blocks.force (create {AI_CONTENT}.make_text (""), e.index)
				end
			when {AI_STREAM_EVENT}.Kind_text_delta then
				if attached blocks.item (e.index) as c and then c.is_text then
					c.append_text (e.text)
				else
					blocks.force (create {AI_CONTENT}.make_text (e.text), e.index)
				end
			when {AI_STREAM_EVENT}.Kind_tool_block_start then
				blocks.force (create {AI_CONTENT}.make_tool_call (e.id, e.name, create {JSON_OBJECT}.make_empty), e.index)
				tool_inputs.force (create {STRING_32}.make_empty, e.index)
			when {AI_STREAM_EVENT}.Kind_tool_input_delta then
				if attached tool_inputs.item (e.index) as s then
					s.append (e.text)
				end
			when {AI_STREAM_EVENT}.Kind_provider_data then
				if attached e.data as d then
					blocks.force (create {AI_CONTENT}.make_provider_data (provider_kind, d), e.index)
				end
			when {AI_STREAM_EVENT}.Kind_usage then
				if e.input_tokens > 0 then
					input_tokens := e.input_tokens
				end
				if e.output_tokens > 0 then
					output_tokens := e.output_tokens
				end
				if e.cache_read_tokens > 0 then
					cache_read_tokens := e.cache_read_tokens
				end
				if e.cache_write_tokens > 0 then
					cache_write_tokens := e.cache_write_tokens
				end
			when {AI_STREAM_EVENT}.Kind_stop then
				stop_reason := e.text
			when {AI_STREAM_EVENT}.Kind_done then
				finish
			when {AI_STREAM_EVENT}.Kind_error then
				error_message := e.text
				is_complete := True
			else
			end
		end

	apply_all (a_events: ITERABLE [AI_STREAM_EVENT])
			-- Take `a_events' into account.
		do
			⟳ e: a_events ¦ apply (e) ⟲
		end

	finish
			-- The answer is complete: parse the inputs of the tool calls.
		local
			l_call: AI_CONTENT
		do
			if not is_complete then
				is_complete := True
				⟳ i: tool_inputs.current_keys ¦
					if attached blocks.item (i) as c and then c.is_tool_call and then attached tool_inputs.item (i) as s then
						if s.is_empty then
							l_call := c
						elseif attached parsed_json_object (utf_8 (s)) as l_input then
							create l_call.make_tool_call (c.tool_call_id, c.tool_name, l_input)
							blocks.force (l_call, i)
						else
							error_message := {STRING_32} "Invalid input of the call of " + c.tool_name + {STRING_32} ": " + s
						end
					end
				⟲
			end
		ensure
			complete: is_complete
		end

feature {NONE} -- Implementation

	blocks: HASH_TABLE [AI_CONTENT, INTEGER]
			-- Contents of the message, by block index

	tool_inputs: HASH_TABLE [STRING_32, INTEGER]
			-- JSON inputs of the tool calls received so far, by block index

invariant
	tokens_non_negative: input_tokens >= 0 and output_tokens >= 0
	tool_inputs_of_blocks: ∀ i: tool_inputs.current_keys ¦ blocks.has (i)

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
