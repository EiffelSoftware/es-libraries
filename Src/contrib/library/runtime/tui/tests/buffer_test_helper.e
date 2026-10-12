note
	description: "[
		Helper class providing buffer snapshot extraction and comparison assertions for tests.
		Enables full-buffer snapshot assertions against expected multi-line arrays.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	BUFFER_TEST_HELPER

inherit
	EQA_TEST_SET

feature -- Snapshot Extraction

	buffer_row_as_string (a_buf: BUFFER; a_row: INTEGER): STRING_32
			-- Extract line `a_row` from `a_buf` as a STRING_32.
			-- Wide characters are placed at their start cell and trailing continuation
			-- cells have empty symbol, preserving visual alignment.
		require
			buf_not_void: a_buf /= Void
			valid_row: a_row >= 0 and a_row < a_buf.height
		local
			c: INTEGER
		do
			create Result.make (a_buf.width)
			from
				c := 0
			until
				c >= a_buf.width
			loop
				Result.append (a_buf.cell (a_row, c).symbol)
				c := c + 1
			end
		ensure
			result_not_void: Result /= Void
		end

	buffer_as_lines (a_buf: BUFFER): ARRAYED_LIST [STRING_32]
			-- Extract all rows of `a_buf` as an arrayed list of strings.
		require
			buf_not_void: a_buf /= Void
		local
			r: INTEGER
		do
			create Result.make (a_buf.height)
			from
				r := 0
			until
				r >= a_buf.height
			loop
				Result.extend (buffer_row_as_string (a_buf, r))
				r := r + 1
			end
		ensure
			count_matches_height: Result.count = a_buf.height
		end

feature -- Assertions

	assert_buffer_lines (a_tag: STRING; a_buf: BUFFER; a_expected: ARRAY [READABLE_STRING_GENERAL])
			-- Assert that `a_buf` rows match `a_expected` string lines.
		require
			tag_not_void: a_tag /= Void
			buf_not_void: a_buf /= Void
			expected_not_void: a_expected /= Void
		local
			r, l_count: INTEGER
			l_actual, l_exp: STRING_32
			l_msg: STRING
		do
			l_count := a_expected.count.min (a_buf.height)
			from
				r := 1
			until
				r > l_count
			loop
				l_actual := buffer_row_as_string (a_buf, r - 1)
				create l_exp.make_from_string_general (a_expected.item (r))
				if not l_actual.is_equal (l_exp) then
					create l_msg.make_from_string (a_tag)
					l_msg.append (" [row ")
					l_msg.append_integer (r - 1)
					l_msg.append ("]: expected %"")
					l_msg.append_string_general (l_exp)
					l_msg.append ("%" but got %"")
					l_msg.append_string_general (l_actual)
					l_msg.append ("%"")
					assert (l_msg, False)
				end
				r := r + 1
			end
			assert (a_tag + " row count match", a_buf.height >= a_expected.count)
		end

	assert_virtual_terminal_lines (a_tag: STRING; a_term: VIRTUAL_TERMINAL; a_expected: ARRAY [READABLE_STRING_GENERAL])
			-- Assert that `a_term` rows match `a_expected` string lines.
		require
			tag_not_void: a_tag /= Void
			term_not_void: a_term /= Void
			expected_not_void: a_expected /= Void
		local
			r, l_count: INTEGER
			l_actual, l_exp: STRING_32
			l_msg: STRING
		do
			l_count := a_expected.count.min (a_term.height)
			from
				r := 1
			until
				r > l_count
			loop
				l_actual := a_term.line (r - 1)
				create l_exp.make_from_string_general (a_expected.item (r))
				if not l_actual.is_equal (l_exp) then
					create l_msg.make_from_string (a_tag)
					l_msg.append (" [row ")
					l_msg.append_integer (r - 1)
					l_msg.append ("]: expected %"")
					l_msg.append_string_general (l_exp)
					l_msg.append ("%" but got %"")
					l_msg.append_string_general (l_actual)
					l_msg.append ("%"")
					assert (l_msg, False)
				end
				r := r + 1
			end
			assert (a_tag + " row count match", a_term.height >= a_expected.count)
		end

	assert_cell_style (a_tag: STRING; a_buf: BUFFER; a_row, a_col: INTEGER; a_expected_style: STYLE)
			-- Assert that the cell at (`a_row`, `a_col`) has style matching `a_expected_style`.
		require
			tag_not_void: a_tag /= Void
			buf_not_void: a_buf /= Void
			valid_pos: a_buf.is_valid_position (a_row, a_col)
			style_not_void: a_expected_style /= Void
		do
			assert (a_tag + " cell style matches", a_buf.cell (a_row, a_col).style.is_equal (a_expected_style))
		end

	assert_cell_symbol (a_tag: STRING; a_buf: BUFFER; a_row, a_col: INTEGER; a_expected_symbol: READABLE_STRING_GENERAL)
			-- Assert that the cell at (`a_row`, `a_col`) has symbol matching `a_expected_symbol`.
		require
			tag_not_void: a_tag /= Void
			buf_not_void: a_buf /= Void
			valid_pos: a_buf.is_valid_position (a_row, a_col)
			symbol_not_void: a_expected_symbol /= Void
		local
			l_exp: STRING_32
		do
			create l_exp.make_from_string_general (a_expected_symbol)
			assert (a_tag + " cell symbol matches", a_buf.cell (a_row, a_col).symbol.is_equal (l_exp))
		end

end
