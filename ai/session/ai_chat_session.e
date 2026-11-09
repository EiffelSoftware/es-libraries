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
			create builder.make (a_provider.settings.kind)
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
			answer_text.wipe_out
			answer_version := answer_version + 1
			last_error := Void
			total_input_tokens := 0
			total_output_tokens := 0
		ensure
			no_messages: conversation.messages.is_empty
		end

feature -- Basic operations

	ask (a_question: READABLE_STRING_GENERAL)
			-- Send `a_question', with the conversation so far.
		require
			idle: not is_answering
			a_question_not_empty: not a_question.is_empty
		local
			j: AI_REQUEST_JOB
		do
			conversation.extend_user_text (a_question)
			if attached transcript as t then
				t.put_question (a_question)
			end
			answer_text.wipe_out
			answer_version := answer_version + 1
			last_error := Void
			was_stopped := False
			is_truncated := False
			input_tokens := 0
			output_tokens := 0
			create builder.make (provider.settings.kind)
			create j.make (provider.chat_request (conversation, model, Void, 0), provider.new_stream_decoder)
			job := j
			j.start
		ensure
			answering: is_answering
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
			-- Stop the answer being received.
		do
			if attached job as j then
				j.cancel
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
			is_truncated := builder.stop_reason.same_string ({AI_STREAM_DECODER}.Stop_max_tokens)
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
			if not m.contents.is_empty and then not m.text.is_empty then
				conversation.extend (m)
			elseif not conversation.messages.is_empty and then not conversation.messages.last.is_assistant then
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
