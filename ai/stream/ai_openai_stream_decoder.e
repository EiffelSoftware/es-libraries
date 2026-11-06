note
	description: "[
		Decoder of the streamed answers of the OpenAI Chat Completions API and of the servers
		compatible with it (NVIDIA, Ollama, llama-server, LM Studio, vLLM...): Server-Sent Events
		whose data are chunks (choices[0].delta: content, tool_calls; finish_reason; usage),
		ended by "[DONE]". The text is block 0, the tool call number n is block n + 1.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	AI_OPENAI_STREAM_DECODER

inherit
	AI_STREAM_DECODER

create
	make

feature {NONE} -- Implementation

	is_done: BOOLEAN
			-- Was the end received?

	process_event (a_name, a_data: STRING_8)
			-- <Precursor>
		local
			o: detachable JSON_OBJECT
			l_choice: detachable JSON_OBJECT
			l_index: INTEGER
		do
			if a_data.same_string ("[DONE]") then
				if not is_done then
					is_done := True
					events.extend (create {AI_STREAM_EVENT}.make_done)
				end
			else
				o := parsed_json_object (a_data)
				if o /= Void then
					if attached object_item (o, "error") as e then
						events.extend (create {AI_STREAM_EVENT}.make_error (if attached string_item (e, "message") as m then m else {STRING_32} "Error from the provider" end))
					end
					if attached array_item (o, "choices") as l_choices and then l_choices.count > 0 and then attached {JSON_OBJECT} l_choices [1] as c then
						l_choice := c
					end
					if l_choice /= Void then
						if attached object_item (l_choice, "delta") as d then
							if attached string_item (d, "content") as t and then not t.is_empty then
								events.extend (create {AI_STREAM_EVENT}.make_text_delta (0, t))
							end
							if attached array_item (d, "tool_calls") as l_calls then
								⟳ tc: l_calls ¦
									l_index := 1 + integer_item (tc, "index")
									if attached string_item (tc, "id") as l_id then
										events.extend (create {AI_STREAM_EVENT}.make_tool_block_start (l_index, l_id,
											if attached string_item (object_item (tc, "function"), "name") as n then n else {STRING_32} "" end))
									end
									if attached string_item (object_item (tc, "function"), "arguments") as l_arguments and then not l_arguments.is_empty then
										events.extend (create {AI_STREAM_EVENT}.make_tool_input_delta (l_index, l_arguments))
									end
								⟲
							end
						end
						if attached string_item (l_choice, "finish_reason") as r then
							events.extend (create {AI_STREAM_EVENT}.make_stop (normalized_reason (r)))
						end
					end
					if attached object_item (o, "usage") as u then
						events.extend (create {AI_STREAM_EVENT}.make_usage (integer_item (u, "prompt_tokens"), integer_item (u, "completion_tokens")))
					end
				end
			end
		end

	normalized_reason (r: READABLE_STRING_32): STRING_32
			-- Stop reason of the same meaning as `r' (see `Stop_*')
		do
			if r.same_string_general ("stop") then
				Result := Stop_end_turn
			elseif r.same_string_general ("tool_calls") or r.same_string_general ("function_call") then
				Result := Stop_tool_use
			elseif r.same_string_general ("length") then
				Result := Stop_max_tokens
			elseif r.same_string_general ("content_filter") then
				Result := Stop_refusal
			else
				Result := r.to_string_32
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
