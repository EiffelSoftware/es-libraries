note
	description: "[
		EXAMPLE_FORM_CONTROLS (P2 W1-W3 review, defect #3): TUI_DIVIDER, TUI_CHECKBOX (with a
		radio group) and TUI_SLIDER in both directions in a real application. Row-exact
		snapshots before and after keys, the Preview section following the checkboxes (wrap, line
		numbers, bold headings) and the theme; the hit regions of each control (only its own
		cells); and a scripted mouse run through the real event loop on a fixed viewport away
		from the screen's origin: clicks toggle, select and miss beside a label, a press on a
		track jumps there and a drag past its end stops at the maximum.

		Expected rows are written with `bar`: '=' U+2501, '~' U+2500, '!' U+2503, '|' U+2502,
		'@' U+25CF and '*' the radio bullet U+2022 (letters that are not in the dialog's text).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_FORM_CONTROLS_EXAMPLE

inherit
	BUFFER_TEST_HELPER

feature -- Tests

	test_form_controls_example_snapshot
			-- The 64 x 20 dialog, row-exact, in the dark theme with "Wrap lines" focused (in the
			-- theme's highlight: its symbol and label only), then after Space, Tab to the volume
			-- slider, Right, End, Tab to the gain slider, Page Up, Down, Shift+Tab twice to
			-- "Light" and Space, which switches the whole dialog to the light theme. The preview
			-- wraps its long line, then cuts it once "Wrap lines" is off.
		local
			l_app: FORM_CONTROLS_SNAPSHOT_APP
			l_buf: BUFFER
			l_frame: FRAME
			l_dark, l_light: TUI_THEME
			i: INTEGER
		do
			l_dark := {TUI_THEME}.dark
			l_light := {TUI_THEME}.light
			l_app := new_snapshot_app
			create l_buf.make (64, 20)
			create l_frame.make (l_buf)
			l_app.render_now (l_frame)
			assert_buffer_lines ("start", l_buf, <<
				frame_row ("top"),
				frame_row ("help"),
				bar ("|~ Options ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  ~ Gain ~~~~~~~~~|"),
				bar ("| [x] Wrap lines                                0 dB           |"),
				bar ("| [ ] Show line numbers                         |              |"),
				bar ("| [x] Bold headings                             |              |"),
				bar ("|~ Theme ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~   |              |"),
				bar ("| (*) Dark                                      @              |"),
				bar ("| ( ) Light                                     !              |"),
				bar ("|~ Volume ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~   !              |"),
				bar ("| ===================@~~~~~~~~~~~~~~~~~~ 50%%    !              |"),
				bar ("|                                               !              |"),
				bar ("|~ Preview " + repeated_8 ('~', 52) + "|"),
				bar (boxed (" # Release notes")),
				bar (boxed (" Sliders, checkboxes and dividers join the widget set, each")),
				bar (boxed (" with its own hit region.")),
				bar (boxed (" ## Fixes")),
				bar (boxed (" Labels are never cut.")),
				bar ("|wrap on, numbers off, bold on, dark, volume 50%%, gain 0 dB    |"),
				frame_row ("bottom")>>)
			assert ("buffer consistent", l_buf.is_consistent)
			assert ("wrap focused", l_app.is_focused_id (1))
			assert ("dark selected", l_app.palette ~ l_dark)
			assert_cell_style ("dark background", l_buf, 11, 5, l_dark.base)
			assert_cell_style ("dark border", l_buf, 5, 0, l_dark.base.patch (l_dark.primary))
			assert_cell_style ("dark rule", l_buf, 6, 30, l_dark.base.patch (l_dark.border))
			assert_cell_style ("focused symbol highlighted", l_buf, 3, 2, l_dark.base.patch (l_dark.highlight))
			assert_cell_style ("focused label end highlighted", l_buf, 3, 15, l_dark.base.patch (l_dark.highlight))
			assert_cell_style ("beside the focused label untouched", l_buf, 3, 16, l_dark.base)
			assert_cell_style ("other box not highlighted", l_buf, 4, 2, l_dark.base)
			assert_cell_style ("dark volume filled", l_buf, 10, 2, l_dark.base.patch (l_dark.success))
			assert_cell_style ("dark status", l_buf, 18, 1, l_dark.base.patch (l_dark.success))
			assert_cell_style ("dark help", l_buf, 1, 1, l_dark.base.patch (l_dark.text))
			assert_cell_style ("bold heading", l_buf, 13, 2, l_dark.base.patch (l_dark.primary.with_bold))
			assert_cell_style ("body text", l_buf, 14, 2, l_dark.base.patch (l_dark.text))

				-- Hit regions: each control's own cells
			assert ("wrap symbol hit", attached l_frame.hit_map.hit (2, 3) as id and then id.value = 1)
			assert ("wrap label end hit", attached l_frame.hit_map.hit (15, 3) as id and then id.value = 1)
			assert ("beside the wrap label misses", l_frame.hit_map.hit (16, 3) = Void)
			assert ("numbers hit", attached l_frame.hit_map.hit (22, 4) as id and then id.value = 2)
			assert ("beside numbers misses", l_frame.hit_map.hit (30, 4) = Void)
			assert ("light hit", attached l_frame.hit_map.hit (2, 8) as id and then id.value = 5)
			assert ("volume track hit", attached l_frame.hit_map.hit (10, 10) as id and then id.value = 6)
			assert ("volume label hit", attached l_frame.hit_map.hit (41, 10) as id and then id.value = 6)
			assert ("below the volume track misses", l_frame.hit_map.hit (10, 11) = Void)
			assert ("gain label hit", attached l_frame.hit_map.hit (48, 3) as id and then id.value = 7)
			assert ("gain track hit", attached l_frame.hit_map.hit (48, 11) as id and then id.value = 7)
			assert ("right of the gain label misses", l_frame.hit_map.hit (60, 8) = Void)
			assert ("divider is no region", l_frame.hit_map.hit (10, 2) = Void)

				-- Keys
			l_app.process_now (char_key (' '))
			from i := 1 until i > 5 loop
				l_app.process_now (create {KEY_EVENT}.make_special ({KEY_CODE}.Tab))
				i := i + 1
			end
			assert ("volume focused", l_app.is_focused_id (6))
			l_app.process_now (create {KEY_EVENT}.make_special ({KEY_CODE}.Right))
			assert ("one step", l_app.volume.value = 55)
			l_app.process_now (create {KEY_EVENT}.make_special ({KEY_CODE}.End_key))
			l_app.process_now (create {KEY_EVENT}.make_special ({KEY_CODE}.Tab))
			assert ("gain focused", l_app.is_focused_id (7))
			l_app.process_now (create {KEY_EVENT}.make_special ({KEY_CODE}.Page_up))
			l_app.process_now (create {KEY_EVENT}.make_special ({KEY_CODE}.Down))
			l_app.process_now (create {KEY_EVENT}.make_special ({KEY_CODE}.Back_tab))
			l_app.process_now (create {KEY_EVENT}.make_special ({KEY_CODE}.Back_tab))
			assert ("light focused", l_app.is_focused_id (5))
			l_app.process_now (char_key (' '))
			assert ("values", not l_app.options [1] and l_app.theme = 2 and l_app.volume.value = 100 and l_app.gain.value = 9)
			create l_buf.make (64, 20)
			create l_frame.make (l_buf)
			l_app.render_now (l_frame)
			assert_buffer_lines ("after keys", l_buf, <<
				frame_row ("top"),
				frame_row ("help"),
				bar ("|~ Options ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  ~ Gain ~~~~~~~~~|"),
				bar ("| [ ] Wrap lines                                +9 dB          |"),
				bar ("| [ ] Show line numbers                         |              |"),
				bar ("| [x] Bold headings                             @              |"),
				bar ("|~ Theme ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~   !              |"),
				bar ("| ( ) Dark                                      !              |"),
				bar ("| (*) Light                                     !              |"),
				bar ("|~ Volume ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~   !              |"),
				bar ("| =====================================@ 100%%   !              |"),
				bar ("|                                               !              |"),
				bar ("|~ Preview " + repeated_8 ('~', 52) + "|"),
				bar (boxed (" # Release notes")),
				bar (boxed (" Sliders, checkboxes and dividers join the widget set, each wi")),
				bar (boxed (" ## Fixes")),
				bar (boxed (" Labels are never cut.")),
				bar (boxed ("")),
				bar ("|wrap off, numbers off, bold on, light, volume 100%%, gain +9 dB|"),
				frame_row ("bottom")>>)
			assert ("light selected", l_app.palette ~ l_light)
			assert_cell_style ("light background", l_buf, 11, 5, l_light.base)
			assert_cell_style ("light border", l_buf, 5, 0, l_light.base.patch (l_light.primary))
			assert_cell_style ("light rule", l_buf, 6, 30, l_light.base.patch (l_light.border))
			assert_cell_style ("light option highlighted", l_buf, 8, 2, l_light.base.patch (l_light.highlight))
			assert_cell_style ("wrap no longer highlighted", l_buf, 3, 2, l_light.base)
			assert_cell_style ("light volume filled", l_buf, 10, 2, l_light.base.patch (l_light.success))
			assert_cell_style ("light status", l_buf, 18, 1, l_light.base.patch (l_light.success))
			assert_cell_style ("light help", l_buf, 1, 1, l_light.base.patch (l_light.text))
			assert_cell_style ("light checkbox label", l_buf, 4, 8, l_light.base)
			assert_cell_style ("light slider label", l_buf, 10, 41, l_light.base)
			assert_cell_style ("light gain track", l_buf, 4, 48, l_light.base)
			assert_cell_style ("light gain filled", l_buf, 7, 48, l_light.base.patch (l_light.info))
			assert ("the themes differ", not l_dark.base.is_equal (l_light.base))
		end

	test_form_controls_example_mouse
			-- The real event loop on a fixed viewport at screen (10, 3): a click on the end of
			-- "Show line numbers" checks it; a click beside it misses; a click on the "Light"
			-- symbol selects it; a press on the volume track at its 20th cell jumps to 50 and a
			-- drag past the end, off the track's row, stops at 100; a press on the bottom of the
			-- gain track sets its minimum; q quits. The preview then shows line numbers.
		local
			l_app: FORM_CONTROLS_SNAPSHOT_APP
			l_buf: BUFFER
			l_frame: FRAME
		do
				-- SGR reports are 1-based screen positions: frame (c, r) is (c + 11; r + 4)
			l_app := new_scripted_app (
				press_release (20, 4) +		-- "Show line numbers", last letter
				press_release (30, 4) +		-- beside it: misses
				press_release (2, 8) +		-- "Light" symbol
				Esc + "[<0;" + (21 + 11).out + ";" + (10 + 4).out + "M" +		-- volume track, cell 19
				Esc + "[<32;" + (60 + 11).out + ";" + (12 + 4).out + "M" +	-- drag past the end
				Esc + "[<0;" + (60 + 11).out + ";" + (12 + 4).out + "m" +		-- release
				press_release (48, 11) +		-- bottom of the gain track
				"q",
				create {VIEWPORT}.make_fixed (create {RECT}.make (10, 3, 64, 20)))
			l_app.run
			assert ("numbers checked", l_app.options [2])
			assert ("wrap and bold unchanged", l_app.options [1] and l_app.options [3])
			assert ("light selected", l_app.theme = 2)
			assert ("volume dragged to the end", l_app.volume.value = 100)
			assert ("gain at its minimum", l_app.gain.value = -12)
			assert ("gain focused", l_app.is_focused_id (7))
				-- The preview now has line numbers, a blank gutter on the wrapped row, and bold
				-- headings, in the light theme
			create l_buf.make (64, 20)
			create l_frame.make (l_buf)
			l_app.render_now (l_frame)
			assert_rows ("preview", l_buf, 13, <<
				bar (boxed ("  1 | # Release notes")),
				bar (boxed ("  2 | Sliders, checkboxes and dividers join the widget set,")),
				bar (boxed ("    | each with its own hit region.")),
				bar (boxed ("  3 | ## Fixes")),
				bar (boxed ("  4 | Labels are never cut."))>>)
			assert_cell_style ("gutter muted", l_buf, 13, 3, {TUI_THEME}.light.base.patch ({TUI_THEME}.light.muted))
			assert_cell_style ("bold heading", l_buf, 13, 7, {TUI_THEME}.light.base.patch ({TUI_THEME}.light.primary.with_bold))
		end

feature {NONE} -- Helpers

	new_snapshot_app: FORM_CONTROLS_SNAPSHOT_APP
			-- The example on a fake console, not running.
		local
			l_backend: ANSI_TERMINAL_BACKEND
		do
			create l_backend.make_with_driver_and_sink (create {FAKE_CONSOLE_DRIVER}, create {STRING_32}.make_empty)
			create Result.make_on (create {TERMINAL [ANSI_TERMINAL_BACKEND]}.make_with_viewport (l_backend, create {VIEWPORT}.make_fullscreen))
		end

	new_scripted_app (a_input: READABLE_STRING_8; a_viewport: VIEWPORT): FORM_CONTROLS_SNAPSHOT_APP
			-- The example on a fake console replaying `a_input`, output captured.
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_sink: STRING_32
			l_backend: ANSI_TERMINAL_BACKEND
		do
			create l_driver
			l_driver.script (a_input)
			create l_sink.make_empty
			l_driver.watch_sink (l_sink)
			create l_backend.make_with_driver_and_sink (l_driver, l_sink)
			create Result.make_on (create {TERMINAL [ANSI_TERMINAL_BACKEND]}.make_with_viewport (l_backend, a_viewport))
			Result.event_thread.set_poll_interval (5)
		end

	press_release (a_column, a_row: INTEGER): STRING_8
			-- SGR press and release of the left button at frame (`a_column`, `a_row`) of a
			-- viewport at screen (10, 3)
		do
			Result := Esc + "[<0;" + (a_column + 11).out + ";" + (a_row + 4).out + "M"
				+ Esc + "[<0;" + (a_column + 11).out + ";" + (a_row + 4).out + "m"
		end

	char_key (a_char: CHARACTER_32): KEY_EVENT
			-- Press of `a_char`
		do
			create Result.make_char (a_char)
		end

	frame_row (a_which: STRING): STRING_32
			-- The dialog's top border with its title, its bottom border, or its help row
		do
			if a_which ~ "top" then
				Result := {STRING_32} "%/0x256D/" + repeated ('%/0x2500/', 23) + {STRING_32} " Form Controls "
					+ repeated ('%/0x2500/', 24) + {STRING_32} "%/0x256E/"
			elseif a_which ~ "bottom" then
				Result := {STRING_32} "%/0x2570/" + repeated ('%/0x2500/', 62) + {STRING_32} "%/0x256F/"
			else
				Result := bar ("|Tab: focus  Space/click: toggle  Arrows/drag: slide  Esc: quit|")
			end
		end

	assert_rows (a_tag: STRING; a_buf: BUFFER; a_first: INTEGER; a_lines: ARRAY [STRING_32])
			-- Rows `a_first` ... of `a_buf` are `a_lines`.
		local
			i: INTEGER
		do
			from i := a_lines.lower until i > a_lines.upper loop
				assert (a_tag + " row " + (a_first + i - a_lines.lower).out,
					buffer_row_as_string (a_buf, a_first + i - a_lines.lower).same_string (a_lines [i]))
				i := i + 1
			end
		end

	boxed (a_inner: STRING): STRING
			-- `a_inner` padded with blanks to the dialog's 62 inner columns, between '|' borders
		require
			fits: a_inner.count <= 62
		do
			Result := "|" + a_inner + create {STRING}.make_filled (' ', 62 - a_inner.count) + "|"
		end

	repeated_8 (a_char: CHARACTER_8; a_count: INTEGER): STRING
			-- `a_count` times `a_char`
		do
			create Result.make_filled (a_char, a_count)
		end

	repeated (a_char: CHARACTER_32; a_count: INTEGER): STRING_32
			-- `a_count` times `a_char`
		do
			create Result.make_filled (a_char, a_count)
		end

	bar (a_pattern: STRING): STRING_32
			-- `a_pattern` with '=' as U+2501, '~' as U+2500, '!' as U+2503, '|' as U+2502, '@'
			-- as U+25CF and '*' as U+2022; other characters as they are.
		local
			i: INTEGER
		do
			create Result.make (a_pattern.count)
			from i := 1 until i > a_pattern.count loop
				inspect a_pattern [i]
				when '=' then Result.append_character ((0x2501).to_character_32)
				when '~' then Result.append_character ((0x2500).to_character_32)
				when '!' then Result.append_character ((0x2503).to_character_32)
				when '|' then Result.append_character ((0x2502).to_character_32)
				when '@' then Result.append_character ((0x25CF).to_character_32)
				when '*' then Result.append_character ((0x2022).to_character_32)
				else
					Result.append_character (a_pattern [i].to_character_32)
				end
				i := i + 1
			end
		end

	Esc: STRING_8 = "%/27/"
			-- ESC, for scripted input

end
