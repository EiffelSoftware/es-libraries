note
	description: "[
		Provider of AI models: how to list its models, how to send a conversation to one of them
		(a streamed answer), and how to read its errors. Its settings give its URL and API key.
	]"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	AI_PROVIDER

inherit
	AI_JSON_HELPER

feature {NONE} -- Initialization

	make (a_settings: AI_PROVIDER_SETTINGS)
			-- Provider of settings `a_settings'.
		do
			settings := a_settings
		ensure
			settings_set: settings = a_settings
		end

feature -- Access

	settings: AI_PROVIDER_SETTINGS
			-- Settings of the provider

	name: STRING_32
			-- Name of the provider
		do
			Result := settings.name
		end

	base_url: STRING_8
			-- URL of the provider, without a final "/" (nor "/v1")
		do
			Result := settings.url.twin
			if Result.ends_with ("/") then
				Result.remove_tail (1)
			end
			if Result.ends_with ("/v1") then
				Result.remove_tail (3)
			end
		end

feature -- Requests

	models_request: AI_HTTP_REQUEST
			-- Request listing the models
		deferred
		ensure
			not_streamed: not Result.is_streamed
		end

	chat_request (a_conversation: AI_CONVERSATION; a_model: READABLE_STRING_GENERAL; a_tools: detachable ITERABLE [AI_TOOL_DEFINITION]; a_max_tokens: INTEGER): AI_HTTP_REQUEST
			-- Request sending `a_conversation' to model `a_model', with tools `a_tools' (if any),
			-- for an answer of at most `a_max_tokens' tokens (0: the default of the provider), streamed.
		require
			a_model_not_empty: not a_model.is_empty
			a_max_tokens_non_negative: a_max_tokens >= 0
		deferred
		ensure
			streamed: Result.is_streamed
		end

feature -- Answers

	models (a_body: READABLE_STRING_8): ARRAYED_LIST [AI_MODEL]
			-- Models listed by `a_body', the answer of `models_request'
		deferred
		end

	new_stream_decoder: AI_STREAM_DECODER
			-- Decoder of the streamed answers of the provider
		deferred
		end

	error_message (a_status: INTEGER; a_body: READABLE_STRING_8): STRING_32
			-- Error described by the answer `a_body' of status `a_status'
		local
			o: detachable JSON_OBJECT
		do
			o := parsed_json_object (a_body)
			if attached string_item (object_item (o, "error"), "message") as m then
				Result := m
			elseif attached string_item (o, "error") as m then
				Result := m
			elseif attached string_item (o, "message") as m then
				Result := m
			else
				Result := {UTF_CONVERTER}.utf_8_string_8_to_string_32 (a_body.head (300))
			end
			if a_status = 401 or a_status = 403 then
				Result := {STRING_32} "API key refused (" + a_status.out + {STRING_32} "): " + Result
			elseif a_status > 0 then
				Result := {STRING_32} "Error " + a_status.out + {STRING_32} ": " + Result
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
