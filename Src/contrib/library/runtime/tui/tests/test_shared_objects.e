note
	description: "[
		Shared objects stay immutable (review finding M4):
		- every cell symbol, pooled or not, is an IMMUTABLE_STRING_32 (a STRING_32 could be
		  changed through an object test and would change every cell sharing it)
		- `set_style' stores a private copy, as the class note says
		STYLE's `copy' is exported to {STYLE} only; that is checked by the compiler.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_SHARED_OBJECTS

inherit
	EQA_TEST_SET

feature -- Tests

	test_symbols_are_immutable
			-- Pooled ASCII and non-ASCII symbols, clusters, blanks, continuations and a cluster
			-- grown by a combining mark: none is a mutable STRING_32.
		local
			l_buf: BUFFER
			l_text, l_mark: STRING_32
			c: INTEGER
		do
			assert ("pooled ASCII", not attached {STRING_32} {TERMINAL_CELL}.pooled_char (97))
			assert ("pooled non-ASCII", not attached {STRING_32} {TERMINAL_CELL}.pooled_char (0x65E5))
			assert ("pooled once", {TERMINAL_CELL}.pooled_char (0x65E5) = {TERMINAL_CELL}.pooled_char (0x65E5))

			create l_buf.make (8, 1)
			create l_text.make (8)
			l_text.append_code (0x61)       -- a
			l_text.append_code (0x65E5)     -- wide
			l_text.append_code (0x65)       -- e + combining acute, one cluster
			l_text.append_code (0x301)
			l_text.append_code (0x1F468)    -- ZWJ family, one wide cluster
			l_text.append_code (0x200D)
			l_text.append_code (0x1F469)
			l_buf.set_string_clipped (0, 0, l_text, 0, 8, create {STYLE})
			-- A mark written on its own attaches to the cell before it
			l_buf.set_string_clipped (0, 6, "x", 0, 8, create {STYLE})
			create l_mark.make (1)
			l_mark.append_code (0x301)
			l_buf.set_string_clipped (0, 7, l_mark, 0, 8, create {STYLE})
			from
				c := 0
			until
				c >= 8
			loop
				assert ("cell " + c.out + " immutable", not attached {STRING_32} l_buf.cell (0, c).symbol)
				c := c + 1
			end
			assert ("grown cluster", l_buf.cell (0, 6).symbol.count = 2)
			assert ("new cell", not attached {STRING_32} (create {TERMINAL_CELL}).symbol)
		end

	test_set_style_stores_private_copy
			-- The cell keeps an equal but separate style.
		local
			l_cell: TERMINAL_CELL
			l_style: STYLE
		do
			create l_cell
			l_style := (create {STYLE}).with_bold.with_foreground ({COLOR}.red)
			l_cell.set_style (l_style)
			assert ("equal", l_cell.style.is_equal (l_style))
			assert ("private", l_cell.style /= l_style)
		end

end
