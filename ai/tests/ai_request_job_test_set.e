note
	description: "Tests of requests performed in a thread, against a local server."
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	AI_REQUEST_JOB_TEST_SET

inherit
	EQA_TEST_SET

	AI_TEST_DATA
		undefine
			default_create
		end

feature -- Tests

	test_streamed_answer
			-- Events arrive while the answer is received; the message built is complete.
		local
			srv: AI_TEST_SERVER
			p: AI_PROVIDER
			j: AI_REQUEST_JOB
			b: AI_RESPONSE_BUILDER
			n: INTEGER
		do
			srv := started_server (200, 0, parts (anthropic_stream, 4), <<100, 100, 100, 100>>)
			p := provider (srv.url)
			create j.make (p.chat_request (create {AI_CONVERSATION}.make ("System"), "claude-opus-5-5", Void, 100), p.new_stream_decoder)
			create b.make ({AI_PROVIDER_SETTINGS}.Kind_anthropic)
			j.start
			from
			until
				j.is_finished or n > 500
			loop
				b.apply_all (j.take_events)
				sleep_ms (20)
				n := n + 1
			end
			j.wait
			b.apply_all (j.take_events)
			srv.stop
			assert ("success", j.is_success)
			assert ("status", j.status = 200)
			assert ("complete", b.is_complete and not b.has_error)
			assert ("text", b.message.text.same_string ({STRING_32} "I will read {LIST}. %/0x2713/"))
			assert ("tool call", b.message.tool_calls.count = 1)
			assert ("posted", srv.request_text.starts_with ("POST /v1/messages "))
			assert ("key sent", srv.request_text.has_substring ("x-api-key: sk-test"))
		end

	test_cancel
			-- A request is stopped soon after `cancel', in the middle of a slow answer.
		local
			srv: AI_TEST_SERVER
			p: AI_PROVIDER
			j: AI_REQUEST_JOB
			t: INTEGER_64
		do
			srv := started_server (200, 0, parts (anthropic_stream, 3), <<0, 5000, 5000>>)
			p := provider (srv.url)
			create j.make (p.chat_request (create {AI_CONVERSATION}.make (""), "claude-opus-5-5", Void, 0), p.new_stream_decoder)
			j.start
			sleep_ms (500)
			t := now_ms
			j.cancel
			j.wait
			t := now_ms - t
			srv.stop
			assert ("cancelled", j.is_cancelled)
			assert ("not success", not j.is_success)
			assert ("soon: " + t.out + "ms", t < 2500)
			assert ("beginning received", j.body.starts_with ("event: message_start"))
		end

	test_error_status
			-- An error answer: the status and the body are available.
		local
			srv: AI_TEST_SERVER
			p: AI_PROVIDER
			j: AI_REQUEST_JOB
		do
			srv := started_server (401, 0, <<"{%"type%":%"error%",%"error%":{%"type%":%"authentication_error%",%"message%":%"invalid x-api-key%"}}">>, <<0>>)
			p := provider (srv.url)
			create j.make (p.chat_request (create {AI_CONVERSATION}.make (""), "claude-opus-5-5", Void, 0), p.new_stream_decoder)
			j.start
			j.wait
			srv.stop
			assert ("finished", j.is_finished)
			assert ("not success", not j.is_success)
			assert ("status", j.status = 401)
			assert ("message", p.error_message (j.status, j.body).same_string_general ("API key refused (401): invalid x-api-key"))
		end

	test_models_request
			-- A request not streamed: the body is kept.
		local
			srv: AI_TEST_SERVER
			p: AI_PROVIDER
			j: AI_REQUEST_JOB
		do
			srv := started_server (200, 0, <<anthropic_models>>, <<0>>)
			p := provider (srv.url)
			create j.make (p.models_request, Void)
			j.start
			j.wait
			srv.stop
			assert ("success", j.is_success)
			assert ("models", p.models (j.body).count = 2)
			assert ("get", srv.request_text.starts_with ("GET /v1/models"))
		end

feature {NONE} -- Implementation

	started_server (a_status, a_first_delay_ms: INTEGER; a_parts: ARRAY [READABLE_STRING_8]; a_delays_ms: ARRAY [INTEGER]): AI_TEST_SERVER
			-- Server started, answering as described
		do
			create Result.make (a_status, a_first_delay_ms, a_parts, a_delays_ms)
			Result.start
			assert ("listening", Result.port > 0)
		end

	provider (a_url: READABLE_STRING_8): AI_PROVIDER
			-- Anthropic provider at `a_url', with key "sk-test"
		local
			s: AI_PROVIDER_SETTINGS
		do
			create s.make ("test", {AI_PROVIDER_SETTINGS}.Kind_anthropic, a_url, Void)
			s.set_key ("sk-test")
			create {AI_ANTHROPIC_PROVIDER} Result.make (s)
		end

	parts (s: READABLE_STRING_8; n: INTEGER): ARRAY [READABLE_STRING_8]
			-- `s' in `n' parts
		local
			i, l_size: INTEGER
		do
			create Result.make_filled ("", 1, n)
			l_size := s.count // n + 1
			from
				i := 1
			until
				i > n
			loop
				Result [i] := s.substring ((i - 1) * l_size + 1, (i * l_size).min (s.count))
				i := i + 1
			end
		end

	sleep_ms (n: INTEGER)
			-- Wait `n' milliseconds.
		do
			(create {EXECUTION_ENVIRONMENT}).sleep (n.to_integer_64 * 1_000_000)
		end

	now_ms: INTEGER_64
			-- Current time in milliseconds
		local
			d: DATE_TIME
		do
			create d.make_now_utc
			Result := d.date.days.to_integer_64 * 86_400_000 + d.time.seconds.to_integer_64 * 1000 + d.time.milli_second
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
