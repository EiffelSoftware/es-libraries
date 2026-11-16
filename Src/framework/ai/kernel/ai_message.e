note
	description: "Message of a conversation with an AI model: from the user (texts, results of tool calls) or from the model (texts, tool calls)."
	date: "$Date$"
	revision: "$Revision$"

class
	AI_MESSAGE

create
	make_user,
	make_assistant

feature {NONE} -- Initialization

	make_user
			-- Empty message of the user.
		do
			is_assistant := False
			create contents.make (2)
		end

	make_assistant
			-- Empty message of the model.
		do
			is_assistant := True
			create contents.make (2)
		end

feature -- Access

	contents: ARRAYED_LIST [AI_CONTENT]
			-- Parts of the message, in order

	text: STRING_32
			-- Texts of the message, one after the other
		do
			create Result.make (80)
			⟳ c: contents ¦
				if c.is_text then
					Result.append (c.text)
				end
			⟲
		end

	tool_calls: ARRAYED_LIST [AI_CONTENT]
			-- Tool calls of the message
		do
			create Result.make (1)
			⟳ c: contents ¦
				if c.is_tool_call then
					Result.extend (c)
				end
			⟲
		end

	role: STRING_8
			-- "assistant" or "user"
		do
			if is_assistant then
				Result := "assistant"
			else
				Result := "user"
			end
		end

feature -- Status report

	is_assistant: BOOLEAN
			-- Is it a message of the model?

	has_tool_calls: BOOLEAN
			-- Does the message call tools?
		do
			Result := ∃ c: contents ¦ c.is_tool_call
		end

feature -- Element change

	extend (c: AI_CONTENT)
			-- Add `c' at the end.
		do
			contents.extend (c)
		ensure
			added: contents.last = c
		end

	extend_text (a_text: READABLE_STRING_GENERAL)
			-- Add text `a_text'.
		do
			extend (create {AI_CONTENT}.make_text (a_text))
		end

	extend_tool_result (a_id, a_text: READABLE_STRING_GENERAL; a_is_error: BOOLEAN)
			-- Add the result `a_text' of the tool call `a_id'.
		do
			extend (create {AI_CONTENT}.make_tool_result (a_id, a_text, a_is_error))
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
