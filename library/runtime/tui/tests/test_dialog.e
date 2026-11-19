note
	description: "[
		P2b item U2, TUI_DIALOG + DIALOG_STATE + DIALOG_KIND
		(review/p2b_clipboard_dialog_breadcrumb_plan.md). Ratatui has no dialog widget, so these
		are EiffelTUI's own row-exact buffer snapshots: an alert, a confirm and three buttons;
		a long message wrapped; frames too small at three heights (message cut, then box cut,
		button row kept) and too narrow (labels cut equally); wide characters; the four kinds'
		border styles from the dark theme. Then the keys (Tab / Shift+Tab / Left / Right wrap,
		Enter and Space, Esc with and without `cancel_button`, first letters, a shared first
		letter), the mouse (a click on each button; the background blocked, through
		FRAME's hit map and through TUI_APPLICATION.hit_test), and the focus scope (pushed
		exactly while open, Tab never leaves, `answered_action` called once and able to
		reopen the dialog).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_DIALOG

inherit
	BUFFER_TEST_HELPER

feature -- Layout

	test_dialog_alert_snapshot
			-- An alert "Saved." titled "Note": 10 x 5, centred in 20 x 7; the message centred,
			-- a blank row, "[ OK ]" focused (reversed), the dimmed shadow keeps the symbols.
		local
			l_frame: FRAME
			s: DIALOG_STATE
		do
			create s.make_alert
			s.open
			l_frame := render ((create {TUI_DIALOG}).with_title ("Note").with_message (create {TEXT}.make_raw ("Saved.")), s, 20, 7)
			assert_buffer_lines ("alert", l_frame.buffer, <<
				"                    ",
				glyphs ("     {--Note--}     "),
				glyphs ("     | Saved. |     "),
				glyphs ("     |        |     "),
				glyphs ("     | [ OK ] |     "),
				glyphs ("     `--------^     "),
				"                    ">>)
			assert_cell_style ("OK focused", l_frame.buffer, 4, 7, (create {STYLE}).with_reverse)
			assert_cell_style ("OK label focused", l_frame.buffer, 4, 9, (create {STYLE}).with_reverse)
			assert_cell_style ("pad not focused", l_frame.buffer, 4, 6, create {STYLE})
			assert ("box", (create {TUI_DIALOG}).with_title ("Note").with_message (create {TEXT}.make_raw ("Saved."))
				.box_area (l_frame.area, s) ~ create {RECT}.make (5, 1, 10, 5))
				-- Closed: nothing drawn
			s.answer_with (1)
			l_frame := render ((create {TUI_DIALOG}).with_message (create {TEXT}.make_raw ("Saved.")), s, 20, 7)
			assert_buffer_lines ("closed draws nothing", l_frame.buffer, <<"                    ", "                    ">>)
			assert ("closed registers nothing", l_frame.hit_map.count = 0)
		end

	test_dialog_confirm_snapshot
			-- Yes / No under "Delete report.txt?": the row (15) centred in the 18 columns of the
			-- message, two columns apart; No (the default) focused.
		local
			l_frame: FRAME
			s: DIALOG_STATE
			l_dialog: TUI_DIALOG
			l_areas: ARRAYED_LIST [RECT]
		do
			create s.make_confirm
			s.open
			l_dialog := (create {TUI_DIALOG}).with_title ("Confirm").with_message (create {TEXT}.make_raw ("Delete report.txt?"))
			l_frame := render (l_dialog, s, 30, 7)
			assert_buffer_lines ("confirm", l_frame.buffer, <<
				"                              ",
				glyphs ("    {------Confirm-------}    "),
				glyphs ("    | Delete report.txt? |    "),
				glyphs ("    |                    |    "),
				glyphs ("    |  [ Yes ]  [ No ]   |    "),
				glyphs ("    `--------------------^    ")>>)
			l_areas := l_dialog.button_areas (l_frame.area, s)
			assert ("yes area", l_areas [1] ~ create {RECT}.make (7, 4, 7, 1))
			assert ("no area", l_areas [2] ~ create {RECT}.make (16, 4, 6, 1))
			assert_cell_style ("No focused", l_frame.buffer, 4, 18, (create {STYLE}).with_reverse)
			assert_cell_style ("Yes plain", l_frame.buffer, 4, 9, create {STYLE})
		end

	test_dialog_three_buttons_snapshot
			-- Save / Discard / Cancel: the row (33) is wider than the message, so it sets the
			-- box's width; the message is centred over it.
		local
			l_frame: FRAME
			s: DIALOG_STATE
		do
			create s.make (<<"Save", "Discard", "Cancel">>, 1, 3)
			s.open
			l_frame := render ((create {TUI_DIALOG}).with_message (create {TEXT}.make_raw ("Unsaved changes.")), s, 40, 7)
			assert_buffer_lines ("three", l_frame.buffer, <<
				"                                        ",
				glyphs (" {-----------------------------------}  "),
				glyphs (" |         Unsaved changes.          |  "),
				glyphs (" |                                   |  "),
				glyphs (" | [ Save ]  [ Discard ]  [ Cancel ] |  "),
				glyphs (" `-----------------------------------^  ")>>)
			assert_cell_style ("Save focused", l_frame.buffer, 4, 3, (create {STYLE}).with_reverse)
		end

	test_dialog_long_message_wrapped
			-- With `max_width` 20 the message is wrapped to 16 columns, word by word, each row
			-- centred; the box is as wide as the widest row + 4.
		local
			l_frame: FRAME
			s: DIALOG_STATE
			l_dialog: TUI_DIALOG
		do
			create s.make_alert
			s.open
			l_dialog := (create {TUI_DIALOG}).with_max_width (20)
				.with_message (create {TEXT}.make_raw ("The quick brown fox jumps over the lazy dog"))
			l_frame := render (l_dialog, s, 25, 9)
			assert ("box", l_dialog.box_area (l_frame.area, s) ~ create {RECT}.make (3, 1, 19, 7))
			assert_buffer_lines ("wrapped", l_frame.buffer, <<
				"                         ",
				glyphs ("   {-----------------}   "),
				glyphs ("   | The quick brown |   "),
				glyphs ("   | fox jumps over  |   "),
				glyphs ("   |  the lazy dog   |   "),
				glyphs ("   |                 |   "),
				glyphs ("   |     [ OK ]      |   "),
				glyphs ("   `-----------------^   ")>>)
			assert ("one row in 60", l_dialog.with_max_width (60).box_area (create {RECT}.make (0, 0, 60, 9), s).height = 5)
			assert ("the area limits the wrap too", l_dialog.with_max_width (60).box_area (l_frame.area, s).height = 7)
		end

	test_dialog_small_frames
			-- A two-row message (box 6 rows high) in frames of 5, 3 and 2 rows: the last message
			-- row goes first, then the blank row (box cut to the area), the button row stays
			-- while one row is left inside the borders; at 2 rows only the borders are drawn.
			-- Too narrow a frame cuts every label to the same width, never below one cluster.
		local
			l_frame: FRAME
			s: DIALOG_STATE
			l_dialog: TUI_DIALOG
		do
			create s.make_confirm
			s.open
			l_dialog := (create {TUI_DIALOG}).with_message (create {TEXT}.make_raw ("Quit now?%NUnsaved work is lost."))
			l_frame := render (l_dialog, s, 30, 8)
			assert ("full box", l_dialog.box_area (l_frame.area, s).height = 6)
				-- 5 rows: one message row
			l_frame := render (l_dialog, s, 30, 5)
			assert_buffer_lines ("five rows", l_frame.buffer, <<
				glyphs ("  {-----------------------}   "),
				glyphs ("  |       Quit now?       |   "),
				glyphs ("  |                       |   "),
				glyphs ("  |    [ Yes ]  [ No ]    |   "),
				glyphs ("  `-----------------------^   ")>>)
				-- 3 rows: no message, no blank row, the buttons kept
			l_frame := render (l_dialog, s, 30, 3)
			assert_buffer_lines ("three rows", l_frame.buffer, <<
				glyphs ("  {-----------------------}   "),
				glyphs ("  |    [ Yes ]  [ No ]    |   "),
				glyphs ("  `-----------------------^   ")>>)
			assert ("buttons clickable", l_frame.hit_map.hit (8, 1) ~ s.button_id (1))
				-- 2 rows: the borders only
			l_frame := render (l_dialog, s, 30, 2)
			assert_buffer_lines ("two rows", l_frame.buffer, <<
				glyphs ("  {-----------------------}   "),
				glyphs ("  `-----------------------^   ")>>)
			assert ("no button drawn", across l_dialog.button_areas (l_frame.area, s) as r all r.is_empty end)
				-- Narrow: OK / Cancel need 18 columns
			create s.make_ok_cancel
			s.open
			l_dialog := (create {TUI_DIALOG}).with_message (create {TEXT}.make_raw ("Go?"))
			assert ("whole in 22", same_labels (l_dialog.shown_labels (create {RECT}.make (0, 0, 22, 5), s), <<"OK", "Cancel">>))
			assert ("cut to 2 in 18", same_labels (l_dialog.shown_labels (create {RECT}.make (0, 0, 18, 5), s), <<"OK", "Ca">>))
			assert ("cut to 1 in 16", same_labels (l_dialog.shown_labels (create {RECT}.make (0, 0, 16, 5), s), <<"O", "C">>))
			assert ("never below 1", same_labels (l_dialog.shown_labels (create {RECT}.make (0, 0, 9, 5), s), <<"O", "C">>))
			l_frame := render (l_dialog, s, 18, 5)
			assert_buffer_lines ("cut labels", l_frame.buffer, <<
				glyphs ("{----------------}"),
				glyphs ("|       Go?      |"),
				glyphs ("|                |"),
				glyphs ("| [ OK ]  [ Ca ] |"),
				glyphs ("`----------------^")>>)
			assert ("consistent", l_frame.buffer.is_consistent)
		end

	test_dialog_wide_characters
			-- A message of eight wide characters (16 columns) and labels of wide characters:
			-- the widths are measured in columns; a label cut to one column keeps its first
			-- (wide) character.
		local
			l_frame: FRAME
			s: DIALOG_STATE
			l_dialog: TUI_DIALOG
			l_message, l_yes, l_no: STRING_32
		do
			l_message := {STRING_32} "%/0x65E5/%/0x672C/%/0x8A9E/%/0x306E/%/0x30C6/%/0x30AD/%/0x30B9/%/0x30C8/"
			l_yes := {STRING_32} "%/0x306F/%/0x3044/"
			l_no := {STRING_32} "%/0x3044/%/0x3044/%/0x3048/"
			create s.make (<<l_yes, l_no>>, 2, 2)
			s.open
			l_dialog := (create {TUI_DIALOG}).with_message (create {TEXT}.make_raw (l_message))
			l_frame := render (l_dialog, s, 30, 7)
				-- Row: 8 + 10 + 2 = 20 columns, wider than the message
			assert ("box", l_dialog.box_area (l_frame.area, s) ~ create {RECT}.make (3, 1, 24, 5))
			assert_cell_symbol ("message first", l_frame.buffer, 2, 7, {STRING_32} "%/0x65E5/")
			assert_cell_symbol ("message last", l_frame.buffer, 2, 21, {STRING_32} "%/0x30C8/")
			assert_cell_symbol ("yes label", l_frame.buffer, 4, 7, {STRING_32} "%/0x306F/")
			assert_cell_symbol ("no label", l_frame.buffer, 4, 17, {STRING_32} "%/0x3044/")
			assert ("consistent", l_frame.buffer.is_consistent)
			assert ("cut to the first wide character", same_labels (l_dialog.shown_labels (create {RECT}.make (0, 0, 12, 5), s),
				<<{STRING_32} "%/0x306F/", {STRING_32} "%/0x3044/">>))
			l_frame := render (l_dialog, s, 12, 5)
			assert ("narrow consistent", l_frame.buffer.is_consistent)
		end

	test_dialog_kinds_from_dark_theme
			-- `with_theme (dark)`: the box takes the base style, the border the kind's style
			-- (info, warning, error, primary for a question).
		local
			l_theme: TUI_THEME
			l_dialog: TUI_DIALOG
			l_frame: FRAME
			s: DIALOG_STATE
			l_kinds: ARRAY [NATURAL_8]
			l_styles: ARRAY [STYLE]
			i: INTEGER
		do
			l_theme := {TUI_THEME}.dark
			l_kinds := <<{DIALOG_KIND}.info, {DIALOG_KIND}.warning, {DIALOG_KIND}.error, {DIALOG_KIND}.question>>
			l_styles := <<l_theme.info, l_theme.warning, l_theme.error, l_theme.primary>>
			create s.make_alert
			s.open
			from i := 1 until i > 4 loop
				l_dialog := (create {TUI_DIALOG}).with_theme (l_theme).with_kind (l_kinds [i])
					.with_message (create {TEXT}.make_raw ("Hi"))
				assert ("kind style " + i.out, l_dialog.kind_style (l_kinds [i]) = l_styles [i])
				l_frame := render (l_dialog, s, 20, 7)
				assert_cell_style ("corner " + i.out, l_frame.buffer, 1, 5, l_theme.base.patch (l_styles [i]))
				assert_cell_style ("edge " + i.out, l_frame.buffer, 2, 5, l_theme.base.patch (l_styles [i]))
				assert_cell_style ("inside " + i.out, l_frame.buffer, 2, 7, l_theme.base)
				i := i + 1
			end
			assert ("focused button from highlight", (create {TUI_DIALOG}).with_theme (l_theme).focused_button_style = l_theme.highlight)
		end

feature -- Keys

	test_dialog_keys_move_and_wrap
			-- Tab and Right go to the next button, Shift+Tab (both encodings) and Left to the
			-- previous one, wrapping round; Up is not the dialog's.
		local
			s: DIALOG_STATE
		do
			create s.make (<<"One", "Two", "Three">>, 1, 0)
			s.open
			assert ("default", s.focused_button = 1)
			assert ("tab", s.handle_key (key ({KEY_CODE}.Tab)) and s.focused_button = 2)
			assert ("right", s.handle_key (key ({KEY_CODE}.Right)) and s.focused_button = 3)
			assert ("tab wraps", s.handle_key (key ({KEY_CODE}.Tab)) and s.focused_button = 1)
			assert ("left wraps", s.handle_key (key ({KEY_CODE}.Left)) and s.focused_button = 3)
			assert ("back tab", s.handle_key (key ({KEY_CODE}.Back_tab)) and s.focused_button = 2)
			assert ("shift tab", s.handle_key (create {KEY_EVENT}.make ({KEY_CODE}.Tab,
				create {MODIFIERS}.make_with_bits (1))) and s.focused_button = 1)
			assert ("up unused", not s.handle_key (key ({KEY_CODE}.Up)) and s.focused_button = 1)
			assert ("still open", s.is_open and s.answer = 0)
		end

	test_dialog_keys_answer
			-- Enter and Space answer with the focused button, each button in turn; Esc answers
			-- with `cancel_button`, and is not used when that is 0; a closed dialog uses no key.
		local
			s: DIALOG_STATE
			i: INTEGER
		do
			create s.make (<<"One", "Two", "Three">>, 1, 2)
			from i := 1 until i > 3 loop
				s.open
				s.focus_button (i)
				assert ("enter " + i.out, s.handle_key (key ({KEY_CODE}.Enter)))
				assert ("answer " + i.out, not s.is_open and s.answer = i)
				i := i + 1
			end
			s.open
			s.focus_next
			assert ("space", s.handle_key (create {KEY_EVENT}.make_char (' ')) and s.answer = 2)
			assert ("closed ignores", not s.handle_key (key ({KEY_CODE}.Enter)) and s.answer = 2)
			s.open
			assert ("esc", s.handle_key (key ({KEY_CODE}.Escape)) and s.answer = 2 and not s.is_open)
			s.set_cancel_button (0)
			s.open
			assert ("esc unused without cancel", not s.handle_key (key ({KEY_CODE}.Escape)))
			s.cancel
			assert ("cancel does nothing", s.is_open and s.answer = 0)
				-- The factories' Esc
			create s.make_confirm
			s.open
			assert ("confirm esc is No", s.handle_key (key ({KEY_CODE}.Escape)) and s.answer = 2)
			create s.make_ok_cancel
			s.open
			assert ("ok cancel default OK", s.focused_button = 1)
			s.cancel
			assert ("ok cancel esc is Cancel", s.answer = 2)
		end

	test_dialog_keys_first_letters
			-- y / n answer Yes / No (case ignored); a letter two labels share is no shortcut;
			-- with Ctrl or Alt the letter is not the dialog's.
		local
			s: DIALOG_STATE
		do
			create s.make_confirm
			s.open
			assert ("ctrl+y unused", not s.handle_key (create {KEY_EVENT}.make (create {KEY_CODE}.make_char ('y'),
				create {MODIFIERS}.make_with_bits (2))))
			assert ("alt+y unused", not s.handle_key (create {KEY_EVENT}.make (create {KEY_CODE}.make_char ('y'),
				create {MODIFIERS}.make_with_bits (4))))
			assert ("x unused", not s.handle_key (create {KEY_EVENT}.make_char ('x')) and s.is_open)
			assert ("y", s.handle_key (create {KEY_EVENT}.make_char ('y')) and s.answer = 1)
			s.open
			assert ("N", s.handle_key (create {KEY_EVENT}.make_char ('N')) and s.answer = 2)
			create s.make (<<"Save", "Skip", "Cancel">>, 1, 3)
			assert ("shared initial", s.button_with_initial ('s') = 0)
			s.open
			assert ("s unused", not s.handle_key (create {KEY_EVENT}.make_char ('s')) and s.is_open)
			assert ("c", s.handle_key (create {KEY_EVENT}.make_char ('c')) and s.answer = 3)
		end

feature -- Mouse

	test_dialog_clicks_in_frame
			-- In a frame with a background control rendered first: each button's area hits
			-- its id, the background (outside and inside the box) hits nothing while open,
			-- with or without a focus manager; `click` answers with the button hit; once
			-- closed, the background hits again.
		local
			s: DIALOG_STATE
			l_frame: FRAME
			l_areas: ARRAYED_LIST [RECT]
			f: FOCUS_MANAGER
			i: INTEGER
		do
			from i := 1 until i > 2 loop
				create s.make_confirm
				if i = 2 then
					create f.make
					f.register (id (90))
					s.set_focus_manager (f)
				end
				s.open
				l_frame := render_over_background (s)
				l_areas := (create {TUI_DIALOG}).with_message (create {TEXT}.make_raw ("Delete?")).button_areas (l_frame.area, s)
				assert ("yes hit " + i.out, l_frame.hit_map.hit (l_areas [1].x, l_areas [1].y) ~ s.button_id (1))
				assert ("no hit " + i.out, l_frame.hit_map.hit (l_areas [2].x + 5, l_areas [2].y) ~ s.button_id (2))
				assert ("background blocked " + i.out, l_frame.hit_map.hit (1, 0) = Void)
				assert ("box blocked " + i.out, l_frame.hit_map.hit (8, 3) = Void)
				assert ("handles anything", s.handles (Void) and s.handles (id (90)))
				s.click (id (90))
				assert ("background click ignored " + i.out, s.is_open)
				s.click (Void)
				assert ("void click ignored " + i.out, s.is_open)
				s.click (l_frame.hit_map.hit (l_areas [2].x, l_areas [2].y))
				assert ("no clicked " + i.out, not s.is_open and s.answer = 2)
				s.open
				s.click (s.button_id (1))
				assert ("yes clicked " + i.out, not s.is_open and s.answer = 1)
				l_frame := render_over_background (s)
				assert ("background back " + i.out, l_frame.hit_map.hit (1, 0) ~ id (90))
				assert ("closed handles nothing", not s.handles (s.button_id (1)))
				i := i + 1
			end
		end

	test_dialog_clicks_through_hit_test
			-- The real event loop on a fixed viewport: a click on the background control and
			-- one inside the box off the buttons hit nothing ({TUI_APPLICATION}.hit_test);
			-- one on Yes hits it, and `click` answers Yes.
		local
			l_app: TEST_TUI_APP_IMPL
			l_hits: ARRAYED_LIST [detachable WIDGET_ID]
			s: DIALOG_STATE
			f: FOCUS_MANAGER
		do
			create l_hits.make (3)
			create f.make
			f.register (id (90))
			create s.make_confirm
			s.set_focus_manager (f)
			s.open
				-- Box 19 x 5 at (5, 2) of 30 x 9; Yes at columns 7..13 of row 5. SGR is 1-based.
			l_app := new_app (Esc + "[<0;2;1M" + Esc + "[<0;9;4M" + Esc + "[<0;10;6M" + "q",
				create {VIEWPORT}.make_fixed (create {RECT}.make (0, 0, 30, 9)))
			l_app.set_draw_hook (agent (a_frame: FRAME; a_state: DIALOG_STATE)
				do
					draw_over_background (a_frame, a_state)
				end (?, s))
			l_app.set_mouse_hook (agent (m: MOUSE_EVENT; a: TEST_TUI_APP_IMPL; l: ARRAYED_LIST [detachable WIDGET_ID]; a_state: DIALOG_STATE)
				do
					if m.is_down then
						l.extend (a.hit_test (m))
						if a_state.handles (a.hit_test (m)) then
							a_state.click (a.hit_test (m))
						end
					end
				end (?, l_app, l_hits, s))
			l_app.run
			assert ("three presses", l_hits.count = 3)
			assert ("background blocked", l_hits [1] = Void)
			assert ("box off the buttons", l_hits [2] = Void)
			assert ("yes", attached l_hits [3] as l_id and then l_id ~ s.button_id (1))
			assert ("answered yes", s.answer = 1 and not s.is_open)
			assert ("scope popped", f.scope_depth = 1 and f.is_focused (id (90)))
		end

feature -- Focus

	test_dialog_focus_scope
			-- With a focus manager the scope is pushed exactly while open: `open` pushes it
			-- with the default button focused, Tab (the manager's or the dialog's) never
			-- leaves the buttons, a background id is refused; every closing path (Enter, Esc,
			-- a letter, a click) pops it and gives the background its focus back.
		local
			s: DIALOG_STATE
			f: FOCUS_MANAGER
			i: INTEGER
		do
			create f.make
			f.register (id (90))
			f.register (id (91))
			create s.make_confirm
			s.set_focus_manager (f)
			assert ("closed: no scope", not s.has_scope and f.scope_depth = 1)
			s.open
			assert ("open: scope", s.has_scope and f.scope_depth = 2)
			assert ("default focused", f.is_focused (s.button_id (2)))
			from i := 1 until i > 5 loop
				f.focus_next
				assert ("manager tab trapped " + i.out, f.is_focused (s.button_id (1)) or f.is_focused (s.button_id (2)))
				assert ("dialog tab " + i.out, s.handle_key (key ({KEY_CODE}.Tab)))
				assert ("in sync " + i.out, f.is_focused (s.button_id (s.focused_button)))
				i := i + 1
			end
			assert ("background refused", not f.focus_at (id (91)))
			assert ("enter", s.handle_key (key ({KEY_CODE}.Enter)))
			assert ("popped by enter", not s.has_scope and f.scope_depth = 1 and f.is_focused (id (90)))
			s.open
			assert ("esc", s.handle_key (key ({KEY_CODE}.Escape)) and f.scope_depth = 1)
			s.open
			assert ("letter", s.handle_key (create {KEY_EVENT}.make_char ('y')) and f.scope_depth = 1)
			s.open
			s.click (s.button_id (2))
			assert ("popped by click", f.scope_depth = 1 and f.is_focused (id (90)))
			assert ("innermost", s.is_scope_innermost)
		end

	test_dialog_answered_action
			-- `answered_action` is called once per answer, with the answer, after the state is
			-- closed and the scope popped; it may open the dialog again (a second question),
			-- which pushes a scope again; `answer` is right on every path.
		local
			s: DIALOG_STATE
			f: FOCUS_MANAGER
			l_log: ARRAYED_LIST [STRING]
		do
			create f.make
			f.register (id (90))
			create l_log.make (4)
			create s.make_confirm
			s.set_focus_manager (f)
			s.set_answered_action (agent (a_answer: INTEGER; a_state: DIALOG_STATE; a_focus: FOCUS_MANAGER; a_log: ARRAYED_LIST [STRING])
				do
					a_log.extend (a_answer.out + " " + a_state.is_open.out + " " + a_focus.scope_depth.out)
					if a_answer = 1 and a_log.count = 1 then
							-- "Are you sure?": ask again
						a_state.open
					end
				end (?, s, f, l_log))
			s.open
			assert ("yes", s.handle_key (create {KEY_EVENT}.make_char ('y')))
			assert ("called once, closed, popped", l_log.count = 1 and l_log [1].same_string ("1 False 1"))
			assert ("reopened by the action", s.is_open and s.answer = 0 and f.scope_depth = 2)
			assert ("default focused again", s.focused_button = 2 and f.is_focused (s.button_id (2)))
			s.cancel
			assert ("second answer", l_log.count = 2 and l_log [2].same_string ("2 False 1"))
			assert ("closed after the second", not s.is_open and s.answer = 2 and f.scope_depth = 1)
			assert ("focus back", f.is_focused (id (90)))
		end

	test_dialog_focus_follows_focus_manager
			-- While the scope is open, `focused_button` is the button the focus manager has
			-- focused: the application's own `focus_next` / `focus_at` move it, the dialog draws
			-- that button focused, and Enter answers with it.
		local
			s: DIALOG_STATE
			f: FOCUS_MANAGER
			l_frame: FRAME
			d: TUI_DIALOG
			l_areas: ARRAYED_LIST [RECT]
		do
			create f.make
			f.register (id (90))
			create s.make_confirm
			s.set_focus_manager (f)
			s.open
			assert ("No first", s.focused_button = 2)
			f.focus_next
			assert ("manager moved to Yes", f.is_focused (s.button_id (1)) and s.focused_button = 1)
			create d
			l_frame := render (d, s, 30, 9)
			l_areas := d.button_areas (l_frame.area, s)
			assert ("Yes drawn focused", l_frame.buffer.cell (l_areas [1].y.to_integer_32, l_areas [1].x.to_integer_32).style.is_reversed)
			assert ("No drawn plain", not l_frame.buffer.cell (l_areas [2].y.to_integer_32, l_areas [2].x.to_integer_32).style.is_reversed)
			assert ("focus_at No", f.focus_at (s.button_id (2)) and s.focused_button = 2)
			assert ("focus_at Yes", f.focus_at (s.button_id (1)) and s.focused_button = 1)
			assert ("enter", s.handle_key (key ({KEY_CODE}.Enter)))
			assert ("answered with the manager's button", s.answer = 1 and s.answer_count = 1)
			assert ("closed: own focus", s.focused_button = 1)
		end

	test_dialog_answer_count_and_ids
			-- `answer_count` counts every answer, also with an action; Esc with no cancel
			-- button and a missed click count none. `set_button_ids` gives the application's
			-- ids; `are_valid_ids` refuses a wrong count, Void and duplicates; `are_ids_free`
			-- finds an id already in the focus manager's active scope.
		local
			s: DIALOG_STATE
			f: FOCUS_MANAGER
			l_calls: CELL [INTEGER]
		do
			create l_calls.put (0)
			create s.make_confirm
			s.set_answered_action (agent (a_answer: INTEGER; a_calls: CELL [INTEGER]) do a_calls.put (a_calls.item + 1) end (?, l_calls))
			s.open
			s.cancel
			assert ("counted with an action", s.answer_count = 1 and l_calls.item = 1)
			s.open
			s.click (id (12345))
			assert ("missed click counts none", s.is_open and s.answer_count = 1)
			s.click (s.button_id (1))
			assert ("click counted", s.answer_count = 2 and s.answer = 1)
			s.set_cancel_button (0)
			s.open
			assert ("esc unused", not s.handle_key (key ({KEY_CODE}.Escape)) and s.answer_count = 2 and s.is_open)
			s.answer_with (2)
			assert ("not valid: count", not s.are_valid_ids (<<id (1)>>))
			assert ("not valid: duplicate", not s.are_valid_ids (<<id (1), id (1)>>))
			assert ("valid", s.are_valid_ids (<<id (21), id (22)>>))
			s.set_button_ids (<<id (21), id (22)>>)
			assert ("ids set", s.button_id (1) ~ id (21) and s.button_id (2) ~ id (22) and s.index_of_id (id (22)) = 2)
			assert ("builder", s.with_button_ids (<<id (31), id (32)>>).button_id (2) ~ id (32) and s.button_id (2) ~ id (22))
			create f.make
			f.register (id (90))
			assert ("free", s.are_ids_free (f))
			f.register (id (22))
			assert ("clash found", not s.are_ids_free (f))
			s.set_button_ids (<<id (41), id (42)>>)
			s.set_focus_manager (f)
			s.open
			assert ("open with own ids", s.has_scope and f.is_focused (id (42)))
			s.answer_with (2)
			assert ("popped", f.scope_depth = 1)
		end

	test_dialog_state_and_widget_values
			-- Ids are distinct and negative across states; `copy` takes no scope; builders,
			-- equality.
		local
			s, t, c: DIALOG_STATE
			f: FOCUS_MANAGER
			d: TUI_DIALOG
		do
			create s.make_confirm
			create t.make_confirm
			assert ("negative", s.button_id (1).value < 0)
			assert ("distinct in a state", not (s.button_id (1) ~ s.button_id (2)))
			assert ("distinct across states", t.index_of_id (s.button_id (1)) = 0 and t.index_of_id (s.button_id (2)) = 0)
			assert ("index of id", s.index_of_id (s.button_id (2)) = 2 and s.index_of_id (Void) = 0)
			assert ("default create is an alert", (create {DIALOG_STATE}).button_count = 1)
			assert ("valid label", {DIALOG_STATE}.is_valid_label ("OK") and not {DIALOG_STATE}.is_valid_label ("")
				and not {DIALOG_STATE}.is_valid_label ("A%NB"))
			assert ("with default", s.with_default_button (1).default_button = 1 and s.default_button = 2)
			assert ("with cancel", s.with_cancel_button (0).cancel_button = 0 and s.cancel_button = 2)
			create f.make
			s.set_focus_manager (f)
			s.open
			c := s.twin
			assert ("copy equal", c ~ s)
			assert ("copy takes no scope", not c.has_scope and c.focus_manager = Void and s.has_scope)
			s.cancel
			assert ("original popped", f.scope_depth = 1)
			d := (create {TUI_DIALOG}).with_title ("T").with_max_width (30).with_button_spacing (4)
				.with_kind ({DIALOG_KIND}.error).with_border_type ({BORDER_TYPE}.double).with_shadow (Void)
			assert ("builders", d.max_width = 30 and d.button_spacing = 4 and d.kind = {DIALOG_KIND}.error
				and d.border_type = {BORDER_TYPE}.double and d.shadow = Void)
			assert ("equal copies", d ~ d.twin and not (d ~ d.with_kind ({DIALOG_KIND}.info)))
			assert ("default shadow dimmed", (create {TUI_DIALOG}).shadow = (create {TUI_DIALOG}).Dimmed_shadow)
			assert ("body replaces message", attached (create {TUI_DIALOG}).with_body (create {TUI_CLEAR}).body
				and (create {TUI_DIALOG}).with_body (create {TUI_CLEAR}).with_message (create {TEXT}.make_raw ("x")).body = Void)
		end

feature {NONE} -- Helpers

	render (a_dialog: TUI_DIALOG; a_state: DIALOG_STATE; a_width, a_height: INTEGER): FRAME
			-- A `a_width` x `a_height` frame with `a_dialog` rendered over its whole area
		do
			create Result.make (create {BUFFER}.make (a_width.to_natural_16, a_height.to_natural_16))
			Result.render_stateful_widget (a_dialog, Result.area, a_state)
		end

	render_over_background (a_state: DIALOG_STATE): FRAME
			-- A 30 x 9 frame: a checkbox (id 90) at (0, 0), then the "Delete?" dialog
		do
			create Result.make (create {BUFFER}.make (30, 9))
			draw_over_background (Result, a_state)
		end

	draw_over_background (a_frame: FRAME; a_state: DIALOG_STATE)
			-- A checkbox (id 90) at (0, 0), then the "Delete?" dialog over the whole frame
		local
			b: TUI_CHECKBOX
		do
			create b.make ("Back")
			a_frame.render_widget (b.with_hit_id (id (90)), create {RECT}.make (0, 0, b.width.to_natural_16, 1))
			a_frame.render_stateful_widget ((create {TUI_DIALOG}).with_message (create {TEXT}.make_raw ("Delete?")),
				a_frame.area, a_state)
		end

	key (a_code: KEY_CODE): KEY_EVENT
			-- A press of `a_code`
		do
			create Result.make_special (a_code)
		end

	id (a_value: INTEGER): WIDGET_ID
			-- A new id of `a_value`
		do
			create Result.make (a_value)
		end

	same_labels (a_labels: ARRAYED_LIST [STRING_32]; a_expected: ARRAY [READABLE_STRING_GENERAL]): BOOLEAN
			-- Are `a_labels` exactly `a_expected`?
		local
			i: INTEGER
		do
			Result := a_labels.count = a_expected.count
			from i := 1 until not Result or i > a_labels.count loop
				Result := a_labels [i].same_string_general (a_expected [i])
				i := i + 1
			end
		end

	glyphs (a_pattern: STRING_8): STRING_32
			-- `a_pattern` with '{' U+250C, '}' U+2510, '`' U+2514, '^' U+2518, '-' U+2500 and '|'
			-- U+2502; other characters as they are.
		local
			i: INTEGER
		do
			create Result.make (a_pattern.count)
			from i := 1 until i > a_pattern.count loop
				inspect a_pattern [i]
				when '{' then Result.append_character ((0x250C).to_character_32)
				when '}' then Result.append_character ((0x2510).to_character_32)
				when '`' then Result.append_character ((0x2514).to_character_32)
				when '^' then Result.append_character ((0x2518).to_character_32)
				when '-' then Result.append_character ((0x2500).to_character_32)
				when '|' then Result.append_character ((0x2502).to_character_32)
				else Result.append_character (a_pattern [i].to_character_32)
				end
				i := i + 1
			end
		end

	new_app (a_input: READABLE_STRING_8; a_viewport: VIEWPORT): TEST_TUI_APP_IMPL
			-- Application on a fake console replaying `a_input`, output captured.
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
			create Result.make_with_terminal (create {TERMINAL [ANSI_TERMINAL_BACKEND]}.make_with_viewport (l_backend, a_viewport))
			Result.event_thread.set_poll_interval (5)
		end

	Esc: STRING_8 = "%/27/"
			-- ESC, for scripted input

end
