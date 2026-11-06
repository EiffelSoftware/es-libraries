note
	description: "Conversation with an AI model: instructions (system prompt) and messages, alternating between the user and the model."
	date: "$Date$"
	revision: "$Revision$"

class
	AI_CONVERSATION

create
	make

feature {NONE} -- Initialization

	make (a_system_prompt: READABLE_STRING_GENERAL)
			-- Empty conversation with instructions `a_system_prompt' (possibly empty).
		do
			system_prompt := a_system_prompt.to_string_32
			create messages.make (10)
		end

feature -- Access

	system_prompt: STRING_32
			-- Instructions for the model

	messages: ARRAYED_LIST [AI_MESSAGE]
			-- Messages, in order

feature -- Element change

	set_system_prompt (s: READABLE_STRING_GENERAL)
			-- Set `system_prompt' to `s'.
		do
			system_prompt := s.to_string_32
		end

	extend (m: AI_MESSAGE)
			-- Add `m' at the end.
		do
			messages.extend (m)
		ensure
			added: messages.last = m
		end

	extend_user_text (a_text: READABLE_STRING_GENERAL)
			-- Add a message of the user with text `a_text'.
		local
			m: AI_MESSAGE
		do
			create m.make_user
			m.extend_text (a_text)
			extend (m)
		end

	wipe_out
			-- Remove all the messages.
		do
			messages.wipe_out
		ensure
			empty: messages.is_empty
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
