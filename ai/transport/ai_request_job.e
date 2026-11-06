note
	description: "[
		Request to a provider performed in a thread of its own, so that the caller (e.g. a user
		interface) goes on. A streamed answer is decoded as it arrives: the caller takes the events
		with `take_events', regularly; it can stop the request with `cancel'.
		Every access to the state shared with the thread goes through `mutex'.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	AI_REQUEST_JOB

create
	make

feature {NONE} -- Initialization

	make (a_request: AI_HTTP_REQUEST; a_decoder: detachable AI_STREAM_DECODER)
			-- Job performing `a_request'; a streamed answer is decoded by `a_decoder'.
		require
			decoder_for_streamed: a_request.is_streamed implies a_decoder /= Void
		do
			request := a_request
			decoder := a_decoder
			create mutex.make
			create body.make_empty
			create pending_events.make (8)
		end

feature -- Access

	request: AI_HTTP_REQUEST
			-- Request performed

	status: INTEGER
			-- HTTP status of the answer (once finished)
		do
			mutex.lock
			Result := internal_status
			mutex.unlock
		end

	body: STRING_8
			-- Body of a not streamed answer, or the beginning of a streamed answer (for errors)
			-- (once finished)

	error_message: detachable STRING_32
			-- Error of the transfer, if any (once finished)

	take_events: ARRAYED_LIST [AI_STREAM_EVENT]
			-- Events of the streamed answer received since the last call
		do
			mutex.lock
			Result := pending_events
			create pending_events.make (8)
			mutex.unlock
		end

feature -- Status report

	is_started: BOOLEAN
			-- Was the job started?

	is_finished: BOOLEAN
			-- Is the request completed (or stopped, or failed)?
		do
			mutex.lock
			Result := internal_is_finished
			mutex.unlock
		end

	is_cancelled: BOOLEAN
			-- Was the request stopped by `cancel'? (Once finished.)
		do
			mutex.lock
			Result := internal_is_cancelled
			mutex.unlock
		end

	is_success: BOOLEAN
			-- Did the request succeed (status 2xx, no error)? (Once finished.)
		do
			mutex.lock
			Result := internal_is_finished and not internal_is_cancelled and error_message = Void and internal_status >= 200 and internal_status < 300
			mutex.unlock
		end

feature -- Basic operations

	start
			-- Perform the request in a new thread.
		require
			not_started: not is_started
		local
			l_thread: WORKER_THREAD
		do
			is_started := True
			create l_thread.make (agent execute)
			thread := l_thread
			l_thread.launch
		ensure
			started: is_started
		end

	cancel
			-- Ask to stop the request.
		do
			mutex.lock
			is_cancel_requested := True
			mutex.unlock
		end

	wait
			-- Wait for the end of the request.
		require
			started: is_started
		do
			if attached thread as t then
				t.join
			end
		ensure
			finished: is_finished
		end

	execute
			-- Perform the request (in the thread of the job).
		local
			cl: DEFAULT_HTTP_CLIENT
			sess: HTTP_CLIENT_SESSION
			ctx: HTTP_CLIENT_REQUEST_CONTEXT
			res: HTTP_CLIENT_RESPONSE
			retried, l_locked: BOOLEAN
		do
			if not retried then
				create cl
				sess := cl.new_session (request.base_url)
					-- (No limit for a streamed answer, which can be long: `cancel' stops it.)
				sess.set_timeout (0)
				sess.set_connect_timeout (30)
				create ctx.make
				⟳ h: request.headers ¦
					ctx.add_header (h.name, h.value)
				⟲
				ctx.set_cancellation_query (agent cancel_requested)
				if request.is_streamed then
					ctx.set_content_write_agent (agent receive)
				end
				if request.method.same_string ("POST") then
					res := sess.post (request.path, ctx, request.body)
				else
					res := sess.get (request.path, ctx)
				end
				mutex.lock
				l_locked := True
				internal_status := res.status
				internal_is_cancelled := res.is_cancelled
				if res.error_occurred and not res.is_cancelled then
					if attached res.error_message as m then
						error_message := {UTF_CONVERTER}.utf_8_string_8_to_string_32 (m)
					else
						error_message := {STRING_32} "Request failed"
					end
				end
				if not request.is_streamed and then attached res.body as b then
					body := b.to_string_8
				end
				if attached decoder as d then
					d.finish
					pending_events.append (d.take_events)
				end
				internal_is_finished := True
				l_locked := False
				mutex.unlock
			else
				if not l_locked then
					mutex.lock
				end
				if error_message = Void then
					error_message := {STRING_32} "Request failed (exception)"
				end
				internal_is_finished := True
				mutex.unlock
			end
		rescue
			retried := True
			retry
		end

feature {NONE} -- Implementation

	decoder: detachable AI_STREAM_DECODER
			-- Decoder of the streamed answer

	thread: detachable WORKER_THREAD
			-- Thread performing the request

	mutex: MUTEX
			-- Protection of the state shared with the thread

	pending_events: ARRAYED_LIST [AI_STREAM_EVENT]
			-- Events decoded, not yet taken

	internal_status: INTEGER
	internal_is_finished: BOOLEAN
	internal_is_cancelled: BOOLEAN
	is_cancel_requested: BOOLEAN
			-- Shared state (see `mutex')

	Max_body_kept: INTEGER = 65536
			-- Length kept of the beginning of a streamed answer

	cancel_requested: BOOLEAN
			-- Is the request to be stopped? (Asked by the HTTP client, in the thread of the job.)
		do
			mutex.lock
			Result := is_cancel_requested
			mutex.unlock
		end

	receive (s: READABLE_STRING_8)
			-- Receive part `s' of the streamed answer (in the thread of the job).
		do
			mutex.lock
			if body.count < Max_body_kept then
				body.append (s.head (Max_body_kept - body.count))
			end
			if attached decoder as d then
				d.feed (s)
				pending_events.append (d.take_events)
			end
			mutex.unlock
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
