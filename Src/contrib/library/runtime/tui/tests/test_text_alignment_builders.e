note
	description: "[
		P1 item V11, alignment builders on TEXT_LINE, TEXT and TUI_PARAGRAPH, and the order in
		which their alignments combine (review/p1_visualization_plan.md).
		The `test_ratatui_*` cases are tests of Ratatui ratatui-core/src/text/line.rs and
		text.rs, ratatui-widgets/src/paragraph.rs and ratatui/tests/widgets_paragraph.rs, as
		row-exact buffer snapshots. A line's alignment wins over the paragraph's; the
		paragraph's is the one set on it, else the text's (0.30.1, #2369), else left.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_TEXT_ALIGNMENT_BUILDERS

inherit
	BUFFER_TEST_HELPER

feature -- Ratatui line.rs

	test_ratatui_line_alignment
			-- Ratatui `alignment`: a line with `Alignment::Left` has `Some (Left)`, a new line
			-- has `None` (here `has_alignment` False, and `alignment` reads left).
		local
			l_line: TEXT_LINE
		do
			l_line := (create {TEXT_LINE}.make_raw ("This is left")).with_alignment ({TEXT_ALIGNMENT}.left)
			assert ("set left", l_line.has_alignment and l_line.alignment = {TEXT_ALIGNMENT}.left)
			create l_line.make_raw ("This is default")
			assert ("default none", not l_line.has_alignment and l_line.alignment = {TEXT_ALIGNMENT}.left)
			assert ("default resolves to parent", l_line.resolved_alignment ({TEXT_ALIGNMENT}.right) = {TEXT_ALIGNMENT}.right)
		end

	test_ratatui_line_left_aligned_centered_right_aligned
			-- Ratatui `left_aligned`, `centered`, `right_aligned`: each builder gives a line with
			-- that alignment set. Here the builders return twins and leave the original as it was.
		local
			l_line, l_twin: TEXT_LINE
		do
			create l_line.make_raw ("Hello, world!")
			l_twin := l_line.left_aligned
			assert ("left", l_twin.has_alignment and l_twin.alignment = {TEXT_ALIGNMENT}.left)
			l_twin := l_line.centered
			assert ("center", l_twin.has_alignment and l_twin.alignment = {TEXT_ALIGNMENT}.center)
			l_twin := l_line.right_aligned
			assert ("right", l_twin.has_alignment and l_twin.alignment = {TEXT_ALIGNMENT}.right)
			assert ("same text", l_twin.to_plain_string.same_string_general ("Hello, world!"))
			assert ("original unchanged", not l_line.has_alignment)
			assert ("twin owns its spans", l_twin.spans /= l_line.spans)
			l_twin := l_line.centered.without_alignment
			assert ("without", not l_twin.has_alignment and l_twin.is_equal (l_line))
		end

	test_ratatui_line_render_aligned
			-- Ratatui `render_centered`, `render_right_aligned` (Line "Hello " in blue + "world!"
			-- in green, in 15 columns) and `render_truncates_left` (a left-aligned line cut to 5).
			-- The spans' colours land where the text does.
		local
			l_buf: BUFFER
			l_line: TEXT_LINE
		do
			l_line := hello_world
			create l_buf.make (15, 1)
			l_line.centered.render (l_buf.area, l_buf)
			assert_buffer_lines ("centered", l_buf, <<" Hello world!  ">>)
			assert ("centered blue", fg_is (l_buf, 0, 1, {COLOR}.Blue) and fg_is (l_buf, 0, 6, {COLOR}.Blue))
			assert ("centered green", fg_is (l_buf, 0, 7, {COLOR}.Green) and fg_is (l_buf, 0, 12, {COLOR}.Green))

			create l_buf.make (15, 1)
			l_line.right_aligned.render (l_buf.area, l_buf)
			assert_buffer_lines ("right", l_buf, <<"   Hello world!">>)
			assert ("right blue", fg_is (l_buf, 0, 3, {COLOR}.Blue) and fg_is (l_buf, 0, 8, {COLOR}.Blue))
			assert ("right green", fg_is (l_buf, 0, 9, {COLOR}.Green) and fg_is (l_buf, 0, 14, {COLOR}.Green))

			create l_buf.make (5, 1)
			(create {TEXT_LINE}.make_raw ("Hello world")).left_aligned.render (l_buf.area, l_buf)
			assert_buffer_lines ("truncates left", l_buf, <<"Hello">>)
		end

feature -- Ratatui text.rs

	test_ratatui_text_left_aligned_centered_right_aligned
			-- Ratatui `left_aligned`, `centered`, `right_aligned` of text.rs, and the doc example
			-- of `Text::alignment` (None by default). The builders leave the original unchanged.
		local
			l_text, l_twin: TEXT
		do
			create l_text.make_raw ("Hello, world!")
			assert ("default none", not l_text.has_alignment and l_text.alignment = {TEXT_ALIGNMENT}.left)
			l_twin := l_text.left_aligned
			assert ("left", l_twin.has_alignment and l_twin.alignment = {TEXT_ALIGNMENT}.left)
			l_twin := l_text.centered
			assert ("center", l_twin.has_alignment and l_twin.alignment = {TEXT_ALIGNMENT}.center)
			l_twin := l_text.right_aligned
			assert ("right", l_twin.has_alignment and l_twin.alignment = {TEXT_ALIGNMENT}.right)
			l_twin := l_text.with_alignment ({TEXT_ALIGNMENT}.right)
			assert ("with_alignment", l_twin.has_alignment and l_twin.alignment = {TEXT_ALIGNMENT}.right)
			assert ("original unchanged", not l_text.has_alignment)
			assert ("twin owns its lines", l_twin.lines.first /= l_text.lines.first)
			assert ("without", l_text.centered.without_alignment.is_equal (l_text))
		end

	test_ratatui_text_render_aligned
			-- Ratatui `render_right_aligned` ("  foo"), `render_centered_odd` (" foo ") and
			-- `render_centered_even` (" foo  ").
		local
			l_buf: BUFFER
			l_text: TEXT
		do
			create l_text.make_raw ("foo")
			create l_buf.make (5, 1)
			l_text.right_aligned.render (l_buf.area, l_buf)
			assert_buffer_lines ("right", l_buf, <<"  foo">>)
			create l_buf.make (5, 1)
			l_text.centered.render (l_buf.area, l_buf)
			assert_buffer_lines ("centered odd", l_buf, <<" foo ">>)
			create l_buf.make (6, 1)
			l_text.centered.render (l_buf.area, l_buf)
			assert_buffer_lines ("centered even", l_buf, <<" foo  ">>)
		end

	test_ratatui_text_render_one_line_right
			-- Ratatui `render_one_line_right`: a right-aligned text with a centred line "bar"
			-- gives "  foo" and " bar ". Here also: a line set to left stays left in that text,
			-- and a text without alignment renders left.
		local
			l_buf: BUFFER
			l_text: TEXT
		do
			create l_text.make (<<create {TEXT_LINE}.make_raw ("foo"), (create {TEXT_LINE}.make_raw ("bar")).centered>>)
			create l_buf.make (5, 2)
			l_text.right_aligned.render (l_buf.area, l_buf)
			assert_buffer_lines ("one line centred", l_buf, <<"  foo", " bar ">>)

			create l_text.make (<<create {TEXT_LINE}.make_raw ("foo"), (create {TEXT_LINE}.make_raw ("bar")).left_aligned>>)
			create l_buf.make (5, 2)
			l_text.right_aligned.render (l_buf.area, l_buf)
			assert_buffer_lines ("explicit left line", l_buf, <<"  foo", "bar  ">>)
			create l_buf.make (5, 2)
			l_text.render (l_buf.area, l_buf)
			assert_buffer_lines ("no text alignment", l_buf, <<"foo  ", "bar  ">>)
		end

feature -- Ratatui paragraph.rs

	test_ratatui_paragraph_left_aligned_centered_right_aligned
			-- Ratatui `left_aligned`, `centered`, `right_aligned` of paragraph.rs.
		local
			l_para: TUI_PARAGRAPH
		do
			create l_para.make_raw ("Hello, world!")
			assert ("default left, not set", l_para.alignment = {TEXT_ALIGNMENT}.left and not l_para.has_alignment)
			assert ("left", l_para.left_aligned.alignment = {TEXT_ALIGNMENT}.left and l_para.left_aligned.has_alignment)
			assert ("center", l_para.centered.alignment = {TEXT_ALIGNMENT}.center)
			assert ("right", l_para.right_aligned.alignment = {TEXT_ALIGNMENT}.right)
			assert ("original unchanged", not l_para.has_alignment)
		end

	test_ratatui_paragraph_inherit_text_alignment
			-- Ratatui `inherit_text_alignment_left_aligned`, `_centered` and `_right_aligned`
			-- (0.30.1, #2369): a paragraph made from an aligned text takes its alignment.
		local
			l_text: TEXT
		do
			create l_text.make (<<create {TEXT_LINE}.make_raw ("Hello, world!")>>)
			assert ("left", (create {TUI_PARAGRAPH}.make (l_text.left_aligned)).alignment = {TEXT_ALIGNMENT}.left)
			assert ("center", (create {TUI_PARAGRAPH}.make (l_text.centered)).alignment = {TEXT_ALIGNMENT}.center)
			assert ("right", (create {TUI_PARAGRAPH}.make (l_text.right_aligned)).alignment = {TEXT_ALIGNMENT}.right)
		end

	test_ratatui_paragraph_inherit_text_alignment_renders
			-- The example of #2369 in Ratatui's CHANGELOG: "one", "double", "quadruple" in a
			-- centred text, in a bordered paragraph that sets no alignment, are centred (they
			-- were left aligned before). 13 x 5: inner width 11.
		local
			l_buf: BUFFER
			l_text: TEXT
			l_para: TUI_PARAGRAPH
		do
			create l_text.make (<<create {TEXT_LINE}.make_raw ("one"), create {TEXT_LINE}.make_raw ("double"),
				create {TEXT_LINE}.make_raw ("quadruple")>>)
			create l_para.make (l_text.centered)
			l_para := l_para.with_block (create {TUI_BLOCK}.make)
			create l_buf.make (13, 5)
			l_para.render (l_buf.area, l_buf)
			assert_buffer_lines ("centred", l_buf, bordered (<<"    one    ", "  double   ", " quadruple ">>, 11, 3))
		end

	test_ratatui_paragraph_with_alignment
			-- Ratatui `test_render_paragraph_with_left_alignment`, `_center_alignment` and
			-- `_right_alignment`: "Hello, world!" truncated, wrapped (trim False) and trimmed
			-- (trim True), in areas 13 to 17 wide and 10 wide.
			-- Centred lines start at `width / 2 - line_width / 2`, as in Ratatui (review fix #7):
			-- in 16 columns "  Hello, world! " (16 / 2 - 13 / 2 = 2).
			-- Adapted: wrapped with trim False, Ratatui drops the space at the break ("Hello,"
			-- is 6 wide); EiffelTUI keeps it ("Hello, " is 7 wide). Centred, both start at 2
			-- (10 / 2 - 7 / 2 = 10 / 2 - 6 / 2); right aligned, EiffelTUI starts at 3, Ratatui at 4.
		local
			l_para: TUI_PARAGRAPH
			l_modes: ARRAY [TUI_PARAGRAPH]
		do
			create l_para.make_raw ("Hello, world!")
			across <<{TEXT_ALIGNMENT}.left, {TEXT_ALIGNMENT}.center, {TEXT_ALIGNMENT}.right>> as a loop
				l_modes := <<l_para.with_alignment (a), l_para.with_alignment (a).with_wrap ({TEXT_WRAP_MODE}.word, False),
					l_para.with_alignment (a).with_wrap ({TEXT_WRAP_MODE}.word, True)>>
				across l_modes as p loop
					assert_paragraph ("fits", p, <<"Hello, world!">>)
					if a = {TEXT_ALIGNMENT}.left then
						assert_paragraph ("left 15", p, <<"Hello, world!  ">>)
					elseif a = {TEXT_ALIGNMENT}.center then
						assert_paragraph ("center 15", p, <<" Hello, world! ">>)
						assert_paragraph ("center 16", p, <<"  Hello, world! ">>)
						assert_paragraph ("center 17", p, <<"  Hello, world!  ">>)
					else
						assert_paragraph ("right 15", p, <<"  Hello, world!">>)
					end
				end
				assert_paragraph ("truncated", l_modes [1], <<"Hello, wor">>)
				if a = {TEXT_ALIGNMENT}.left then
					assert_paragraph ("wrapped left", l_modes [2], <<"Hello,    ", "world!    ">>)
					assert_paragraph ("trimmed left", l_modes [3], <<"Hello,    ", "world!    ">>)
				elseif a = {TEXT_ALIGNMENT}.center then
					assert_paragraph ("wrapped center", l_modes [2], <<"  Hello,  ", "  world!  ">>)
					assert_paragraph ("trimmed center", l_modes [3], <<"  Hello,  ", "  world!  ">>)
				else
					assert_paragraph ("wrapped right (adapted)", l_modes [2], <<"   Hello, ", "    world!">>)
					assert_paragraph ("trimmed right", l_modes [3], <<"    Hello,", "    world!">>)
				end
			end
		end

feature -- Ratatui tests/widgets_paragraph.rs

	test_ratatui_widgets_paragraph_can_align_spans
			-- Ratatui `widgets_paragraph_can_align_spans`: a right-aligned line keeps its
			-- alignment in a left and in a centred paragraph; lines set to left stay left in a
			-- right-aligned paragraph, the others follow the paragraph. 20 x 10 and 20 x 9.
		local
			l_text: TEXT
			l_para: TUI_PARAGRAPH
			l_buf: BUFFER
		do
			create l_text.make (<<(create {TEXT_LINE}.make_raw ("This string will override the paragraph alignment to be right aligned.")).right_aligned,
				create {TEXT_LINE}.make_raw ("This string will be aligned based on the alignment of the paragraph.")>>)
			create l_para.make (l_text)
			l_para := l_para.with_block (create {TUI_BLOCK}.make).with_wrap ({TEXT_WRAP_MODE}.word, True)

			create l_buf.make (20, 10)
			l_para.left_aligned.render (l_buf.area, l_buf)
			assert_buffer_lines ("left", l_buf, bordered (<<"  This string will", "      override the", "         paragraph",
				"   alignment to be", "    right aligned.", "This string will  ", "be aligned based  ", "on the alignment  ">>, 18, 8))
			create l_buf.make (20, 10)
			l_para.centered.render (l_buf.area, l_buf)
			assert_buffer_lines ("center", l_buf, bordered (<<"  This string will", "      override the", "         paragraph",
				"   alignment to be", "    right aligned.", " This string will ", " be aligned based ", " on the alignment ">>, 18, 8))

			create l_text.make (<<(create {TEXT_LINE}.make_raw ("This string")).left_aligned,
				(create {TEXT_LINE}.make_raw ("will override the paragraph alignment")).left_aligned,
				create {TEXT_LINE}.make_raw ("This"), create {TEXT_LINE}.make_raw ("must be pretty long"),
				create {TEXT_LINE}.make_raw ("in order to effectively show"), create {TEXT_LINE}.make_raw ("truncation.")>>)
			create l_para.make (l_text)
			l_para := l_para.with_block (create {TUI_BLOCK}.make)
			create l_buf.make (20, 10)
			l_para.right_aligned.render (l_buf.area, l_buf)
			assert_buffer_lines ("explicit left in right", l_buf, bordered (<<"This string       ", "will override the ",
				"              This", "must be pretty lon", "in order to effect", "       truncation.", "", "">>, 18, 8))
			create l_buf.make (20, 9)
			l_para.left_aligned.render (l_buf.area, l_buf)
			assert_buffer_lines ("explicit left in left", l_buf, bordered (<<"This string       ", "will override the ",
				"This              ", "must be pretty lon", "in order to effect", "truncation.       ", "">>, 18, 7))
		end

	test_ratatui_widgets_paragraph_works_with_padding_centred_line
			-- The last case of Ratatui `widgets_paragraph_works_with_padding`: "This is always
			-- centered." (a centred line) and SAMPLE_STRING in a right-aligned, trimmed paragraph,
			-- in a bordered block with padding (2, 2, 1, 1), 22 x 14: inner width 16.
			-- "centered." (9 wide) is at 16 / 2 - 9 / 2 = 4, as in Ratatui (review fix #7; it
			-- was adapted to 3 before).
		local
			l_text: TEXT
			l_para: TUI_PARAGRAPH
			l_buf: BUFFER
			l_block: TUI_BLOCK
		do
			create l_text.make (<<(create {TEXT_LINE}.make_raw ("This is always centered.")).centered,
				create {TEXT_LINE}.make_raw (Sample_string)>>)
			create l_block.make
			l_block := l_block.with_four_sided_padding (create {PADDING}.make (1, 2, 1, 2))
			create l_para.make (l_text)
			l_para := l_para.with_block (l_block).with_wrap ({TEXT_WRAP_MODE}.word, True).right_aligned
			create l_buf.make (22, 14)
			l_para.render (l_buf.area, l_buf)
			assert_buffer_lines ("padded", l_buf, bordered (<<"                    ", "   This is always   ", "      centered.     ",
				"    The library is  ", "      based on the  ", "      principle of  ", "         immediate  ",
				"    rendering with  ", "      intermediate  ", "     buffers. This  ", "     means that at  ",
				"                    ">>, 20, 12))
		end

feature -- Precedence

	test_paragraph_alignment_precedence
			-- Every combination of line (none, left, center, right), paragraph (none, left,
			-- center, right) and text (none, left, center, right) alignment, for "ab" in 6
			-- columns: the line's own wins, else the paragraph's, else the text's, else left.
			-- TEXT.render follows the same order without the paragraph.
		local
			l_text: TEXT
			l_line: TEXT_LINE
			l_para: TUI_PARAGRAPH
			l_buf: BUFFER
			l_expected, l_expected_text: NATURAL_8
			i, j, k: INTEGER
		do
			from i := 0 until i > 3 loop
				from j := 0 until j > 3 loop
					from k := 0 until k > 3 loop
						create l_line.make_raw ("ab")
						if i > 0 then
							l_line.set_alignment ((i - 1).to_natural_8)
						end
						create l_text.make (<<l_line>>)
						if k > 0 then
							l_text.set_alignment ((k - 1).to_natural_8)
						end
						create l_para.make (l_text)
						if j > 0 then
							l_para.set_alignment ((j - 1).to_natural_8)
						end
						if i > 0 then
							l_expected := (i - 1).to_natural_8
						elseif j > 0 then
							l_expected := (j - 1).to_natural_8
						elseif k > 0 then
							l_expected := (k - 1).to_natural_8
						else
							l_expected := {TEXT_ALIGNMENT}.left
						end
						create l_buf.make (6, 1)
						l_para.render (l_buf.area, l_buf)
						assert_buffer_lines ("paragraph " + i.out + j.out + k.out, l_buf, <<placed ("ab", 6, l_expected)>>)

						if i > 0 then
							l_expected_text := (i - 1).to_natural_8
						elseif k > 0 then
							l_expected_text := (k - 1).to_natural_8
						else
							l_expected_text := {TEXT_ALIGNMENT}.left
						end
						create l_buf.make (6, 1)
						l_text.render (l_buf.area, l_buf)
						assert_buffer_lines ("text " + i.out + k.out, l_buf, <<placed ("ab", 6, l_expected_text)>>)
						k := k + 1
					end
					j := j + 1
				end
				i := i + 1
			end
		end

	test_paragraph_alignment_follows_text
			-- A paragraph without its own alignment reads the text's at render time:
			-- `set_text` with a right-aligned text, and `text.set_alignment`, are followed.
			-- `reset_alignment` and `without_alignment` go back to the text's; a paragraph set
			-- to left overrides a centred text. Copies share neither setting.
		local
			l_para, l_copy: TUI_PARAGRAPH
			l_buf: BUFFER
		do
			create l_para.make_raw ("ab")
			l_para.set_text ((create {TEXT}.make_raw ("ab")).right_aligned)
			assert ("follows new text", l_para.alignment = {TEXT_ALIGNMENT}.right and not l_para.has_alignment)
			create l_buf.make (6, 1)
			l_para.render (l_buf.area, l_buf)
			assert_buffer_lines ("right from text", l_buf, <<"    ab">>)

			l_para.text.set_alignment ({TEXT_ALIGNMENT}.center)
			create l_buf.make (6, 1)
			l_para.render (l_buf.area, l_buf)
			assert_buffer_lines ("center from text", l_buf, <<"  ab  ">>)

			l_para.set_alignment ({TEXT_ALIGNMENT}.left)
			create l_buf.make (6, 1)
			l_para.render (l_buf.area, l_buf)
			assert_buffer_lines ("left overrides text", l_buf, <<"ab    ">>)

			l_copy := l_para.without_alignment
			assert ("copy back to text", not l_copy.has_alignment and l_copy.alignment = {TEXT_ALIGNMENT}.center)
			assert ("original keeps left", l_para.has_alignment and l_para.alignment = {TEXT_ALIGNMENT}.left)
			l_para.reset_alignment
			assert ("reset", not l_para.has_alignment and l_para.alignment = {TEXT_ALIGNMENT}.center)
			create l_buf.make (6, 1)
			l_para.render (l_buf.area, l_buf)
			assert_buffer_lines ("center again", l_buf, <<"  ab  ">>)
		end

	test_wrapped_lines_keep_alignment_state
			-- Wrapping (character and word, with an oversized word) keeps whether a line has
			-- an alignment: a line without one gives lines without one, a line set to left
			-- gives lines set to left. So a wrapped left line stays left in a right paragraph.
		local
			l_lines: ARRAYED_LIST [TEXT_LINE]
			l_buf: BUFFER
			l_para: TUI_PARAGRAPH
			l_text: TEXT
		do
			across <<{TEXT_WRAP_MODE}.character, {TEXT_WRAP_MODE}.word>> as m loop
				l_lines := {TEXT_LAYOUT}.wrap_line (create {TEXT_LINE}.make_raw ("aa bbbbbbbb c"), 4, m, True)
				assert ("several", l_lines.count > 2)
				assert ("unset kept", across l_lines as l all not l.has_alignment end)
				l_lines := {TEXT_LAYOUT}.wrap_line ((create {TEXT_LINE}.make_raw ("aa bbbbbbbb c")).left_aligned, 4, m, True)
				assert ("left kept", across l_lines as l all l.has_alignment and l.alignment = {TEXT_ALIGNMENT}.left end)
				l_lines := {TEXT_LAYOUT}.wrap_line ((create {TEXT_LINE}.make_raw ("aa bbbbbbbb c")).centered, 4, m, True)
				assert ("center kept", across l_lines as l all l.has_alignment and l.alignment = {TEXT_ALIGNMENT}.center end)
			end
			create l_text.make (<<(create {TEXT_LINE}.make_raw ("aa bb")).left_aligned, create {TEXT_LINE}.make_raw ("cc dd")>>)
			create l_para.make (l_text)
			l_para := l_para.right_aligned.with_wrap ({TEXT_WRAP_MODE}.word, True)
			create l_buf.make (4, 4)
			l_para.render (l_buf.area, l_buf)
			assert_buffer_lines ("wrapped", l_buf, <<"aa  ", "bb  ", "  cc", "  dd">>)
		end

feature -- Equality, copy, conversion

	test_alignment_equality_and_copy
			-- `is_equal` tells a line or text without alignment from one set to left (Ratatui
			-- compares the `Option`). A paragraph compares the alignment it uses, so one that
			-- inherits center equals one set to center (Ratatui stores the inherited value).
			-- `twin` keeps the setting. The string conversions of TEXT_LINE and TEXT still give
			-- values without alignment, and the builders work on them.
		local
			l_line, l_line2: TEXT_LINE
			l_text, l_text2: TEXT
			l_para: TUI_PARAGRAPH
			l_list: TEXT
		do
			create l_line.make_raw ("ab")
			assert ("unset /= left", not l_line.is_equal (l_line.left_aligned))
			assert ("left = left", l_line.left_aligned.is_equal (l_line.with_alignment ({TEXT_ALIGNMENT}.left)))
			l_line2 := l_line.centered
			assert ("twin keeps", l_line2.twin.has_alignment and l_line2.twin.is_equal (l_line2))

			create l_text.make_raw ("ab")
			assert ("text unset /= left", not l_text.is_equal (l_text.left_aligned))
			l_text2 := l_text.right_aligned
			assert ("text twin keeps", l_text2.twin.has_alignment and l_text2.twin.is_equal (l_text2))

			create l_para.make (l_text.centered)
			assert ("inherited = set", l_para.is_equal ((create {TUI_PARAGRAPH}.make (l_text.centered)).centered))
			assert ("differs from left", not l_para.is_equal (l_para.left_aligned))
			assert ("twin keeps own", l_para.right_aligned.twin.has_alignment)

				-- Conversions from strings
			l_line := "converted"
			assert ("converted line unset", not l_line.has_alignment)
			assert ("converted line builder", l_line.centered.alignment = {TEXT_ALIGNMENT}.center)
			l_text := "one%Ntwo"
			assert ("converted text unset", not l_text.has_alignment and across l_text.lines as l all not l.has_alignment end)
			create l_list.make_empty
			l_list.append_line ("appended")
			assert ("appended line unset", not l_list.lines.last.has_alignment)
			l_line := create {TEXT_SPAN}.make_raw ("span")
			assert ("converted span line unset", not l_line.has_alignment)
		end

	test_alignment_preconditions
			-- An invalid alignment (3) is refused by every builder and setter.
		do
			assert ("line with", precondition_raised (agent (create {TEXT_LINE}.make_raw ("a")).with_alignment (3), "valid_align"))
			assert ("line set", precondition_raised (agent (create {TEXT_LINE}.make_raw ("a")).set_alignment (3), "valid_align"))
			assert ("line resolved", precondition_raised (agent (create {TEXT_LINE}.make_raw ("a")).resolved_alignment (3), "valid_default"))
			assert ("text with", precondition_raised (agent (create {TEXT}.make_raw ("a")).with_alignment (3), "valid_align"))
			assert ("text set", precondition_raised (agent (create {TEXT}.make_raw ("a")).set_alignment (3), "valid_align"))
			assert ("paragraph with", precondition_raised (agent (create {TUI_PARAGRAPH}.make_raw ("a")).with_alignment (3), "valid_align"))
			assert ("valid accepted", not precondition_raised (agent (create {TEXT_LINE}.make_raw ("a")).with_alignment (2), "valid_align"))
		end

feature {NONE} -- Helpers

	Sample_string: STRING = "The library is based on the principle of immediate rendering with intermediate buffers. This means that at each new frame you should build all widgets that are supposed to be part of the UI. While providing a great flexibility for rich and interactive UI, this may introduce overhead for highly dynamic content."
			-- Ratatui's SAMPLE_STRING (tests/widgets_paragraph.rs)

	hello_world: TEXT_LINE
			-- "Hello " in blue and "world!" in green (Ratatui `hello_world`, without its
			-- italic line style)
		do
			create Result.make (<<create {TEXT_SPAN}.make ("Hello ", create {STYLE}.make_fg ({COLOR}.Blue)),
				create {TEXT_SPAN}.make ("world!", create {STYLE}.make_fg ({COLOR}.Green))>>)
		end

	fg_is (a_buf: BUFFER; a_row, a_col: INTEGER; a_color: COLOR): BOOLEAN
			-- Is the foreground of cell (`a_row`, `a_col`) `a_color`?
		do
			Result := a_buf.cell (a_row, a_col).style.foreground.is_equal (a_color)
		end

	assert_paragraph (a_tag: STRING; a_para: TUI_PARAGRAPH; a_expected: ARRAY [READABLE_STRING_GENERAL])
			-- Render `a_para` on a buffer as wide as the first row of `a_expected` and as high
			-- as its rows, and compare (Ratatui's `test_case`).
		local
			l_buf: BUFFER
		do
			create l_buf.make (a_expected [1].count, a_expected.count)
			a_para.render (l_buf.area, l_buf)
			assert_buffer_lines (a_tag + " (" + l_buf.width.out + ")", l_buf, a_expected)
		end

	placed (a_text: STRING; a_width: INTEGER; a_align: NATURAL_8): STRING
			-- `a_text` placed in `a_width` columns with `a_align`. Centred as TEXT_LINE does,
			-- `(a_width - count) // 2`; the paragraph's `a_width // 2 - count // 2` gives the
			-- same column unless `a_width` is even and `count` odd, which the callers avoid.
		local
			l_left: INTEGER
		do
			inspect a_align
			when {TEXT_ALIGNMENT}.center then
				l_left := (a_width - a_text.count) // 2
			when {TEXT_ALIGNMENT}.right then
				l_left := a_width - a_text.count
			else
				l_left := 0
			end
			create Result.make_filled (' ', l_left)
			Result.append (a_text)
			Result.append (create {STRING}.make_filled (' ', a_width - Result.count))
		end

	bordered (a_rows: ARRAY [STRING]; a_width, a_height: INTEGER): ARRAY [STRING_32]
			-- `a_rows`, each padded to `a_width` and with as many empty rows after them as make
			-- `a_height`, inside a plain border (Ratatui `Block::bordered`)
		local
			l_row: STRING_32
			i: INTEGER
		do
			create Result.make_filled ({STRING_32} "", 1, a_height + 2)
			Result [1] := {STRING_32} "%/0x250C/" + horizontal (a_width) + {STRING_32} "%/0x2510/"
			from i := 1 until i > a_height loop
				create l_row.make_from_string ({STRING_32} "%/0x2502/")
				if i <= a_rows.count then
					l_row.append_string_general (a_rows [i])
				end
				l_row.append (create {STRING_32}.make_filled (' ', a_width + 1 - l_row.count))
				l_row.append ({STRING_32} "%/0x2502/")
				Result [i + 1] := l_row
				i := i + 1
			end
			Result [a_height + 2] := {STRING_32} "%/0x2514/" + horizontal (a_width) + {STRING_32} "%/0x2518/"
		end

	horizontal (a_width: INTEGER): STRING_32
			-- `a_width` horizontal border characters
		do
			create Result.make_filled ('%/0x2500/', a_width)
		end

	precondition_raised (a_action: ROUTINE; a_tag: STRING): BOOLEAN
			-- Does `a_action` raise a precondition violation tagged `a_tag`?
		local
			l_retried: BOOLEAN
		do
			if not l_retried then
				a_action.call
			end
		rescue
			if not l_retried then
				l_retried := True
				Result := attached (create {EXCEPTION_MANAGER}).last_exception as e and then
					(attached {PRECONDITION_VIOLATION} e.original as v and then
					(attached v.description as d and then d.same_string (a_tag)))
				retry
			end
		end

end
