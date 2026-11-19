note
	description: "[
		TUI_GAUGE against Ratatui's Gauge (review fix of 2026-10-23, found from a screenshot of
		EXAMPLE_GAUGE: the unfilled part did not take the gauge background).
		The `test_ratatui_*` cases are the Gauge tests of Ratatui ratatui/tests/widgets_gauge.rs,
		as row-exact buffer snapshots with the styles checked where Ratatui checks them.
		Ratatui lays the first two out with `margin (2)` and two `Percentage (50)` rows of a
		40 x 10 buffer, that is the rects (2, 2, 36, 3) and (2, 5, 36, 3) used here.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_GAUGE_RATATUI

inherit
	BUFFER_TEST_HELPER

feature -- Ratatui tests/widgets_gauge.rs

	test_ratatui_gauge_renders
			-- Ratatui `widgets_gauge_renders`: red on blue, Unicode, 43 % and 0.5113. The whole
			-- gauge row is red on blue (unfilled cells included), except "51" over the filled part,
			-- which is blue on red; the "%" after it is not in the filled part.
			-- The label style is set plain, as Ratatui's default label; EiffelTUI's default label
			-- style is bold (`test_gauge_default_label_is_bold`).
		local
			l_buf: BUFFER
			l_style: STYLE
			c: INTEGER
		do
			create l_buf.make (40, 10)
			create l_style.make_with_colors ({COLOR}.Red, {COLOR}.Blue);
			(create {TUI_GAUGE}.make).with_block ((create {TUI_BLOCK}.make).with_title ("Percentage")).with_label_style (create {STYLE}).
				with_gauge_style (l_style).with_use_unicode (True).with_percent (43).render (create {RECT}.make (2, 2, 36, 3), l_buf);
			(create {TUI_GAUGE}.make).with_block ((create {TUI_BLOCK}.make).with_title ("Ratio")).with_label_style (create {STYLE}).
				with_gauge_style (l_style).with_use_unicode (True).with_ratio (0.511_313_934_313_1).render (create {RECT}.make (2, 5, 36, 3), l_buf)
			assert_buffer_lines ("gauges", l_buf, <<
				"                                        ",
				"                                        ",
				{STRING_32} "  %/0x250C/Percentage" + rule (24) + {STRING_32} "%/0x2510/  ",
				{STRING_32} "  %/0x2502/" + blocks (14) + {STRING_32} "%/0x258B/43%%                %/0x2502/  ",
				{STRING_32} "  %/0x2514/" + rule (34) + {STRING_32} "%/0x2518/  ",
				{STRING_32} "  %/0x250C/Ratio" + rule (29) + {STRING_32} "%/0x2510/  ",
				{STRING_32} "  %/0x2502/" + blocks (15) + {STRING_32} "51%%                %/0x2502/  ",
				{STRING_32} "  %/0x2514/" + rule (34) + {STRING_32} "%/0x2518/  ",
				"                                        ",
				"                                        ">>)
			from c := 3 until c > 36 loop
				assert_cell_style ("43: column " + c.out, l_buf, 3, c, l_style)
				if c = 18 or c = 19 then
					assert_cell_style ("51: label over the fill, column " + c.out, l_buf, 6, c, create {STYLE}.make_with_colors ({COLOR}.Blue, {COLOR}.Red))
				else
					assert_cell_style ("51: column " + c.out, l_buf, 6, c, l_style)
				end
				c := c + 1
			end
		end

	test_ratatui_gauge_renders_no_unicode
			-- Ratatui `widgets_gauge_renders_no_unicode`: without Unicode the filled width is
			-- rounded to the nearest cell (34 x 0.43 = 14.62 gives 15; 34 x 0.2113 gives 7).
		local
			l_buf: BUFFER
		do
			create l_buf.make (40, 10);
			(create {TUI_GAUGE}.make).with_block ((create {TUI_BLOCK}.make).with_title ("Percentage")).
				with_percent (43).with_use_unicode (False).render (create {RECT}.make (2, 2, 36, 3), l_buf);
			(create {TUI_GAUGE}.make).with_block ((create {TUI_BLOCK}.make).with_title ("Ratio")).
				with_ratio (0.211_313_934_313_1).with_use_unicode (False).render (create {RECT}.make (2, 5, 36, 3), l_buf)
			assert_buffer_lines ("gauges", l_buf, <<
				"                                        ",
				"                                        ",
				{STRING_32} "  %/0x250C/Percentage" + rule (24) + {STRING_32} "%/0x2510/  ",
				{STRING_32} "  %/0x2502/" + blocks (15) + {STRING_32} "43%%                %/0x2502/  ",
				{STRING_32} "  %/0x2514/" + rule (34) + {STRING_32} "%/0x2518/  ",
				{STRING_32} "  %/0x250C/Ratio" + rule (29) + {STRING_32} "%/0x2510/  ",
				{STRING_32} "  %/0x2502/" + blocks (7) + {STRING_32} "        21%%                %/0x2502/  ",
				{STRING_32} "  %/0x2514/" + rule (34) + {STRING_32} "%/0x2518/  ",
				"                                        ",
				"                                        ">>)
		end

	test_ratatui_gauge_applies_styles
			-- Ratatui `widgets_gauge_applies_styles`: blue on red, 43 %, label "43%" in bold green.
			-- The gauge area is blue on red; the label's "4" is over the filled part, so its
			-- background is the gauge foreground (blue); "3%" is not, so it keeps red.
		local
			l_buf: BUFFER
			l_gauge_style, l_label_style: STYLE
			r, c: INTEGER
		do
			create l_buf.make (12, 5)
			create l_gauge_style.make_with_colors ({COLOR}.Blue, {COLOR}.Red)
			l_label_style := (create {STYLE}.make_fg ({COLOR}.Green)).with_bold;
			(create {TUI_GAUGE}.make).with_block ((create {TUI_BLOCK}.make).with_title ("Test")).
				with_gauge_style (l_gauge_style).with_percent (43).with_label ("43%%").with_label_style (l_label_style).
				render (l_buf.area, l_buf)
			assert_buffer_lines ("gauge", l_buf, <<
				{STRING_32} "%/0x250C/Test" + rule (6) + {STRING_32} "%/0x2510/",
				{STRING_32} "%/0x2502/" + blocks (4) + {STRING_32} "      %/0x2502/",
				{STRING_32} "%/0x2502/" + blocks (3) + {STRING_32} "43%%    %/0x2502/",
				{STRING_32} "%/0x2502/" + blocks (4) + {STRING_32} "      %/0x2502/",
				{STRING_32} "%/0x2514/" + rule (10) + {STRING_32} "%/0x2518/">>)
			from r := 1 until r > 3 loop
				from c := 1 until c > 10 loop
					if r = 2 and c = 4 then
						assert_cell_style ("label over the fill", l_buf, r, c, (create {STYLE}.make_with_colors ({COLOR}.Green, {COLOR}.Blue)).with_bold)
					elseif r = 2 and (c = 5 or c = 6) then
						assert_cell_style ("label after the fill, column " + c.out, l_buf, r, c, (create {STYLE}.make_with_colors ({COLOR}.Green, {COLOR}.Red)).with_bold)
					else
						assert_cell_style ("gauge area (" + r.out + ", " + c.out + ")", l_buf, r, c, l_gauge_style)
					end
					c := c + 1
				end
				r := r + 1
			end
		end

	test_ratatui_gauge_fills_cell_immediately_after_label
			-- Ratatui `widgets_gauge_fills_cell_immediately_after_label` (#2547): a full gauge
			-- 10 wide, label "100%" at columns 3..6; columns 0..2 and 7..9 are full blocks.
		local
			l_buf: BUFFER
		do
			create l_buf.make (10, 1);
			(create {TUI_GAUGE}.make).with_percent (100).with_use_unicode (False).render (l_buf.area, l_buf)
			assert_buffer_lines ("full", l_buf, <<blocks (3) + {STRING_32} "100%%" + blocks (3)>>)
		end

	test_ratatui_gauge_supports_large_labels
			-- Ratatui `widgets_gauge_supports_large_labels`: a label wider than the gauge is cut
			-- to the gauge width, from its start.
		do
			assert_buffer_lines ("cut", large_label_buffer, <<"4333333333">>)
		end

feature -- EiffelTUI cases

	test_gauge_unfilled_part_takes_gauge_background
			-- The EXAMPLE_GAUGE case: black on amber, Unicode, 42 % of 20 columns. Before the fix the
			-- unfilled cells kept the widget style, so the amber track was missing and the black
			-- filled blocks did not show either. Now the 8 filled cells are black blocks on amber,
			-- the fraction cell is the eighth block of the rest on amber, and every unfilled cell
			-- is a blank on amber.
		local
			l_buf: BUFFER
			l_amber: COLOR
			l_style: STYLE
			c: INTEGER
		do
			create l_amber.make_rgb (217, 119, 6)
			create l_style.make_with_colors ({COLOR}.Black, l_amber)
			create l_buf.make (20, 1);
			(create {TUI_GAUGE}.make).with_ratio (0.42).with_use_unicode (True).with_gauge_style (l_style).
				with_label ("").render (l_buf.area, l_buf)
			assert_buffer_lines ("amber track", l_buf, <<blocks (8) + {STRING_32} "%/0x258D/           ">>)
			from c := 0 until c >= 20 loop
				assert_cell_style ("column " + c.out, l_buf, 0, c, l_style)
				c := c + 1
			end
		end

	test_gauge_default_label_is_bold
			-- EiffelTUI's default `label_style` is bold (Ratatui's label has no style): the default
			-- "50%" label of a plain gauge is bold, over the fill and after it.
		local
			l_buf: BUFFER
		do
			create l_buf.make (10, 1)
			(create {TUI_GAUGE}.make).with_ratio (0.5).render (l_buf.area, l_buf)
			assert_buffer_lines ("half", l_buf, <<blocks (3) + {STRING_32} "50%%    ">>)
			assert ("label over the fill is bold", l_buf.cell (0, 3).style.is_bold)
			assert ("label after the fill is bold", l_buf.cell (0, 5).style.is_bold)
			assert ("filled block not bold", not l_buf.cell (0, 0).style.is_bold)
		end

	test_gauge_without_background_keeps_cell_background
			-- A gauge style that sets only a foreground leaves the unfilled cells' background as it
			-- was (here a blue block background): `gauge_style` is patched over the area, as
			-- Ratatui's `Buffer::set_style`. Filled cells get Reset as their background, as Ratatui
			-- sets `bg (Reset)` when the gauge has none.
		local
			l_buf: BUFFER
		do
			create l_buf.make (10, 1);
			(create {TUI_GAUGE}.make).with_style (create {STYLE}.make_bg ({COLOR}.Blue)).
				with_gauge_style (create {STYLE}.make_fg ({COLOR}.Green)).with_ratio (0.5).with_label ("").
				render (l_buf.area, l_buf)
			assert_buffer_lines ("half", l_buf, <<blocks (5) + {STRING_32} "     ">>)
			assert_cell_style ("filled", l_buf, 0, 0, create {STYLE}.make_with_colors ({COLOR}.Green, {COLOR}.Reset_color))
			assert_cell_style ("unfilled", l_buf, 0, 7, create {STYLE}.make_with_colors ({COLOR}.Green, {COLOR}.Blue))
		end

feature {NONE} -- Helpers

	large_label_buffer: BUFFER
			-- 10 x 1 gauge at 43 % with a 30-character label
		do
			create Result.make (10, 1);
			(create {TUI_GAUGE}.make).with_percent (43).with_label ("43333333333333333333333333333%%").render (Result.area, Result)
		end

	blocks (a_count: INTEGER): STRING_32
			-- `a_count` full blocks
		do
			create Result.make_filled ('%/0x2588/', a_count)
		end

	rule (a_count: INTEGER): STRING_32
			-- `a_count` horizontal box lines
		do
			create Result.make_filled ('%/0x2500/', a_count)
		end

end
