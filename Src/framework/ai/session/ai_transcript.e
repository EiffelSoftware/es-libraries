note
	description: "[
		Transcript of conversations with models, appended to a text file (Markdown): the questions,
		the answers and the model which gave them, with their time. No API key is ever written.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	AI_TRANSCRIPT

create
	make

feature {NONE} -- Initialization

	make (a_path: PATH)
			-- Transcript appended to file `a_path' (its directory is created when needed).
		do
			path := a_path
		ensure
			path_set: path = a_path
		end

feature -- Access

	path: PATH
			-- File of the transcript

	last_error: detachable STRING_32
			-- Error of the last writing, if any

feature -- Basic operations

	put_conversation_start (a_title: READABLE_STRING_GENERAL)
			-- Note the start of a conversation titled `a_title'.
		do
			append ({STRING_32} "%N# " + a_title.to_string_32 + {STRING_32} " (" + now + {STRING_32} ")%N")
		end

	put_question (a_question: READABLE_STRING_GENERAL)
			-- Note question `a_question'.
		do
			append ({STRING_32} "%N## You (" + now + {STRING_32} ")%N%N" + a_question.to_string_32 + {STRING_32} "%N")
		end

	put_answer (a_model: READABLE_STRING_GENERAL; a_text: READABLE_STRING_GENERAL; a_error: detachable READABLE_STRING_GENERAL; a_stopped: BOOLEAN)
			-- Note answer `a_text' of model `a_model' (with its error, or stopped).
		local
			s: STRING_32
		do
			s := {STRING_32} "%N## " + a_model.to_string_32 + {STRING_32} " (" + now + {STRING_32} ")%N%N" + a_text.to_string_32 + {STRING_32} "%N"
			if a_stopped then
				s.append ({STRING_32} "%N(stopped)%N")
			end
			if a_error /= Void then
				s.append ({STRING_32} "%N(error: " + a_error.to_string_32 + {STRING_32} ")%N")
			end
			append (s)
		end

feature {NONE} -- Implementation

	now: STRING_32
			-- Current date and time
		do
			create Result.make_from_string_general ((create {DATE_TIME}.make_now).formatted_out ("yyyy-[0]mm-[0]dd [0]hh:[0]mi:[0]ss"))
		end

	append (s: READABLE_STRING_32)
			-- Append `s' to the file (in UTF-8).
		local
			f: PLAIN_TEXT_FILE
			d: DIRECTORY
			retried: BOOLEAN
		do
			last_error := Void
			if not retried then
				if attached path.parent as l_parent then
					create d.make_with_path (l_parent)
					if not d.exists then
						d.recursive_create_dir
					end
				end
				create f.make_with_path (path)
				f.open_append
				f.put_string ({UTF_CONVERTER}.utf_32_string_to_utf_8_string_8 (s))
				f.close
			else
				last_error := {STRING_32} "Cannot write " + path.name
			end
		rescue
			retried := True
			if attached f as l_file and then not l_file.is_closed then
				l_file.close
			end
			retry
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
