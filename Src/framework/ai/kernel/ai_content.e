note
	description: "[
		Part of a message of a conversation with an AI model: a text, a call of a tool by the model,
		the result of a tool call, or data of the provider that must be sent back as received
		(e.g. the thinking blocks of Claude models).
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	AI_CONTENT

create
	make_text,
	make_tool_call,
	make_tool_result,
	make_provider_data

feature {NONE} -- Initialization

	make_text (a_text: READABLE_STRING_GENERAL)
			-- Text `a_text'.
		do
			kind := Kind_text
			text := a_text.to_string_32
			create tool_call_id.make_empty
			create tool_name.make_empty
		ensure
			is_text: is_text
		end

	make_tool_call (a_id, a_name: READABLE_STRING_GENERAL; a_input: JSON_OBJECT)
			-- Call of tool `a_name' with input `a_input', identified by `a_id'.
		do
			kind := Kind_tool_call
			create text.make_empty
			tool_call_id := a_id.to_string_32
			tool_name := a_name.to_string_32
			tool_input := a_input
		ensure
			is_tool_call: is_tool_call
		end

	make_tool_result (a_id: READABLE_STRING_GENERAL; a_text: READABLE_STRING_GENERAL; a_is_error: BOOLEAN)
			-- Result `a_text' of the tool call identified by `a_id' (an error if `a_is_error').
		do
			kind := Kind_tool_result
			text := a_text.to_string_32
			tool_call_id := a_id.to_string_32
			create tool_name.make_empty
			is_error := a_is_error
		ensure
			is_tool_result: is_tool_result
		end

	make_provider_data (a_provider_kind: READABLE_STRING_GENERAL; a_data: JSON_OBJECT)
			-- Data `a_data' of providers of kind `a_provider_kind', to send back to them unchanged.
		do
			kind := Kind_provider_data
			text := a_provider_kind.to_string_32
			create tool_call_id.make_empty
			create tool_name.make_empty
			provider_data := a_data
		ensure
			is_provider_data: is_provider_data
		end

feature -- Access

	kind: INTEGER
			-- Kind of content (see `Kind_*')

	text: STRING_32
			-- Text; result of a tool call; kind of the provider of `provider_data'

	tool_call_id: STRING_32
			-- Identifier of the tool call (call or result)

	tool_name: STRING_32
			-- Name of the tool called

	tool_input: detachable JSON_OBJECT
			-- Input of the tool call

	provider_data: detachable JSON_OBJECT
			-- Data of the provider, sent back as received

feature -- Status report

	is_error: BOOLEAN
			-- Is the result of the tool call an error?

	is_text: BOOLEAN
			-- Is it a text?
		do
			Result := kind = Kind_text
		end

	is_tool_call: BOOLEAN
			-- Is it a call of a tool?
		do
			Result := kind = Kind_tool_call
		end

	is_tool_result: BOOLEAN
			-- Is it the result of a tool call?
		do
			Result := kind = Kind_tool_result
		end

	is_provider_data: BOOLEAN
			-- Is it data of the provider?
		do
			Result := kind = Kind_provider_data
		end

feature -- Element change

	append_text (s: READABLE_STRING_GENERAL)
			-- Append `s' to `text'.
		do
			text.append_string_general (s)
		end

feature -- Kinds

	Kind_text: INTEGER = 1
	Kind_tool_call: INTEGER = 2
	Kind_tool_result: INTEGER = 3
	Kind_provider_data: INTEGER = 4

invariant
	valid_kind: kind >= Kind_text and kind <= Kind_provider_data
	tool_call_has_input: is_tool_call implies tool_input /= Void
	provider_data_attached: is_provider_data implies provider_data /= Void

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
