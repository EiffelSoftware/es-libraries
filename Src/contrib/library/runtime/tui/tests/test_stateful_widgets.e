note
	description: "[
		Test set for Phase 6: TERMINAL, FRAME, LIST_STATE, TUI_LIST,
		TABS_STATE, and TUI_TABS.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_STATEFUL_WIDGETS

inherit
	EQA_TEST_SET

feature -- Test routines

	test_terminal_and_frame_agent_draw
			-- Test agent-based draw pass via TERMINAL and FRAME.
		local
			l_vt: VIRTUAL_TERMINAL
			l_term: TERMINAL [VIRTUAL_TERMINAL]
			l_block: TUI_BLOCK
		do
			create l_vt.make (20, 5)
			create l_term.make (l_vt)
			assert ("term width 20", l_term.width = 20)
			assert ("term height 5", l_term.height = 5)

			create l_block.make
			l_block.set_title_string ("Box")

			-- Execute draw pass using inline agent
			l_term.draw (agent (f: FRAME; b: TUI_BLOCK)
				do
					f.render_widget (b, f.area)
				end (?, l_block))

			-- Verify on the underlying virtual terminal backend that box was serialized
			assert ("vt top-left corner", l_vt.cell (0, 0).code = 9484) -- '┌'
			assert ("vt title char B", l_vt.cell (0, 1) = 'B')
			assert ("vt title char o", l_vt.cell (0, 2) = 'o')
			assert ("vt title char x", l_vt.cell (0, 3) = 'x')
		end

	test_list_state_navigation
			-- Test LIST_STATE selection movement and clamping.
		local
			l_st: LIST_STATE
		do
			create l_st.make
			assert ("no initial selection", not l_st.has_selection)
			assert ("initial offset 1", l_st.offset = 1)

			-- First next selects 1
			l_st.select_next (5)
			assert ("selected 1", l_st.has_selection and l_st.selected = 1)

			-- Move down
			l_st.select_next (5)
			assert ("selected 2", l_st.selected = 2)
			l_st.select_next (5)
			assert ("selected 3", l_st.selected = 3)
			l_st.select_next (5)
			assert ("selected 4", l_st.selected = 4)
			l_st.select_next (5)
			assert ("selected 5", l_st.selected = 5)
			-- Clamps at 5
			l_st.select_next (5)
			assert ("clamped at 5", l_st.selected = 5)

			-- Move up
			l_st.select_previous (5)
			assert ("selected 4", l_st.selected = 4)
			l_st.select_first
			assert ("select first is 1", l_st.selected = 1)
			l_st.select_previous (5)
			assert ("clamped at 1", l_st.selected = 1)

			l_st.select_last (5)
			assert ("select last is 5", l_st.selected = 5)

			l_st.unselect
			assert ("unselected", not l_st.has_selection and l_st.selected = 0)
		end

	test_list_viewport_scrolling
			-- Test LIST_STATE adjust_viewport scrolling logic.
		local
			l_st: LIST_STATE
		do
			create l_st.make
			-- 10 items, 3 visible rows
			l_st.select_index (1)
			l_st.adjust_viewport (3, 10)
			assert ("offset is 1", l_st.offset = 1)

			l_st.select_index (3)
			l_st.adjust_viewport (3, 10)
			assert ("item 3 fits in 3-row view", l_st.offset = 1)

			l_st.select_index (4)
			l_st.adjust_viewport (3, 10)
			assert ("item 4 scrolls view to offset 2", l_st.offset = 2)

			l_st.select_index (10)
			l_st.adjust_viewport (3, 10)
			assert ("item 10 scrolls view to offset 8", l_st.offset = 8)

			-- Scroll back up
			l_st.select_index (5)
			l_st.adjust_viewport (3, 10)
			assert ("item 5 scrolls view up to offset 5", l_st.offset = 5)
		end

	test_tui_list_stateful_rendering
			-- Test TUI_LIST rendering with highlight symbol and styles.
		local
			l_list: TUI_LIST
			l_st: LIST_STATE
			l_buf: BUFFER
			l_area: RECT
			l_hl_style: STYLE
		do
			create l_list.make_empty
			l_list.append_raw_item ("Apple")
			l_list.append_raw_item ("Banana")
			l_list.append_raw_item ("Cherry")

			create l_hl_style.make_fg ({COLOR}.bright_cyan)
			l_hl_style := l_hl_style.with_bold
			l_list.set_highlight_style (l_hl_style)
			l_list.set_highlight_symbol ("> ")

			create l_st.make
			l_st.select_index (2) -- Banana

			create l_buf.make (20, 5)
			create l_area.make (0, 0, 20, 5)
			l_list.render_list (l_area, l_buf, l_st)

			-- Row 0: "Apple" (indented by 2 spaces because of "> ")
			assert ("row 0 col 0 space", l_buf.cell (0, 0).symbol.same_string_general (" "))
			assert ("row 0 col 1 space", l_buf.cell (0, 1).symbol.same_string_general (" "))
			assert ("row 0 col 2 A", l_buf.cell (0, 2).symbol.same_string_general ("A"))

			-- Row 1: Selected "Banana" has highlight symbol "> "
			assert ("row 1 col 0 >", l_buf.cell (1, 0).symbol.same_string_general (">"))
			assert ("row 1 col 1 space", l_buf.cell (1, 1).symbol.same_string_general (" "))
			assert ("row 1 col 2 B", l_buf.cell (1, 2).symbol.same_string_general ("B"))
			assert ("row 1 style bold", l_buf.cell (1, 2).style.flags.is_bold)
			assert ("row 1 style fg cyan", l_buf.cell (1, 2).style.foreground.ansi_code = 14)

			-- Row 2: "Cherry"
			assert ("row 2 col 2 C", l_buf.cell (2, 2).symbol.same_string_general ("C"))
		end

	test_tabs_state_and_rendering
			-- Test TABS_STATE cycling and TUI_TABS layout with divider.
		local
			l_ts: TABS_STATE
			l_tabs: TUI_TABS
			l_buf: BUFFER
			l_area: RECT
			l_hl_style: STYLE
		do
			create l_ts.make
			assert ("initial tab 1", l_ts.selected = 1)
			l_ts.select_next (3)
			assert ("next tab 2", l_ts.selected = 2)
			l_ts.select_next (3)
			assert ("next tab 3", l_ts.selected = 3)
			l_ts.select_next (3)
			assert ("wrapped to tab 1", l_ts.selected = 1)
			l_ts.select_previous (3)
			assert ("previous wrapped to tab 3", l_ts.selected = 3)

			-- TUI_TABS rendering
			create l_tabs.make_from_strings (<<"Overview", "Logs", "Help">>)
			create l_hl_style.make_fg ({COLOR}.bright_yellow)
			l_hl_style := l_hl_style.with_bold
			l_tabs.set_highlight_style (l_hl_style)
			l_tabs.set_divider (" | ")

			l_ts.select_index (2) -- "Logs"

			create l_buf.make (30, 1)
			create l_area.make (0, 0, 30, 1)
			l_tabs.render_tabs (l_area, l_buf, l_ts.selected)

			-- Layout: "Overview | Logs | Help"
			-- Overview is 8 chars, divider " | " is 3 chars, Logs starts at col 11
			assert ("char O", l_buf.cell (0, 0).symbol.same_string_general ("O"))
			assert ("divider pipe", l_buf.cell (0, 9).symbol.same_string_general ("|"))
			assert ("char L", l_buf.cell (0, 11).symbol.same_string_general ("L"))
			-- "Logs" is highlighted
			assert ("Logs bold", l_buf.cell (0, 11).style.flags.is_bold)
			assert ("Logs fg yellow", l_buf.cell (0, 11).style.foreground.ansi_code = 11)
		end

end
