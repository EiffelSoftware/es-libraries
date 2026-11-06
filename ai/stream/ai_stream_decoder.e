note
	description: "[
		Decoder of the streamed answer of a provider: the parts of the HTTP content received are
		turned into {AI_STREAM_EVENT}s, available in `events'.
	]"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	AI_STREAM_DECODER

inherit
	AI_JSON_HELPER

feature {NONE} -- Initialization

	make
			-- Decoder waiting for the stream.
		do
			create sse.make
			create events.make (8)
		end

feature -- Access

	events: ARRAYED_LIST [AI_STREAM_EVENT]
			-- Events decoded, not yet taken

	take_events: ARRAYED_LIST [AI_STREAM_EVENT]
			-- The events decoded so far (and forget them)
		do
			Result := events
			create events.make (8)
		ensure
			none_left: events.is_empty
		end

feature -- Basic operations

	feed (s: READABLE_STRING_8)
			-- Decode the next part `s' of the content.
		do
			sse.feed (s)
			process_sse_events
		end

	finish
			-- The content ended.
		do
			sse.finish
			process_sse_events
		end

feature -- Stop reasons

	Stop_end_turn: STRING = "end_turn"
	Stop_tool_use: STRING = "tool_use"
	Stop_max_tokens: STRING = "max_tokens"
	Stop_refusal: STRING = "refusal"
			-- Reasons of the end of an answer, the same for every provider

feature {NONE} -- Implementation

	sse: AI_SSE_PARSER
			-- Server-Sent Events of the content

	process_sse_events
			-- Decode the events of `sse'.
		do
			⟳ e: sse.events ¦
				process_event (e.name, e.data)
			⟲
			sse.wipe_out_events
		end

	process_event (a_name, a_data: STRING_8)
			-- Decode Server-Sent Event `a_name' with data `a_data'.
		deferred
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
