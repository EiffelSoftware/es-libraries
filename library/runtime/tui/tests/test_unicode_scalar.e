note
	description: "[
		Non-scalar values in drawn text (review finding U3): surrogates (U+D800..U+DFFF) and values
		above U+10FFFF are drawn as U+FFFD, in the columns the text was measured with, and every
		frame sent to the terminal is valid UTF-8 (RFC 3629: no CESU-8 surrogate sequences).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_UNICODE_SCALAR

inherit
	EQA_TEST_SET

feature -- UNICODE_SCALAR

	test_scalar_value_boundaries
			-- Scalar values stop at the surrogate range and at U+10FFFF.
		do
			assert ("U+0000", {UNICODE_SCALAR}.is_scalar_value (0))
			assert ("U+D7FF", {UNICODE_SCALAR}.is_scalar_value (0xD7FF))
			assert ("U+D800", not {UNICODE_SCALAR}.is_scalar_value (0xD800))
			assert ("U+DFFF", not {UNICODE_SCALAR}.is_scalar_value (0xDFFF))
			assert ("U+E000", {UNICODE_SCALAR}.is_scalar_value (0xE000))
			assert ("U+FFFD", {UNICODE_SCALAR}.is_scalar_value (0xFFFD))
			assert ("U+10FFFF", {UNICODE_SCALAR}.is_scalar_value (0x10FFFF))
			assert ("U+110000", not {UNICODE_SCALAR}.is_scalar_value (0x110000))
			assert ("max", not {UNICODE_SCALAR}.is_scalar_value ({NATURAL_32}.max_value))
			assert ("replaced", {UNICODE_SCALAR}.scalar_value (0xDC00) = 0xFFFD)
			assert ("kept", {UNICODE_SCALAR}.scalar_value (0x1F600) = 0x1F600)
		end

	test_scalar_string
			-- A valid string is returned as it is; otherwise every non-scalar value is replaced.
		local
			l_valid: STRING_32
			l_result: READABLE_STRING_GENERAL
		do
			l_valid := {STRING_32} "caf%/0x301/ %/0x1F600/"
			assert ("valid kept as the same object", {UNICODE_SCALAR}.scalar_string (l_valid) = l_valid)
			l_result := {UNICODE_SCALAR}.scalar_string (codes (<<0x61, 0xD83D, 0xDE00, 0x110000, 0x62>>))
			assert ("replaced one by one", l_result.same_string (codes (<<0x61, 0xFFFD, 0xFFFD, 0xFFFD, 0x62>>)))
		end

	test_replacement_is_measurement_neutral
			-- Replacing non-scalar values does not change any width: text measured before
			-- the replacement takes the same columns after it.
		local
			l_samples: ARRAYED_LIST [STRING_32]
			k: INTEGER
		do
			create l_samples.make (6)
			l_samples.extend (codes (<<0xD83D, 0xDE00, 0x78>>))
			l_samples.extend (codes (<<0xD800, 0x301, 0x41>>))
			l_samples.extend (codes (<<0x1F468, 0x200D, 0xD83D, 0xDC69>>))
			l_samples.extend (codes (<<0x1F1FA, 0xDFFF, 0x1F1F8>>))
			l_samples.extend (codes (<<0x110000, 0xFE0F, 0x7C>>))
			l_samples.extend (codes (<<0x2764, 0xDBFF, 0xFE0F>>))
			across l_samples as s loop
				k := k + 1
				assert ("same width " + k.out,
					{UNICODE_WIDTH}.string_width (s) = {UNICODE_WIDTH}.string_width ({UNICODE_SCALAR}.scalar_string (s)))
			end
		end

feature -- BUFFER and TERMINAL_CELL

	test_buffer_draws_surrogates_as_replacement
			-- The probe case: `D83D DE00 'x'` is measured as 3 columns and drawn as
			-- U+FFFD U+FFFD 'x' in those 3 columns.
		local
			l_buffer: BUFFER
			l_text: STRING_32
		do
			l_text := codes (<<0xD83D, 0xDE00, 0x78>>)
			create l_buffer.make (10, 1)
			l_buffer.put_string (0, 0, l_text, create {STYLE})
			assert ("measured 3", {UNICODE_WIDTH}.string_width (l_text) = 3)
			assert ("high surrogate replaced", l_buffer.cell (0, 0).symbol.same_string (codes (<<0xFFFD>>)))
			assert ("low surrogate replaced", l_buffer.cell (0, 1).symbol.same_string (codes (<<0xFFFD>>)))
			assert ("x in the third column", l_buffer.cell (0, 2).symbol.same_string ("x"))
			assert ("nothing after", l_buffer.cell (0, 3).symbol.same_string (" "))
		end

	test_buffer_replaces_values_above_u10ffff
			-- A value above U+10FFFF (a CHARACTER_32 can hold one) is drawn as U+FFFD.
		local
			l_buffer: BUFFER
		do
			create l_buffer.make (10, 1)
			l_buffer.put_string (0, 0, codes (<<0x110000, 0x41>>), create {STYLE})
			assert ("replaced", l_buffer.cell (0, 0).symbol.same_string (codes (<<0xFFFD>>)))
			assert ("A next", l_buffer.cell (0, 1).symbol.same_string ("A"))
		end

	test_put_char_replaces_surrogate
			-- `put_char` with a lone surrogate draws U+FFFD.
		local
			l_buffer: BUFFER
		do
			create l_buffer.make (4, 1)
			l_buffer.put_char (0, 1, (0xDC00).to_character_32, create {STYLE})
			assert ("replaced", l_buffer.cell (0, 1).symbol.same_string (codes (<<0xFFFD>>)))
			assert ("width 1", l_buffer.cell (0, 1).width = 1)
		end

	test_surrogate_keeps_its_combining_mark
			-- A combining mark after a lone surrogate stays with the replacement, in one cell.
		local
			l_buffer: BUFFER
		do
			create l_buffer.make (4, 1)
			l_buffer.put_string (0, 0, codes (<<0xD800, 0x301, 0x41>>), create {STYLE})
			assert ("mark kept on the replacement", l_buffer.cell (0, 0).symbol.same_string (codes (<<0xFFFD, 0x301>>)))
			assert ("A in column 1", l_buffer.cell (0, 1).symbol.same_string ("A"))
		end

	test_line_spans_stay_in_place
			-- A span with non-scalar values takes the columns its width says, so the next
			-- span starts right after it.
		local
			l_buffer: BUFFER
			l_line: TEXT_LINE
		do
			create l_line.make_empty
			l_line.append_span (create {TEXT_SPAN}.make (codes (<<0x61, 0xD83D, 0xDE00, 0x62>>), create {STYLE}))
			l_line.append_span (create {TEXT_SPAN}.make ("Z", (create {STYLE}).with_foreground ({COLOR}.red)))
			create l_buffer.make (10, 1)
			l_buffer.set_line (0, 0, l_line, 10)
			assert ("line width 5", l_line.width = 5)
			assert ("b in column 3", l_buffer.cell (0, 3).symbol.same_string ("b"))
			assert ("Z in column 4", l_buffer.cell (0, 4).symbol.same_string ("Z"))
		end

	test_cell_setters_replace_non_scalar_values
			-- The TERMINAL_CELL setters store U+FFFD for a non-scalar value.
		local
			l_cell: TERMINAL_CELL
		do
			create l_cell.make_with_char ((0xD83D).to_character_32, create {STYLE})
			assert ("make_with_char", l_cell.symbol.same_string (codes (<<0xFFFD>>)) and l_cell.width = 1)
			l_cell.set_char ((0x110000).to_character_32)
			assert ("set_char", l_cell.symbol.same_string (codes (<<0xFFFD>>)))
			l_cell.set_symbol (codes (<<0x65, 0xDFFF>>))
			assert ("set_symbol", l_cell.symbol.same_string (codes (<<0x65, 0xFFFD>>)))
			l_cell.set_symbol ("ok")
			assert ("valid symbol kept", l_cell.symbol.same_string ("ok"))
		end

feature -- Serializer

	test_frame_is_valid_utf_8
			-- The probe case through BUFFER, DIFF_ENGINE and ANSI_SERIALIZER: the frame holds
			-- EF BF BD for each surrogate and no CESU-8 sequence (ED A0..BF).
		local
			l_sink: STRING_32
		do
			l_sink := rendered (codes (<<0xD83D, 0xDE00, 0x78>>))
			assert ("replacement bytes then x", l_sink.has_substring (bytes (<<0xEF, 0xBF, 0xBD, 0xEF, 0xBF, 0xBD, 0x78>>)))
			assert ("no ED byte", not l_sink.has_code (0xED))
			assert ("strict UTF-8", is_strict_utf_8 (l_sink))
		end

	test_frames_with_mixed_text_are_valid_utf_8
			-- Frames of valid text, non-scalar values and their mixes are all RFC 3629 UTF-8.
		do
			assert ("valid text", is_strict_utf_8 (rendered ({STRING_32} "h%/0xE9/llo %/0x65E5/%/0x672C/ %/0x1F600/ %/0x1F44D/%/0x1F3FD/")))
			assert ("lone high surrogate", is_strict_utf_8 (rendered (codes (<<0x41, 0xDBFF>>))))
			assert ("above U+10FFFF", is_strict_utf_8 (rendered (codes (<<0x110000, 0x7FFFFFFF>>))))
			assert ("surrogate with extensions", is_strict_utf_8 (rendered (codes (<<0x2764, 0xDBFF, 0xFE0F, 0x301>>))))
		end

feature {NONE} -- Helpers

	codes (a_codes: ARRAY [NATURAL_32]): STRING_32
			-- String of the code points `a_codes`, valid or not
		do
			create Result.make (a_codes.count)
			across a_codes as c loop
				Result.append_code (c)
			end
		end

	bytes (a_bytes: ARRAY [NATURAL_32]): STRING_32
			-- The sink form of the byte sequence `a_bytes` (one character per byte)
		do
			Result := codes (a_bytes)
		end

	rendered (a_text: READABLE_STRING_GENERAL): STRING_32
			-- Output of drawing `a_text` on row 0 of a 20x1 buffer and serializing the diff,
			-- one character per byte
		local
			l_prev, l_curr: BUFFER
			l_engine: DIFF_ENGINE
			l_backend: ANSI_TERMINAL_BACKEND
		do
			create l_prev.make (20, 1)
			create l_curr.make (20, 1)
			l_curr.put_string (0, 0, a_text, create {STYLE})
			create l_engine
			create Result.make (64)
			create l_backend.make_with_driver_and_sink (create {FAKE_CONSOLE_DRIVER}, Result)
			(create {ANSI_SERIALIZER}).render_spans (l_engine.diff (l_prev, l_curr), l_backend)
		end

	is_strict_utf_8 (a_bytes: READABLE_STRING_GENERAL): BOOLEAN
			-- Is `a_bytes` (one character per byte) well-formed UTF-8 as RFC 3629 / Unicode
			-- table 3-7 define it: no overlongs, no surrogates, nothing above U+10FFFF?
		local
			i, l_count, k: INTEGER
			b, l_lo, l_hi: NATURAL_32
		do
			from
				Result := True
				i := 1
			until
				not Result or i > a_bytes.count
			loop
				b := a_bytes.code (i)
				l_lo := 0x80
				l_hi := 0xBF
				if b > 0xFF then
					Result := False
				elseif b <= 0x7F then
					l_count := 0
				elseif b >= 0xC2 and b <= 0xDF then
					l_count := 1
				elseif b >= 0xE0 and b <= 0xEF then
					l_count := 2
					if b = 0xE0 then
						l_lo := 0xA0
					elseif b = 0xED then
						l_hi := 0x9F
					end
				elseif b >= 0xF0 and b <= 0xF4 then
					l_count := 3
					if b = 0xF0 then
						l_lo := 0x90
					elseif b = 0xF4 then
						l_hi := 0x8F
					end
				else
					Result := False
				end
				from
					k := 1
				until
					not Result or k > l_count
				loop
					if i + k > a_bytes.count then
						Result := False
					else
						b := a_bytes.code (i + k)
						if k = 1 then
							Result := b >= l_lo and b <= l_hi
						else
							Result := b >= 0x80 and b <= 0xBF
						end
					end
					k := k + 1
				end
				i := i + l_count + 1
			end
		end

end
