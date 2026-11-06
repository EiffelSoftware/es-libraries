note
	description: "[
		Tests of a streamed response (the content given to an agent as it arrives) and of the
		cancellation of a transfer, with a local server (no network needed).
	]"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

deferred class
	TEST_HTTP_STREAMING_I

inherit
	EQA_TEST_SET

feature -- Factory

	new_session (a_url: READABLE_STRING_8): HTTP_CLIENT_SESSION
		deferred
		end

feature {NONE} -- Implementation

	now_ms: INTEGER_64
			-- Current time in milliseconds
		local
			t: DATE_TIME
		do
			create t.make_now_utc
			Result := t.date.days.to_integer_64 * 86_400_000 + (t.time.fine_seconds * 1000).truncated_to_integer_64
		end

feature -- Test routines

	test_streamed_content
			-- The parts of a chunked response reach the `content_write_agent' as they arrive.
		local
			srv: TEST_STREAMING_SERVER
			sess: like new_session
			ctx: HTTP_CLIENT_REQUEST_CONTEXT
			l_parts: ARRAYED_LIST [TUPLE [content: STRING_8; time: INTEGER_64]]
			l_all: STRING_8
		do
			create srv.make (0, <<"data: one%N%N", "data: two%N%N", "data: three%N%N">>, <<0, 400, 400>>)
			srv.start
			assert ("server started", srv.port > 0)
			sess := new_session (srv.url)
			sess.set_timeout (20)
			create l_parts.make (3)
			create ctx.make
			ctx.set_content_write_agent (agent (s: READABLE_STRING_8; a_parts: ARRAYED_LIST [TUPLE [content: STRING_8; time: INTEGER_64]])
				do
					a_parts.extend ([s.to_string_8, now_ms])
				end (?, l_parts))
			if attached sess.get ("/stream", ctx) as res then
				srv.stop
				assert ("no error", not res.error_occurred)
				assert ("not cancelled", not res.is_cancelled)
				assert ("status 200", res.status = 200)
				assert ("content type", attached res.header ("Content-Type") as ct and then ct.same_string ("text/event-stream"))
				assert ("no body (given to the agent)", not attached res.body as b or else b.is_empty)
				create l_all.make_empty
				from
					l_parts.start
				until
					l_parts.after
				loop
					l_all.append (l_parts.item.content)
					l_parts.forth
				end
				assert ("whole content", l_all.same_string ("data: one%N%Ndata: two%N%Ndata: three%N%N"))
				assert ("several parts", l_parts.count >= 2)
				assert ("parts received as they were sent", l_parts.last.time - l_parts.first.time >= 500)
			else
				srv.stop
				assert ("response", False)
			end
		end

	test_cancel_during_content
			-- A transfer stopped while the content arrives ends at once.
		local
			srv: TEST_STREAMING_SERVER
			sess: like new_session
			ctx: HTTP_CLIENT_REQUEST_CONTEXT
			l_parts: ARRAYED_LIST [STRING_8]
			l_start: INTEGER_64
		do
			create srv.make (0, <<"data: one%N%N", "data: two%N%N">>, <<0, 15000>>)
			srv.start
			assert ("server started", srv.port > 0)
			sess := new_session (srv.url)
			sess.set_timeout (30)
			create l_parts.make (2)
			create ctx.make
			ctx.set_content_write_agent (agent (s: READABLE_STRING_8; a_parts: ARRAYED_LIST [STRING_8])
				do
					a_parts.extend (s.to_string_8)
				end (?, l_parts))
				-- (Stop once the first part is received.)
			ctx.set_cancellation_query (agent (a_parts: ARRAYED_LIST [STRING_8]): BOOLEAN
				do
					Result := not a_parts.is_empty
				end (l_parts))
			l_start := now_ms
			if attached sess.get ("/stream", ctx) as res then
				assert ("stopped quickly", now_ms - l_start < 8000)
				srv.stop
				assert ("cancelled", res.is_cancelled)
				assert ("error", res.error_occurred)
				assert ("first part received", not l_parts.is_empty and then l_parts.first.starts_with ("data: one"))
				assert ("second part not received", not l_parts.last.has_substring ("two") and l_parts.count = 1)
			else
				srv.stop
				assert ("response", False)
			end
		end

	test_cancel_before_response
			-- A transfer stopped while waiting for the response ends at once.
		local
			srv: TEST_STREAMING_SERVER
			sess: like new_session
			ctx: HTTP_CLIENT_REQUEST_CONTEXT
			l_start: INTEGER_64
		do
			create srv.make (15000, <<"data: late%N%N">>, <<0>>)
			srv.start
			assert ("server started", srv.port > 0)
			sess := new_session (srv.url)
			sess.set_timeout (30)
			create ctx.make
			l_start := now_ms
				-- (Stop after one second.)
			ctx.set_cancellation_query (agent (a_start: INTEGER_64): BOOLEAN
				do
					Result := now_ms - a_start > 1000
				end (l_start))
			if attached sess.get ("/wait", ctx) as res then
				assert ("stopped quickly", now_ms - l_start < 8000)
				srv.stop
				assert ("cancelled", res.is_cancelled)
				assert ("error", res.error_occurred)
			else
				srv.stop
				assert ("response", False)
			end
		end

note
	copyright: "2011-2026, Jocelyn Fiat, Javier Velilla, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
end
