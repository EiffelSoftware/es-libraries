note
	description: "Streaming and cancellation tests with the net implementation."
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_NET_STREAMING

inherit
	TEST_HTTP_STREAMING_I

feature -- Factory

	new_session (a_url: READABLE_STRING_8): HTTP_CLIENT_SESSION
		do
			create {NET_HTTP_CLIENT_SESSION} Result.make (a_url)
		end

feature -- Tests

	test_net_streamed_content
		do
			test_streamed_content
		end

	test_net_cancel_during_content
		do
			test_cancel_during_content
		end

	test_net_cancel_before_response
		do
			test_cancel_before_response
		end

note
	copyright: "2011-2026, Jocelyn Fiat, Javier Velilla, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
end
