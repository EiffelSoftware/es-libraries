note
	description: "[
		`out' of text and widget items is UTF-8 (review finding U9): it used to fail a
		`to_string_8' precondition (or narrow the characters) on text above U+00FF.
		Non-ASCII text is built from code points: BOM-less sources compile as Latin-1.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_UTF_8_OUT

inherit
	EQA_TEST_SET

feature -- Tests

	test_text_out_is_utf_8
			-- Spans, lines and texts: CJK, an emoji and Latin-1 come out as their UTF-8 bytes.
		local
			l_span: TEXT_SPAN
			l_line: TEXT_LINE
			l_text: TEXT
		do
			create l_span.make_raw (nihon)
			assert ("span bytes", l_span.out.same_string (nihon_utf_8))
			assert ("span round trip", {UTF_CONVERTER}.utf_8_string_8_to_string_32 (l_span.out).same_string (nihon))

			create l_line.make_raw ({STRING_32} "a" + nihon + codes (<<0x1F600, 0xE9>>))
			assert ("line bytes", l_line.out.same_string ("a" + nihon_utf_8 + "%/0xF0/%/0x9F/%/0x98/%/0x80/%/0xC3/%/0xA9/"))

			create l_text.make_raw (nihon + {STRING_32} "%N" + nihon)
			assert ("text bytes", l_text.out.same_string (nihon_utf_8 + "%N" + nihon_utf_8))

			create l_span.make_raw ("plain")
			assert ("ASCII unchanged", l_span.out.same_string ("plain"))
		end

	test_widget_items_out_is_utf_8
			-- Table cells, rows and bar items.
		local
			l_cell: TABLE_CELL
			l_row: TABLE_ROW
			l_bar: BAR_ITEM
		do
			create l_cell.make_raw (nihon)
			assert ("cell", l_cell.out.same_string ("TABLE_CELL(" + nihon_utf_8 + ")"))

			create l_row.make_raw (<<nihon, {STRING_32} "x">>)
			assert ("row", l_row.out.same_string ("TABLE_ROW([TABLE_CELL(" + nihon_utf_8 + "), TABLE_CELL(x)])"))

			create l_bar.make (nihon, 3)
			assert ("bar item", l_bar.out.same_string ("BAR_ITEM(" + nihon_utf_8 + ": 3)"))
		end

feature {NONE} -- Helpers

	nihon: STRING_32
			-- U+65E5 U+672C
		do
			create Result.make (2)
			Result.append_code (0x65E5)
			Result.append_code (0x672C)
		end

	codes (a_codes: ARRAY [NATURAL_32]): STRING_32
			-- String of the code points `a_codes`
		do
			create Result.make (a_codes.count)
			across a_codes as c loop
				Result.append_code (c)
			end
		end

	nihon_utf_8: STRING_8
			-- UTF-8 bytes of `nihon`
		do
			Result := "%/0xE6/%/0x97/%/0xA5/%/0xE6/%/0x9C/%/0xAC/"
		end

end
