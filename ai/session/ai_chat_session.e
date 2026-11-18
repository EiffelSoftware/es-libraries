note
	description: "[
		Conversation with a model: each question is sent with the conversation so far, and the
		answer is received in a thread while the user interface polls it (`poll'), shows the text
		received (`answer_text'), and can stop it (`stop'). The provider and the model can change
		between two questions.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	AI_CHAT_SESSION

create
	make

feature {NONE} -- Initialization

	make (a_provider: AI_PROVIDER; a_model: READABLE_STRING_GENERAL; a_system_prompt: READABLE_STRING_GENERAL)
			-- Session with model `a_model' of `a_provider', instructed by `a_system_prompt'.
		require
			a_model_not_empty: not a_model.is_empty
		do
			provider := a_provider
			create model.make_from_string_general (a_model)
			create conversation.make (a_system_prompt)
			create answer_text.make_empty
			create stop_reason.make_empty
			create builder.make (a_provider.settings.kind)
			create pending_tool_calls.make (0)
			max_rounds := Default_max_rounds
		ensure
			provider_set: provider = a_provider
			idle: not is_answering
		end

feature -- Access

	provider: AI_PROVIDER
			-- Provider of the model

	model: STRING_32
			-- Model answering

	model_name: STRING_32
			-- "provider/model"
		do
			Result := provider.name + {STRING_32} "/" + model
		end

	conversation: AI_CONVERSATION
			-- Questions and answers so far

	answer_text: STRING_32
			-- Text of the answer being received (or of the last answer)

	answer_version: INTEGER
			-- Number incremented each time `answer_text' changes

	last_error: detachable STRING_32
			-- Error of the last answer, if any

	input_tokens, output_tokens: INTEGER
			-- Tokens of the last answer

	total_input_tokens, total_output_tokens: INTEGER
			-- Tokens of all the answers of the session

	transcript: detachable AI_TRANSCRIPT
			-- Transcript kept, if any

	tools: detachable ITERABLE [AI_TOOL_DEFINITION]
			-- Tools the model may call, if any

	stop_reason: STRING_32
			-- Why the last answer ended, as the provider tells it (see {AI_STREAM_DECODER}.Stop_*; empty if unknown)

	last_job: detachable AI_REQUEST_JOB
			-- Request of the answer being received, or of the last answer (its URL, body, progress...)

	pending_tool_calls: ARRAYED_LIST [AI_CONTENT]
			-- Tool calls of the last answer, waiting for their results (see `answer_tool_calls')

	rounds: INTEGER
			-- Number of answers to the results of tool calls since the last question

	max_rounds: INTEGER
			-- Maximum of `rounds' for a question

	Default_max_rounds: INTEGER = 25
			-- Default of `max_rounds'

feature -- Status report

	is_answering: BOOLEAN
			-- Is an answer being received?
		do
			Result := job /= Void
		end

	was_stopped: BOOLEAN
			-- Was the last answer stopped by `stop'?

	is_truncated: BOOLEAN
			-- Did the last answer end because of its maximum length?

	has_pending_tool_calls: BOOLEAN
			-- Is the model waiting for the results of tool calls? (Not if the answer was stopped or failed.)
		do
			Result := not pending_tool_calls.is_empty and not was_stopped and last_error = Void
		end

feature -- Element change

	set_model (a_provider: AI_PROVIDER; a_model: READABLE_STRING_GENERAL)
			-- Use model `a_model' of `a_provider' for the next questions.
		require
			idle: not is_answering
			a_model_not_empty: not a_model.is_empty
		do
			provider := a_provider
			create model.make_from_string_general (a_model)
		ensure
			provider_set: provider = a_provider
		end

	set_tools (a_tools: like tools)
			-- Let the model call `a_tools' (none if Void).
		do
			tools := a_tools
		ensure
			tools_set: tools = a_tools
		end

	set_max_rounds (n: INTEGER)
			-- Set `max_rounds' to `n'.
		require
			positive: n > 0
		do
			max_rounds := n
		ensure
			set: max_rounds = n
		end

	set_transcript (t: detachable AI_TRANSCRIPT)
			-- Keep the transcript in `t' (none if Void).
		do
			transcript := t
		ensure
			transcript_set: transcript = t
		end

	wipe_out
			-- Start a new conversation.
		require
			idle: not is_answering
		do
			conversation.wipe_out
			pending_tool_calls.wipe_out
			answer_text.wipe_out
			answer_version := answer_version + 1
			last_error := Void
			total_input_tokens := 0
			total_output_tokens := 0
		ensure
			no_messages: conversation.messages.is_empty
		end

	set_conversation (a_conversation: AI_CONVERSATION; a_input_tokens, a_output_tokens: INTEGER)
			-- Go on with `a_conversation' (read again), whose questions used `a_input_tokens' and `a_output_tokens'.
		require
			idle: not is_answering
			tokens_non_negative: a_input_tokens >= 0 and a_output_tokens >= 0
		do
			conversation := a_conversation
			pending_tool_calls.wipe_out
			answer_text.wipe_out
			answer_version := answer_version + 1
			last_error := Void
			total_input_tokens := a_input_tokens
			total_output_tokens := a_output_tokens
		ensure
			conversation_set: conversation = a_conversation
		end

	compact_with (a_summary: READABLE_STRING_GENERAL)
			-- Replace the messages of the conversation by `a_summary' of them (and the agreement of the model
			-- to go on from it), so that the next questions send less.
		require
			idle: not is_answering
			a_summary_not_empty: not a_summary.is_empty
		local
			m: AI_MESSAGE
		do
			conversation.wipe_out
			pending_tool_calls.wipe_out
			conversation.extend_user_text ({STRING_32} "Summary of our conversation so far (the earlier messages are replaced by it):%N%N" + a_summary.to_string_32)
			create m.make_assistant
			m.extend_text ("Understood: I go on from this summary.")
			conversation.extend (m)
		ensure
			two_messages: conversation.messages.count = 2
			no_pending: pending_tool_calls.is_empty
		end

feature -- Basic operations

	ask (a_question: READABLE_STRING_GENERAL)
			-- Send `a_question', with the conversation so far.
		require
			idle: not is_answering
			a_question_not_empty: not a_question.is_empty
		local
			m: AI_MESSAGE
		do
			create m.make_user
			⟳ c: pending_tool_calls ¦
					-- (Calls left without results when the user stopped.)
				m.extend_tool_result (c.tool_call_id, "Not run: stopped by the user.", True)
			⟲
			pending_tool_calls.wipe_out
			m.extend_text (a_question)
			conversation.extend (m)
			if attached transcript as t then
				t.put_question (a_question)
			end
			rounds := 0
			start_request
		ensure
			answering: is_answering
		end

	answer_tool_calls (a_results: ITERABLE [TUPLE [id: READABLE_STRING_GENERAL; text: READABLE_STRING_GENERAL; is_error: BOOLEAN]])
			-- Send `a_results' of `pending_tool_calls' to the model, which goes on answering (unless
			-- `max_rounds' is reached: `last_error' then tells it).
		require
			idle: not is_answering
			pending: has_pending_tool_calls
		local
			m: AI_MESSAGE
		do
			create m.make_user
			⟳ r: a_results ¦
				m.extend_tool_result (r.id, r.text, r.is_error)
			⟲
			pending_tool_calls.wipe_out
			conversation.extend (m)
			rounds := rounds + 1
			if rounds > max_rounds then
				m.contents.wipe_out
				⟳ r: a_results ¦
					m.extend_tool_result (r.id, "Not run: too many tool calls.", True)
				⟲
				last_error := {STRING_32} "Stopped after " + max_rounds.out + {STRING_32} " answers to tool calls."
			else
				start_request
			end
		ensure
			no_pending: pending_tool_calls.is_empty
		end

	poll: BOOLEAN
			-- Take the part of the answer received into account. Did something change?
		local
			l_text: STRING_32
		do
			if attached job as j then
				if j.is_finished then
					builder.apply_all (j.take_events)
					builder.finish
					end_answer (j)
					Result := True
				else
					builder.apply_all (j.take_events)
				end
				l_text := builder.message.text
				if not l_text.same_string (answer_text) then
					answer_text := l_text
					answer_version := answer_version + 1
					Result := True
				end
			end
		end

	stop
			-- Stop the answer being received (or the tool calls waiting for their results).
		do
			if attached job as j then
				j.cancel
			elseif has_pending_tool_calls then
				was_stopped := True
			end
		end

	wait
			-- Wait for the end of the answer being received.
		do
			if attached job as j then
				j.wait
				if poll then
						-- (The answer is complete.)
				end
			end
		ensure
			idle: not is_answering
		end

feature {NONE} -- Implementation

	start_request
			-- Send the conversation, and receive the answer.
		local
			j: AI_REQUEST_JOB
		do
			answer_text.wipe_out
			answer_version := answer_version + 1
			last_error := Void
			was_stopped := False
			is_truncated := False
			input_tokens := 0
			output_tokens := 0
			create builder.make (provider.settings.kind)
			create j.make (provider.chat_request (conversation, model, tools, 0), provider.new_stream_decoder)
			job := j
			last_job := j
			j.start
		ensure
			answering: is_answering
			last_job_set: last_job /= Void
		end

	job: detachable AI_REQUEST_JOB
			-- Request of the answer being received

	builder: AI_RESPONSE_BUILDER
			-- Builder of the answer being received

	end_answer (j: AI_REQUEST_JOB)
			-- The answer of `j' ended: keep it in the conversation.
		local
			m: AI_MESSAGE
		do
			job := Void
			m := builder.message
			answer_text := m.text
			answer_version := answer_version + 1
			input_tokens := builder.input_tokens
			output_tokens := builder.output_tokens
			total_input_tokens := total_input_tokens + input_tokens
			total_output_tokens := total_output_tokens + output_tokens
			was_stopped := j.is_cancelled
			stop_reason := builder.stop_reason.twin
			is_truncated := stop_reason.same_string ({AI_STREAM_DECODER}.Stop_max_tokens)
			if was_stopped then
					-- (Kept as far as received.)
			elseif not j.is_success then
				if attached j.error_message as e then
					last_error := e
				else
					last_error := provider.error_message (j.status, j.body)
				end
			elseif attached builder.error_message as e then
				last_error := e
			end
			if not m.contents.is_empty and then (not m.text.is_empty or m.has_tool_calls) then
				conversation.extend (m)
				if m.has_tool_calls then
						-- (Waiting for their results, or answered "not run" with the next question if stopped.)
					pending_tool_calls.append (m.tool_calls)
				end
			elseif rounds = 0 and then not conversation.messages.is_empty and then not conversation.messages.last.is_assistant then
					-- No answer: the question is forgotten (it can be asked again).
				conversation.messages.finish
				conversation.messages.remove
			end
			if attached transcript as t then
				t.put_answer (model_name, m.text, last_error, was_stopped)
			end
		ensure
			idle: not is_answering
		end

invariant
	tokens_non_negative: total_input_tokens >= 0 and total_output_tokens >= 0

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
