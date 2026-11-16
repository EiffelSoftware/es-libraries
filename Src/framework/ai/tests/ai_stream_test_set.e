note
	description: "Tests of the decoding of streamed answers (Server-Sent Events, Anthropic and OpenAI formats)."
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	AI_STREAM_TEST_SET

inherit
	EQA_TEST_SET

	AI_TEST_DATA
		undefine
			default_create
		end

feature -- Tests: Server-Sent Events

	test_sse_parts
			-- Events split anywhere, CR LF line ends, comments, data on several lines.
		local
			p: AI_SSE_PARSER
		do
			create p.make
			p.feed (": comment%R%Nevent: a%R%Ndata: 1%R")
			assert ("nothing yet", p.events.is_empty)
			p.feed ("%N%R%Ndata: first%N")
			p.feed ("data:second%N%Nev")
			p.feed ("ent: c%Ndata: last")
			assert ("two events", p.events.count = 2)
			assert ("name a", p.events [1].name.same_string ("a"))
			assert ("data 1", p.events [1].data.same_string ("1"))
			assert ("no name", p.events [2].name.is_empty)
			assert ("joined", p.events [2].data.same_string ("first%Nsecond"))
			p.wipe_out_events
			p.finish
			assert ("last one", p.events.count = 1 and then p.events [1].name.same_string ("c") and then p.events [1].data.same_string ("last"))
		end

feature -- Tests: Anthropic

	test_anthropic_stream
			-- Thinking, text and a tool call whose input is received in parts.
		local
			b: AI_RESPONSE_BUILDER
			m: AI_MESSAGE
		do
			b := built_answer (create {AI_ANTHROPIC_STREAM_DECODER}.make, {AI_PROVIDER_SETTINGS}.Kind_anthropic, anthropic_stream, 7)
			assert ("complete", b.is_complete)
			assert ("no error", not b.has_error)
			assert ("stop tool_use", b.stop_reason.same_string ({AI_STREAM_DECODER}.Stop_tool_use))
			assert ("input tokens", b.input_tokens = 472 + 10 + 0)
			assert ("output tokens", b.output_tokens = 89)
			m := b.message
			assert ("assistant", m.is_assistant)
			assert ("three blocks", m.contents.count = 3)
			assert ("thinking first", m.contents [1].is_provider_data)
			if attached m.contents [1].provider_data as d then
				assert ("thinking text", attached {JSON_STRING} d.item ("thinking") as t and then t.unescaped_string_32.same_string ("Let me look at the class."))
				assert ("signature", attached {JSON_STRING} d.item ("signature") as s and then s.unescaped_string_32.same_string ("EqQBCgIYAhIM"))
			end
			assert ("text", m.text.same_string ({STRING_32} "I will read {LIST}. %/0x2713/"))
			assert ("one call", m.tool_calls.count = 1)
			assert ("call id", m.tool_calls [1].tool_call_id.same_string_general ("toolu_01"))
			assert ("call name", m.tool_calls [1].tool_name.same_string_general ("class_text"))
			if attached m.tool_calls [1].tool_input as l_input then
				assert ("input", attached {JSON_STRING} l_input.item ("class") as c and then c.item.same_string ("LIST"))
			else
				assert ("has input", False)
			end
		end

	test_anthropic_error
			-- An error event during the answer.
		local
			b: AI_RESPONSE_BUILDER
		do
			b := built_answer (create {AI_ANTHROPIC_STREAM_DECODER}.make, {AI_PROVIDER_SETTINGS}.Kind_anthropic,
				"event: error%Ndata: {%"type%":%"error%",%"error%":{%"type%":%"overloaded_error%",%"message%":%"Overloaded%"}}%N%N", 3)
			assert ("error", attached b.error_message as e and then e.same_string_general ("Overloaded"))
			assert ("complete", b.is_complete)
		end

feature -- Tests: OpenAI

	test_openai_stream
			-- Text then two tool calls whose arguments are received in parts, then the usage.
		local
			b: AI_RESPONSE_BUILDER
			m: AI_MESSAGE
		do
			b := built_answer (create {AI_OPENAI_STREAM_DECODER}.make, {AI_PROVIDER_SETTINGS}.Kind_openai, openai_stream, 5)
			assert ("complete", b.is_complete)
			assert ("no error", not b.has_error)
			assert ("stop tool_use", b.stop_reason.same_string ({AI_STREAM_DECODER}.Stop_tool_use))
			assert ("input tokens", b.input_tokens = 120)
			assert ("output tokens", b.output_tokens = 33)
			m := b.message
			assert ("text", m.text.same_string_general ("Looking at both."))
			assert ("two calls", m.tool_calls.count = 2)
			assert ("first", m.tool_calls [1].tool_call_id.same_string_general ("call_a") and m.tool_calls [1].tool_name.same_string_general ("class_text"))
			assert ("second", m.tool_calls [2].tool_call_id.same_string_general ("call_b"))
			if attached m.tool_calls [2].tool_input as l_input then
				assert ("input", attached {JSON_STRING} l_input.item ("class") as c and then c.item.same_string ("ARRAY"))
			else
				assert ("has input", False)
			end
		end

	test_openai_end_without_done
			-- A stream ended without "[DONE]" (some servers): the end of the transfer completes it.
		local
			d: AI_OPENAI_STREAM_DECODER
			b: AI_RESPONSE_BUILDER
		do
			create d.make
			create b.make ({AI_PROVIDER_SETTINGS}.Kind_openai)
			d.feed ("data: {%"choices%":[{%"index%":0,%"delta%":{%"content%":%"Hi%"},%"finish_reason%":%"length%"}]}%N%N")
			b.apply_all (d.take_events)
			assert ("not complete", not b.is_complete)
			b.finish
			assert ("complete", b.is_complete)
			assert ("max tokens", b.stop_reason.same_string ({AI_STREAM_DECODER}.Stop_max_tokens))
			assert ("text", b.message.text.same_string_general ("Hi"))
		end

feature {NONE} -- Implementation

	built_answer (d: AI_STREAM_DECODER; a_kind: READABLE_STRING_8; a_stream: READABLE_STRING_8; a_part_count: INTEGER): AI_RESPONSE_BUILDER
			-- Answer built from `a_stream' given to `d' in `a_part_count' parts of the same size.
		local
			i, n: INTEGER
		do
			create Result.make (a_kind)
			n := (a_stream.count // a_part_count).max (1)
			from
				i := 1
			until
				i > a_stream.count
			loop
				d.feed (a_stream.substring (i, (i + n - 1).min (a_stream.count)))
				Result.apply_all (d.take_events)
				i := i + n
			end
			d.finish
			Result.apply_all (d.take_events)
			Result.finish
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
