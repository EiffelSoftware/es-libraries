note
	description: "[
		Bracketed paste event delivering pasted text payload.
		A paste longer than the parser's `max_paste_size` arrives as several events in a row:
		every event but the last has `is_continued` set, and joining their texts gives the paste.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	PASTE_EVENT

inherit
	EVENT
		redefine
			is_paste
		end

create
	make

create {ANSI_INPUT_PARSER}
	make_owned

feature {NONE} -- Initialization

	make (a_text: READABLE_STRING_GENERAL)
			-- Initialize paste event with `a_text`.
		require
			text_attached: a_text /= Void
		do
			text := a_text.as_string_32.twin
		ensure
			text_set: text.is_equal (a_text.as_string_32)
			not_continued: not is_continued
		end

	make_owned (a_text: STRING_32; a_continued: BOOLEAN)
			-- Initialize paste event holding `a_text` itself (not a copy), with `is_continued`
			-- set to `a_continued`. The caller gives up `a_text` and must not change it later.
		require
			text_attached: a_text /= Void
		do
			text := a_text
			is_continued := a_continued
		ensure
			text_set: text = a_text
			continued_set: is_continued = a_continued
		end

feature -- Access

	text: STRING_32
			-- Pasted text payload

feature -- Status report

	is_paste: BOOLEAN = True

	is_continued: BOOLEAN
			-- Does more text of the same paste follow in the next paste event?

invariant
	text_attached: text /= Void

end
