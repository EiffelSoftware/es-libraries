note
	description: "Tests of conversations with a model (a local server answering recorded streams)."
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	AI_CHAT_SESSION_TEST_SET

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

	test_two_questions
			-- The second question is sent with the first one and its answer; the transcript keeps both.
		local
			srv1, srv2: AI_TEST_SERVER
			s: AI_CHAT_SESSION
			l_path: PATH
			n: INTEGER
			l_versions: INTEGER
		do
			l_path := (create {EXECUTION_ENVIRONMENT}).current_working_path.extended ("ai_transcript_test").extended ("t.md")
			srv1 := started_server (openai_text_stream ("Hello"), 50)
			create s.make (provider (srv1.url), "m1", "Be brief.")
			s.set_transcript (create {AI_TRANSCRIPT}.make (l_path))
			s.ask ("Hi")
			assert ("answering", s.is_answering)
			from
			until
				not s.is_answering or n > 500
			loop
				if s.poll then
					l_versions := l_versions + 1
				end
				sleep_ms (10)
				n := n + 1
			end
			srv1.stop
			assert ("answered", not s.is_answering and s.last_error = Void)
			assert ("text", s.answer_text.same_string_general ("Hello, world!"))
			assert ("seen in parts", l_versions >= 2)
			assert ("two messages", s.conversation.messages.count = 2)
			assert ("tokens", s.input_tokens = 12 and s.total_output_tokens = 4)
				-- Second question, with another model (and server).
			srv2 := started_server (openai_text_stream ("Bye"), 0)
			s.set_model (provider (srv2.url), "m2")
			s.ask ("Again")
			s.wait
			srv2.stop
			assert ("second", s.answer_text.same_string_general ("Bye, world!"))
			assert ("four messages", s.conversation.messages.count = 4)
			assert ("totals", s.total_output_tokens = 8)
			if attached parsed_json_object (srv2.request_body) as o and then attached array_item (o, "messages") as l_messages then
				assert ("model", string_item (o, "model") ~ {STRING_32} "m2")
				assert ("history", l_messages.count = 4)
				assert ("system", string_item (l_messages [1], "content") ~ {STRING_32} "Be brief.")
				assert ("first answer", string_item (l_messages [3], "content") ~ {STRING_32} "Hello, world!")
				assert ("question", string_item (l_messages [4], "content") ~ {STRING_32} "Again")
			else
				assert ("JSON body", False)
			end
			assert ("transcript", attached file_text (l_path) as t and then (t.has_substring ("## You (") and t.has_substring ("Hi") and t.has_substring ("## test/m1 (") and t.has_substring ("Bye, world!")))
			(create {RAW_FILE}.make_with_path (l_path)).delete
		end

	test_error_forgets_question
			-- An error: the question is not kept in the conversation.
		local
			srv: AI_TEST_SERVER
			s: AI_CHAT_SESSION
		do
			create srv.make (500, 0, <<"{%"error%":{%"message%":%"model crashed%"}}">>, <<0>>)
			srv.start
			create s.make (provider (srv.url), "m", "")
			s.ask ("Hi")
			s.wait
			srv.stop
			assert ("error", attached s.last_error as e and then e.has_substring ("model crashed"))
			assert ("no messages", s.conversation.messages.is_empty)
		end

	test_stop
			-- A stopped answer is kept as far as received.
		local
			srv: AI_TEST_SERVER
			s: AI_CHAT_SESSION
			n: INTEGER
		do
			create srv.make (200, 0, <<"data: {%"choices%":[{%"index%":0,%"delta%":{%"content%":%"Partial%"}}]}%N%N", "data: [DONE]%N%N">>, <<0, 5000>>)
			srv.start
			create s.make (provider (srv.url), "m", "")
			s.ask ("Hi")
			from
			until
				s.answer_text.same_string_general ("Partial") or n > 300
			loop
				if s.poll then
				end
				sleep_ms (10)
				n := n + 1
			end
			s.stop
			s.wait
			srv.stop
			assert ("stopped", s.was_stopped)
			assert ("no error", s.last_error = Void)
			assert ("partial kept", s.conversation.messages.count = 2 and then s.conversation.messages [2].text.same_string_general ("Partial"))
		end

feature {NONE} -- Implementation

	openai_text_stream (a_word: STRING_8): ARRAY [READABLE_STRING_8]
			-- Stream answering "`a_word', world!" in three parts
		do
			Result := <<
				"data: {%"choices%":[{%"index%":0,%"delta%":{%"role%":%"assistant%",%"content%":%"" + a_word + "%"}}]}%N%N",
				"data: {%"choices%":[{%"index%":0,%"delta%":{%"content%":%", world!%"},%"finish_reason%":%"stop%"}]}%N%N",
				"data: {%"choices%":[],%"usage%":{%"prompt_tokens%":12,%"completion_tokens%":4}}%N%Ndata: [DONE]%N%N"
				>>
		end

	started_server (a_parts: ARRAY [READABLE_STRING_8]; a_delay_ms: INTEGER): AI_TEST_SERVER
			-- Server answering `a_parts', each after `a_delay_ms'
		local
			l_delays: ARRAY [INTEGER]
		do
			create l_delays.make_filled (a_delay_ms, 1, a_parts.count)
			create Result.make (200, 0, a_parts, l_delays)
			Result.start
			assert ("listening", Result.port > 0)
		end

	provider (a_url: READABLE_STRING_8): AI_PROVIDER
			-- OpenAI-compatible provider "test" at `a_url'
		do
			create {AI_OPENAI_PROVIDER} Result.make (create {AI_PROVIDER_SETTINGS}.make ("test", {AI_PROVIDER_SETTINGS}.Kind_openai, a_url, Void))
		end

	file_text (p: PATH): detachable STRING_8
			-- Content of file `p', if readable
		local
			f: PLAIN_TEXT_FILE
		do
			create f.make_with_path (p)
			if f.exists and then f.is_readable then
				f.open_read
				f.read_stream (f.count)
				Result := f.last_string.twin
				f.close
			end
		end

	sleep_ms (n: INTEGER)
			-- Wait `n' milliseconds.
		do
			(create {EXECUTION_ENVIRONMENT}).sleep (n.to_integer_64 * 1_000_000)
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
