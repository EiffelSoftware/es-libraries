note
	description: "[
		Text input edge cases (review finding U8):
		- control characters: TAB and line breaks become a space, others are removed, on every
		  way in (typed, pasted, set)
		- the cursor stays on a grapheme cluster boundary when an insertion or a deletion
		  regroups the clusters around it (flags, combining marks, ZWJ sequences)
		- the widget cursor on a zero-width cluster does not blank the next character
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_TEXT_INPUT_EDGES

inherit
	EQA_TEST_SET

feature -- Control characters

	test_single_line_text
			-- TAB and each line break become one space; other controls are removed.
		do
			assert ("tab and line breaks", {TEXT_INPUT_STATE}.single_line_text ("a%Tb%Nc%R%Nd%Re").same_string ("a b c d e"))
			assert ("escape removed", {TEXT_INPUT_STATE}.single_line_text ("x%/27/[31my").same_string ("x[31my"))
			assert ("DEL and C1 removed", {TEXT_INPUT_STATE}.single_line_text ({STRING_32} "p%/127/q%/0x9B/r").same_string ("pqr"))
			assert ("other text kept", {TEXT_INPUT_STATE}.single_line_text ({STRING_32} "caf%/0x301/ %/0x1F600/").same_string ({STRING_32} "caf%/0x301/ %/0x1F600/"))
		end

	test_paste_is_single_line
			-- A pasted multi-line text with tabs and an escape sequence becomes one clean line.
		local
			l_state: TEXT_INPUT_STATE
		do
			create l_state.make_with_text ("<>")
			l_state.set_cursor_position (1)
			l_state.insert_string ("one%Ttwo%R%Nthree%/27/[0m")
			assert ("clean line", l_state.value.same_string ("<one two three[0m>"))
			assert ("cursor after the paste", l_state.cursor_position = 17)
		end

	test_typed_controls
			-- A typed TAB inserts a space; a typed ESC is ignored.
		local
			l_state: TEXT_INPUT_STATE
		do
			create l_state.make_with_text ("ab")
			l_state.insert_character ('%T')
			assert ("tab as a space", l_state.value.same_string ("ab ") and l_state.cursor_position = 3)
			l_state.insert_character ((27).to_character_32)
			assert ("escape ignored", l_state.value.same_string ("ab ") and l_state.cursor_position = 3)
		end

	test_set_value_is_single_line
			-- `make_with_text` and `set_value` apply the same rule.
		local
			l_state: TEXT_INPUT_STATE
		do
			create l_state.make_with_text ("a%Nb")
			assert ("make_with_text", l_state.value.same_string ("a b"))
			l_state.set_value ("x%Ty%/7/")
			assert ("set_value", l_state.value.same_string ("x y"))
		end

feature -- Cursor on a cluster boundary

	test_insert_regional_indicator_before_flag
			-- The review's case: typing a regional indicator before a flag regroups the
			-- indicators; the cursor moves after the new pair, not into it.
		local
			l_state: TEXT_INPUT_STATE
		do
			create l_state.make_with_text ({STRING_32} "%/0x1F1FA/%/0x1F1F8/")
			l_state.move_cursor_home
			l_state.insert_character ((0x1F1EF).to_character_32)
			assert ("text", l_state.value.same_string ({STRING_32} "%/0x1F1EF/%/0x1F1FA/%/0x1F1F8/"))
			assert ("after the new pair", l_state.cursor_position = 2)
			assert ("on a boundary", l_state.is_boundary (l_state.cursor_position))
		end

	test_insert_before_combining_mark
			-- A letter typed before a leading combining mark takes it; the cursor goes after both.
		local
			l_state: TEXT_INPUT_STATE
		do
			create l_state.make_with_text ({STRING_32} "%/0x301/x")
			l_state.move_cursor_home
			l_state.insert_character ('a')
			assert ("text", l_state.value.same_string ({STRING_32} "a%/0x301/x"))
			assert ("after the accented letter", l_state.cursor_position = 2)
		end

	test_insert_zwj_between_emoji
			-- A ZWJ typed between two emoji joins them into one cluster; the cursor goes after it.
		local
			l_state: TEXT_INPUT_STATE
		do
			create l_state.make_with_text ({STRING_32} "%/0x1F468/%/0x1F469/")
			l_state.set_cursor_position (1)
			l_state.insert_character ((0x200D).to_character_32)
			assert ("one cluster", {UNICODE_WIDTH}.grapheme_end (l_state.value, 1) = 3)
			assert ("after the sequence", l_state.cursor_position = 3)
		end

	test_backspace_regroups_flags
			-- Deleting a character between regional indicators regroups them; the cursor stays
			-- before the new pair instead of inside it.
		local
			l_state: TEXT_INPUT_STATE
		do
			create l_state.make_with_text ({STRING_32} "%/0x1F1E6/x%/0x1F1E7/%/0x1F1E8/")
			l_state.set_cursor_position (2)
			l_state.delete_backward
			assert ("text", l_state.value.same_string ({STRING_32} "%/0x1F1E6/%/0x1F1E7/%/0x1F1E8/"))
			assert ("before the new pair", l_state.cursor_position = 0)
		end

	test_delete_regroups_flags
			-- The same with Delete: the cursor moves back to the start of the new pair.
		local
			l_state: TEXT_INPUT_STATE
		do
			create l_state.make_with_text ({STRING_32} "%/0x1F1E6/x%/0x1F1E7/%/0x1F1E8/")
			l_state.set_cursor_position (1)
			l_state.delete_forward
			assert ("text", l_state.value.same_string ({STRING_32} "%/0x1F1E6/%/0x1F1E7/%/0x1F1E8/"))
			assert ("before the new pair", l_state.cursor_position = 0)
		end

	test_typing_keeps_cursor_on_boundaries
			-- Typing a ZWJ family one code point at a time keeps the cursor on a boundary at every step.
		local
			l_state: TEXT_INPUT_STATE
		do
			create l_state
			across <<0x1F468, 0x200D, 0x1F469, 0x200D, 0x1F467, 0x1F3FD, 0x301>> as c loop
				l_state.insert_character (c.to_character_32)
				assert ("at the end after each code point", l_state.cursor_position = l_state.value.count)
			end
		end

feature -- Widget

	test_cursor_on_zero_width_cluster_keeps_next_character
			-- The cursor on a lone leading combining mark highlights the next cell instead of
			-- writing a blank over its character.
		local
			l_input: TUI_TEXT_INPUT
			l_state: TEXT_INPUT_STATE
			l_buf: BUFFER
		do
			create l_input
			create l_state.make_with_text ({STRING_32} "%/0x301/ab")
			l_state.move_cursor_home
			create l_buf.make (6, 1)
			l_input.render_stateful (l_buf.area, l_buf, l_state)
			assert ("a kept", l_buf.cell (0, 0).symbol.same_string ("a"))
			assert ("a highlighted as the cursor", l_buf.cell (0, 0).style.is_reversed)
			assert ("b kept", l_buf.cell (0, 1).symbol.same_string ("b"))
		end

	test_cursor_at_end_is_blank_cell
			-- At the end of the text the cursor is still a blank highlighted cell.
		local
			l_input: TUI_TEXT_INPUT
			l_state: TEXT_INPUT_STATE
			l_buf: BUFFER
		do
			create l_input
			create l_state.make_with_text ("ab")
			create l_buf.make (6, 1)
			l_input.render_stateful (l_buf.area, l_buf, l_state)
			assert ("blank cursor cell", l_buf.cell (0, 2).symbol.same_string (" "))
			assert ("highlighted", l_buf.cell (0, 2).style.is_reversed)
			assert ("b kept", l_buf.cell (0, 1).symbol.same_string ("b"))
		end

end
