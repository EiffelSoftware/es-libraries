note
	description: "[
		Comprehensive test suite for Milestone G (Eiffel Ergonomics & Ecosystem):
		- Style immutability & CQS fluent builders
		- BLOCK_CONTAINER shared composition and inner_area deflation
		- Text hierarchy as direct WIDGETs with conversions and width saturation safety
		- Named symbol sets (SYMBOLS_BAR, SYMBOLS_BLOCK, SYMBOLS_MARKER) and TUI_THEME
		- TUI_TEXT_INPUT and TEXT_INPUT_STATE (editing, masking, scrolling, cursor)
		- TUI_POPUP (modal helper, centered_rect, fixed_rect, background clearing)
		- TUI_TREE, TREE_NODE, TREE_STATE (hierarchy, expand/collapse, indent, rendering)
		- TUI_CALENDAR and CALENDAR_STATE (Gregorian math, day of week, grid rendering)
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_MILESTONE_G

inherit
	EQA_TEST_SET
	BUFFER_TEST_HELPER

feature -- Style & CQS Tests

	test_style_immutability_and_cqs
			-- Verify STYLE fluent builders produce modified copies without mutating the original.
		local
			l_orig, l_styled: STYLE
			l_red, l_blue: COLOR
		do
			create l_red.make_ansi (1)
			create l_blue.make_ansi (4)

			create l_orig.default_create
			assert ("orig has no fg", l_orig.foreground.is_default)
			assert ("orig has no bg", l_orig.background.is_default)
			assert ("orig not bold", not l_orig.is_bold)

			l_styled := l_orig.with_fg (l_red).with_bg (l_blue).with_bold.with_italic.with_dim.with_underline.with_reversed

			-- Verify original was unchanged
			assert ("orig still has no fg", l_orig.foreground.is_default)
			assert ("orig still has no bg", l_orig.background.is_default)
			assert ("orig still not bold", not l_orig.is_bold)

			-- Verify new style has all attributes
			assert ("styled has fg", attached l_styled.foreground as fg and then fg.is_equal (l_red))
			assert ("styled has bg", attached l_styled.background as bg and then bg.is_equal (l_blue))
			assert ("styled is bold", l_styled.is_bold)
			assert ("styled is italic", l_styled.is_italic)
			assert ("styled is dim", l_styled.is_dim)
			assert ("styled is underlined", l_styled.is_underlined)
			assert ("styled is reversed", l_styled.is_reversed)
		end

feature -- BLOCK_CONTAINER Tests

	test_block_container_and_inner_area
			-- Verify BLOCK_CONTAINER deflates area with borders and padding.
		local
			l_para: TUI_PARAGRAPH
			l_block: TUI_BLOCK
			l_pad: PADDING
			l_area, l_inner: RECT
		do
			create l_para.make_raw ("Test Paragraph")
			create l_area.make (0, 0, 30, 10)

			-- Without block, inner_area equals input area
			l_inner := l_para.inner_area (l_area)
			assert ("inner equals area without block", l_inner.is_equal (l_area))

			-- With block containing borders and padding
			create l_pad.make_all (2)
			create l_block.make
			l_block := l_block.with_borders ({BORDERS}.all_borders).with_four_sided_padding (l_pad)
			l_para := l_para.with_block (l_block)

			l_inner := l_para.inner_area (l_area)
			-- Borders take 1 cell on each side (2 total), padding takes 2 cells on each side (4 total)
			-- Total width reduction: 6 cells -> 30 - 6 = 24
			-- Total height reduction: 6 cells -> 10 - 6 = 4
			assert ("inner x deflated", l_inner.x = 3)
			assert ("inner y deflated", l_inner.y = 3)
			assert ("inner width deflated", l_inner.width = 24)
			assert ("inner height deflated", l_inner.height = 4)
		end

feature -- Text Hierarchy as Widgets Tests

	test_text_hierarchy_direct_rendering
			-- Verify TEXT_SPAN, TEXT_LINE, and TEXT render directly as widgets.
		local
			l_buf: BUFFER
			l_span: TEXT_SPAN
			l_line: TEXT_LINE
			l_text: TEXT
			l_style: STYLE
			l_cyan: COLOR
		do
			create l_buf.make (30, 5)
			create l_cyan.make_ansi (6)
			create l_style.make_fg (l_cyan)

			-- 1. TEXT_SPAN rendering directly
			create l_span.make ("Span", l_style)
			l_span.render (create {RECT}.make (0, 0, 10, 1), l_buf)
			assert ("span rendered char 1", l_buf.cell (0, 0).symbol.same_string ("S"))
			assert ("span rendered char 2", l_buf.cell (0, 1).symbol.same_string ("p"))
			assert ("span rendered char 3", l_buf.cell (0, 2).symbol.same_string ("a"))
			assert ("span rendered char 4", l_buf.cell (0, 3).symbol.same_string ("n"))

			-- 2. TEXT_LINE rendering directly
			create l_line.make_raw ("Line Text")
			l_line.render (create {RECT}.make (0, 1, 15, 1), l_buf)
			assert ("line rendered char 1", l_buf.cell (1, 0).symbol.same_string ("L"))
			assert ("line rendered char 5", l_buf.cell (1, 4).symbol.same_string (" "))
			assert ("line rendered char 9", l_buf.cell (1, 8).symbol.same_string ("t"))

			-- 3. TEXT rendering directly
			create l_text.make_raw ("Multi%NLine")
			l_text.render (create {RECT}.make (0, 2, 15, 2), l_buf)
			assert ("text line 1", l_buf.cell (2, 0).symbol.same_string ("M"))
			assert ("text line 2", l_buf.cell (3, 0).symbol.same_string ("L"))
		end

feature -- Symbols and Themes Tests

	test_symbols_and_themes
			-- Verify named symbol sets and TUI_THEME palette presets.
		local
			l_sym_bar: SYMBOLS_BAR
			l_sym_block: SYMBOLS_BLOCK
			l_sym_marker: SYMBOLS_MARKER
			l_theme: TUI_THEME
		do
			-- Check vertical fractional bars
			assert ("bar full", l_sym_bar.vertical_full = '%/0x2588/')
			assert ("bar index 1", l_sym_bar.vertical_bar (1) = '%/0x2581/')
			assert ("bar index 8", l_sym_bar.vertical_bar (8) = '%/0x2588/')

			-- Check block symbols
			assert ("half block upper", l_sym_block.upper_half = '%/0x2580/')
			assert ("half block lower", l_sym_block.lower_half = '%/0x2584/')

			-- Check markers
			assert ("marker dot", l_sym_marker.dot = '%/0x2022/')
			assert ("marker check", l_sym_marker.check_mark = '%/0x2714/')

			-- Check themes
			l_theme := {TUI_THEME}.nord
			assert ("nord primary attached", l_theme.primary /= Void)
			assert ("nord text attached", l_theme.text /= Void)

			l_theme := {TUI_THEME}.dracula
			assert ("dracula primary attached", l_theme.primary /= Void)
			assert ("dracula base attached", l_theme.base /= Void)

			l_theme := {TUI_THEME}.dark
			assert ("dark base attached", l_theme.base /= Void)
		end

feature -- TUI_TEXT_INPUT Tests

	test_text_input_editing_and_rendering
			-- Verify TEXT_INPUT_STATE editing and TUI_TEXT_INPUT rendering.
		local
			l_state: TEXT_INPUT_STATE
			l_input: TUI_TEXT_INPUT
			l_buf: BUFFER
			l_area: RECT
		do
			create l_state.make_with_text ("Hello")
			assert ("cursor at end", l_state.cursor_position = 5)
			assert ("value is Hello", l_state.value.same_string ("Hello"))

			l_state.insert_character ('!')
			assert ("value is Hello!", l_state.value.same_string ("Hello!"))
			assert ("cursor at 6", l_state.cursor_position = 6)

			l_state.delete_backward
			assert ("value back to Hello", l_state.value.same_string ("Hello"))

			l_state.move_cursor_home
			assert ("cursor at 0", l_state.cursor_position = 0)

			l_state.insert_string ("Say: ")
			assert ("value is Say: Hello", l_state.value.same_string ("Say: Hello"))

			-- Render input to buffer
			create l_buf.make (20, 1)
			create l_area.make (0, 0, 20, 1)
			create l_input.make
			l_input.render_stateful (l_area, l_buf, l_state)

			assert ("rendered S", l_buf.cell (0, 0).symbol.same_string ("S"))
			assert ("rendered a", l_buf.cell (0, 1).symbol.same_string ("a"))
			assert ("rendered y", l_buf.cell (0, 2).symbol.same_string ("y"))

			-- Test password masking
			l_input := l_input.with_mask_char ('*')
			l_input.render_stateful (l_area, l_buf, l_state)
			assert ("masked * 1", l_buf.cell (0, 0).symbol.same_string ("*"))
			assert ("masked * 2", l_buf.cell (0, 1).symbol.same_string ("*"))
		end

feature -- TUI_POPUP Tests

	test_popup_helpers_and_rendering
			-- Verify TUI_POPUP geometry calculations and rendering with background clearing.
		local
			l_popup: TUI_POPUP
			l_screen, l_centered, l_fixed: RECT
			l_buf: BUFFER
			l_content: TUI_PARAGRAPH
		do
			create l_popup.make
			create l_screen.make (0, 0, 80, 24)

			-- Centered rect 50% x 50%
			l_centered := l_popup.centered_rect (50, 50, l_screen)
			assert ("centered w", l_centered.width = 40)
			assert ("centered h", l_centered.height = 12)
			assert ("centered x", l_centered.x = 20)
			assert ("centered y", l_centered.y = 6)

			-- Fixed rect 30x10
			l_fixed := l_popup.fixed_rect (30, 10, l_screen)
			assert ("fixed w", l_fixed.width = 30)
			assert ("fixed h", l_fixed.height = 10)
			assert ("fixed x", l_fixed.x = 25)
			assert ("fixed y", l_fixed.y = 7)

			-- Rendering popup clears background
			create l_buf.make (20, 5)
			-- Fill with 'X'
			l_buf.put_string (0, 0, "XXXXXXXXXXXXXXXXXXXX", create {STYLE}.default_create)
			l_buf.put_string (1, 0, "XXXXXXXXXXXXXXXXXXXX", create {STYLE}.default_create)

			create l_content.make_raw ("Pop")
			l_popup := l_popup.with_inner_widget (l_content).with_clear_background (True)
			l_popup.render (create {RECT}.make (2, 0, 10, 2), l_buf)

			-- Area outside popup should remain 'X'
			assert ("outside left", l_buf.cell (0, 0).symbol.same_string ("X"))
			assert ("outside right", l_buf.cell (0, 15).symbol.same_string ("X"))
			-- Inner content rendered
			assert ("inner P", l_buf.cell (0, 2).symbol.same_string ("P"))
			assert ("inner o", l_buf.cell (0, 3).symbol.same_string ("o"))
			assert ("inner p", l_buf.cell (0, 4).symbol.same_string ("p"))
			-- Trailing cleared cell inside popup area
			assert ("cleared inside", l_buf.cell (0, 5).symbol.same_string (" "))
		end

feature -- TUI_TREE Tests

	test_tree_navigation_and_rendering
			-- Verify TREE_NODE, TREE_STATE, and TUI_TREE rendering.
		local
			l_root1, l_child1, l_child2: TREE_NODE
			l_tree: TUI_TREE
			l_state: TREE_STATE
			l_buf: BUFFER
			l_area: RECT
		do
			create l_root1.make_with_string ("root", "Root Node")
			create l_child1.make_with_string ("c1", "Child 1")
			create l_child2.make_with_string ("c2", "Child 2")
			l_root1.add_child (l_child1)
			l_root1.add_child (l_child2)

			assert ("root is not leaf", not l_root1.is_leaf)
			assert ("child1 is leaf", l_child1.is_leaf)

			create l_state.make
			assert ("root not expanded initially", not l_state.is_expanded ("root"))

			create l_tree.make
			l_tree := l_tree.with_highlight_symbol ("")
			l_tree.add_root (l_root1)

			create l_buf.make (30, 5)
			create l_area.make (0, 0, 30, 5)

			-- 1. When collapsed: only root is rendered
			l_tree.render_stateful (l_area, l_buf, l_state)
			assert ("collapsed icon", l_buf.cell (0, 0).symbol.same_string (">"))

			-- 2. When expanded: root and children rendered
			l_state.expand_node ("root")
			assert ("root is expanded", l_state.is_expanded ("root"))

			create l_buf.make (30, 5)
			l_tree.render_stateful (l_area, l_buf, l_state)
			assert ("expanded icon", l_buf.cell (0, 0).symbol.same_string ("v"))
			-- Line 1 is Child 1 (depth 1 * indent 2 + leaf_symbol 2 = col 4)
			assert ("child 1 rendered", l_buf.cell (1, 4).symbol.same_string ("C"))
		end

feature -- TUI_CALENDAR Tests

	test_calendar_state_and_rendering
			-- Verify CALENDAR_STATE math and TUI_CALENDAR grid rendering.
		local
			l_cal: TUI_CALENDAR
			l_state: CALENDAR_STATE
			l_buf: BUFFER
			l_area: RECT
		do
			create l_state.make_with_date (2024, 2, 28)
			-- 2024 is a leap year
			assert ("2024 is leap year", l_state.is_leap_year (2024))
			assert ("2024 feb days", l_state.days_in_month (2024, 2) = 29)
			assert ("2023 not leap year", not l_state.is_leap_year (2023))
			assert ("2023 feb days", l_state.days_in_month (2023, 2) = 28)

			-- Navigation test: next_day across leap day
			l_state.next_day
			assert ("leap day selected", l_state.selected_day = 29)
			l_state.next_day
			assert ("march rollover", l_state.month = 3 and l_state.selected_day = 1)

			-- September 2026 test
			create l_state.make_with_date (2026, 9, 27)
			assert ("september month name", l_state.month_name.same_string ("September"))
			-- 2026-09-01 is a Tuesday (weekday 2)
			assert ("first weekday of sep 2026", l_state.first_weekday_of_month = 2)
			-- 2026-09-27 is a Sunday (weekday 7)
			assert ("dow of 2026-09-27", l_state.day_of_week (2026, 9, 27) = 7)

			-- Render calendar
			create l_buf.make (25, 10)
			create l_area.make (0, 0, 25, 10)
			create l_cal.make
			l_cal.render_stateful (l_area, l_buf, l_state)

			-- Line 0: Month Year Header
			-- Line 1: Weekday Header (Mo Tu We Th Fr Sa Su)
			-- Verify weekdays line contains "Mo"
			assert ("has Mo in header", l_buf.cell (1, 2).symbol.same_string ("M") or l_buf.cell (1, 3).symbol.same_string ("M"))
		end

end
