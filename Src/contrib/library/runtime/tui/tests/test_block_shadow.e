note
	description: "[
		P1 item V6, block shadows (review/p1_visualization_plan.md): SHADOW, CELL_EFFECT,
		DIMMED_EFFECT, TUI_BLOCK.shadow and TUI_POPUP.with_shadow.
		The `test_ratatui_*` cases are the tests of Ratatui ratatui-widgets/src/block/shadow.rs,
		as row-exact buffer snapshots with the styles checked cell by cell.
		Coordinates: Ratatui writes buffer[(x, y)]; here cells are (row, column), so Ratatui's
		(2, 1) is row 1, column 2.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_BLOCK_SHADOW

inherit
	BUFFER_TEST_HELPER

feature -- Ratatui shadow.rs

	test_ratatui_overlay_renders_style_without_changing_symbols
			-- Ratatui `overlay_renders_style_without_changing_symbols`: an overlay shadow of the
			-- block (0, 0, 2, 2) on "abcd / efgh / ijkl / mnop" styles the three visible shadow
			-- cells red on blue and keeps every symbol. The block's own cells and the cells
			-- outside the shadow keep the default style.
		local
			l_buf: BUFFER
			l_shadow: SHADOW
		do
			l_buf := buffer_with_lines (<<"abcd", "efgh", "ijkl", "mnop">>)
			l_shadow := (create {SHADOW}.make_overlay).with_style (create {STYLE}.make_with_colors ({COLOR}.Red, {COLOR}.Blue))
			l_shadow.render (create {RECT}.make (0, 0, 2, 2), l_buf)
			assert_buffer_lines ("overlay", l_buf, <<"abcd", "efgh", "ijkl", "mnop">>)
			assert ("g symbol", l_buf.cell (1, 2).symbol.same_string ("g"))
			assert ("j symbol", l_buf.cell (2, 1).symbol.same_string ("j"))
			assert ("k symbol", l_buf.cell (2, 2).symbol.same_string ("k"))
			assert_shadow_styles ("overlay", l_buf, <<[1, 2], [2, 1], [2, 2]>>, {COLOR}.Red, {COLOR}.Blue)
		end

	test_ratatui_symbol_filters_fill_only_visible_shadow_cells
			-- Ratatui `symbol_filters_fill_only_visible_shadow_cells`, cases `Shadow::symbol("$")`
			-- and `Shadow::block()`, plus the three shade presets: on an empty 4 x 4 buffer,
			-- the shadow of (0, 0, 2, 2) fills (2, 1), (1, 2) and (2, 2) only; (1, 1), in the
			-- block, stays a space. The styles stay the default (the shadow style is empty).
		do
			assert_symbol_shadow ("symbol $", create {SHADOW}.make_symbol ('$'), "$")
			assert_symbol_shadow ("block", create {SHADOW}.make_block, {STRING_32} "%/0x2588/")
			assert_symbol_shadow ("light shade", create {SHADOW}.make_light_shade, {STRING_32} "%/0x2591/")
			assert_symbol_shadow ("medium shade", create {SHADOW}.make_medium_shade, {STRING_32} "%/0x2592/")
			assert_symbol_shadow ("dark shade", create {SHADOW}.make_dark_shade, {STRING_32} "%/0x2593/")
		end

	test_ratatui_render_is_clipped_to_buffer
			-- Ratatui `render_is_clipped_to_buffer`: the shadow of (0, 0, 2, 1) on a 3 x 2 buffer
			-- is (1, 1, 2, 1), and its last column is the buffer's last column.
		local
			l_buf: BUFFER
		do
			create l_buf.make (3, 2)
			(create {SHADOW}.make_symbol ('#')).render (create {RECT}.make (0, 0, 2, 1), l_buf)
			assert_buffer_lines ("clipped", l_buf, <<"   ", " ##">>)
				-- Moved past the buffer: cut, nothing outside is written
			create l_buf.make (3, 2)
			(create {SHADOW}.make_symbol ('#')).render (create {RECT}.make (1, 0, 2, 2), l_buf)
			assert_buffer_lines ("cut at the right and bottom", l_buf, <<"   ", "   ">>)
			assert ("consistent", l_buf.is_consistent)
		end

	test_ratatui_custom_filter_is_applied
			-- Ratatui `custom_filter_is_applied`: a custom effect (PLUS_TEST_EFFECT, Ratatui's
			-- `PlusFilter`) writes '+' into the three visible shadow cells.
		local
			l_buf: BUFFER
		do
			create l_buf.make (4, 4)
			(create {SHADOW}.make_custom (create {PLUS_TEST_EFFECT})).render (create {RECT}.make (0, 0, 2, 2), l_buf)
			assert_buffer_lines ("plus", l_buf, <<"    ", "  + ", " ++ ", "    ">>)
		end

	test_ratatui_dimmed_filter_dims_background
			-- Ratatui `dimmed_filter_dims_background`: on an RGB (100, 120, 140) background the
			-- shadow cells get DIM and (50, 60, 70); the block's cell (1, 1) keeps both.
			-- Also a named and a default background, which become black, and the order
			-- "style, then effect": a shadow style's RGB background is the one halved.
		local
			l_buf: BUFFER
			l_shadow: SHADOW
			l_base: RECT
		do
			create l_base.make (0, 0, 2, 2)
			create l_buf.make (4, 4)
			l_buf.set_style (l_buf.area, create {STYLE}.make_bg ({COLOR}.rgb (100, 120, 140)))
			create l_shadow.make_custom (create {DIMMED_EFFECT})
			l_shadow.render (l_base, l_buf)
			assert ("shadow cell dim", l_buf.cell (1, 2).style.is_dim)
			assert ("shadow bg halved", l_buf.cell (1, 2).style.background ~ {COLOR}.rgb (50, 60, 70))
			assert ("all three halved", l_buf.cell (2, 1).style.background ~ {COLOR}.rgb (50, 60, 70)
				and l_buf.cell (2, 2).style.background ~ {COLOR}.rgb (50, 60, 70))
			assert ("block cell bg kept", l_buf.cell (1, 1).style.background ~ {COLOR}.rgb (100, 120, 140))
			assert ("block cell not dim", not l_buf.cell (1, 1).style.is_dim)
			assert ("outside cell not dim", not l_buf.cell (3, 3).style.is_dim
				and l_buf.cell (3, 3).style.background ~ {COLOR}.rgb (100, 120, 140))
			assert_buffer_lines ("symbols kept", l_buf, <<"    ", "    ", "    ", "    ">>)

				-- Named background: black
			l_buf := buffer_with_lines (<<"abcd", "efgh", "ijkl", "mnop">>)
			l_buf.set_style (l_buf.area, create {STYLE}.make_with_colors ({COLOR}.Yellow, {COLOR}.Blue))
			l_shadow.render (l_base, l_buf)
			assert ("named bg becomes black", l_buf.cell (1, 2).style.background ~ {COLOR}.Black and l_buf.cell (1, 2).style.is_dim)
			assert ("fg kept", l_buf.cell (1, 2).style.foreground ~ {COLOR}.Yellow)
			assert ("named block cell kept", l_buf.cell (1, 1).style.background ~ {COLOR}.Blue)
			assert_buffer_lines ("named symbols kept", l_buf, <<"abcd", "efgh", "ijkl", "mnop">>)

				-- Default background: black
			create l_buf.make (4, 4)
			l_shadow.render (l_base, l_buf)
			assert ("default bg becomes black", l_buf.cell (2, 2).style.background ~ {COLOR}.Black)
			assert ("default block cell kept", l_buf.cell (1, 1).style.background.is_default)

				-- Style first, then the effect
			create l_buf.make (4, 4)
			l_shadow.with_style (create {STYLE}.make_bg ({COLOR}.rgb (200, 100, 50))).render (l_base, l_buf)
			assert ("style then effect", l_buf.cell (2, 1).style.background ~ {COLOR}.rgb (100, 50, 25))
		end

feature -- Offsets

	test_shadow_negative_offset
			-- A negative offset moves the shadow up and left (Ratatui `Offset` is signed). The
			-- shadow of (2, 2, 3, 2) with offset (-1, -1) is (1, 1, 3, 2): row 1, columns 1..3,
			-- and column 1 of row 2. Offset (2, 1), as in Ratatui's `Block::shadow` example,
			-- leaves column 2 of the block's rows uncovered. Offset (0, 0) draws nothing.
			-- A shadow moved past column 0 is clamped there with its size kept, as Ratatui's
			-- `Rect + Offset` (review fix #6): with (-5, 0) it covers columns 0..2, of which
			-- 0..1 are outside the block; with (-3, 1) columns 0..2 of rows 3 and 4.
		local
			l_buf: BUFFER
			l_base: RECT
		do
			create l_base.make (2, 2, 3, 2)
			create l_buf.make (8, 6)
			(create {SHADOW}.make_symbol ('#')).with_offset (-1, -1).render (l_base, l_buf)
			assert_buffer_lines ("offset -1 -1", l_buf, <<"        ", " ###    ", " #      ", "        ", "        ", "        ">>)

			create l_buf.make (8, 6)
			(create {SHADOW}.make_symbol ('#')).with_offset (2, 1).render (l_base, l_buf)
			assert_buffer_lines ("offset 2 1", l_buf, <<"        ", "        ", "        ", "     ## ", "    ### ", "        ">>)

			create l_buf.make (8, 6)
			(create {SHADOW}.make_symbol ('#')).with_offset (0, 0).render (l_base, l_buf)
			assert_buffer_lines ("offset 0 0", l_buf, <<"        ", "        ", "        ", "        ", "        ", "        ">>)

			create l_buf.make (8, 6)
			(create {SHADOW}.make_symbol ('#')).with_offset (-5, 0).render (l_base, l_buf)
			assert_buffer_lines ("past the left edge, clamped at 0", l_buf, <<"        ", "        ", "##      ", "##      ", "        ", "        ">>)

			create l_buf.make (8, 6)
			(create {SHADOW}.make_symbol ('#')).with_offset (-3, 1).render (l_base, l_buf)
			assert_buffer_lines ("partly past the left edge, clamped at 0", l_buf, <<"        ", "        ", "        ", "##      ", "###     ", "        ">>)

			create l_buf.make (8, 6)
			(create {SHADOW}.make_symbol ('#')).with_offset (0, -9).render (l_base, l_buf)
			assert_buffer_lines ("past the top edge, clamped at 0", l_buf, <<"  ###   ", "  ###   ", "        ", "        ", "        ", "        ">>)

			create l_buf.make (8, 6)
			(create {SHADOW}.make_symbol ('#')).with_offset ({INTEGER}.min_value, {INTEGER}.max_value).render (l_base, l_buf)
			assert ("extreme offsets draw nothing", l_buf.is_consistent and l_buf.line (0).same_string ("        "))
		end

feature -- Block

	test_block_with_shadow
			-- TUI_BLOCK draws its shadow last: the borders and the title are as without a
			-- shadow, and the dark shade is on the column right of the block and the row below.
			-- The block style does not reach the shadow. `render_merged` draws it too. A block
			-- at the buffer's bottom-right corner has no visible shadow.
		local
			l_buf, l_plain: BUFFER
			l_block: TUI_BLOCK
			l_area: RECT
			r, c: INTEGER
		do
			create l_area.make (0, 0, 6, 3)
			create l_block.make
			l_block := l_block.with_title ("Hi").with_style (create {STYLE}.make_bg ({COLOR}.Blue))
			create l_plain.make (8, 5)
			l_block.render (l_area, l_plain)
			create l_buf.make (8, 5)
			l_block.with_shadow (create {SHADOW}.make_dark_shade).render (l_area, l_buf)
			assert_buffer_lines ("block with shadow", l_buf, <<
				{STRING_32} "%/0x250C/Hi%/0x2500/%/0x2500/%/0x2510/  ",
				{STRING_32} "%/0x2502/    %/0x2502/%/0x2593/ ",
				{STRING_32} "%/0x2514/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2518/%/0x2593/ ",
				{STRING_32} " %/0x2593/%/0x2593/%/0x2593/%/0x2593/%/0x2593/%/0x2593/ ",
				{STRING_32} "        ">>)
			from r := 0 until r > 2 loop
				from c := 0 until c > 5 loop
					assert ("block cell unchanged " + r.out + "," + c.out, l_buf.cell (r, c).is_equal (l_plain.cell (r, c)))
					c := c + 1
				end
				r := r + 1
			end
			assert ("shadow without block style", l_buf.cell (1, 6).style.background.is_default
				and l_buf.cell (3, 1).style.background.is_default)

			create l_buf.make (8, 5)
			l_block.with_shadow (create {SHADOW}.make_dark_shade).render_merged (l_area, l_buf)
			assert ("merged draws the shadow", l_buf.cell (3, 6).symbol.same_string ({STRING_32} "%/0x2593/")
				and l_buf.cell (1, 6).symbol.same_string ({STRING_32} "%/0x2593/"))

			create l_buf.make (8, 5)
			l_block.with_shadow (create {SHADOW}.make_dark_shade).render (create {RECT}.make (2, 2, 6, 3), l_buf)
			assert ("no shadow at the corner", across 0 |..| 4 as y all not l_buf.line (y).has ('%/0x2593/') end)
			assert ("consistent", l_buf.is_consistent)
		end

	test_block_shadow_equality_and_copy
			-- `with_shadow` leaves the original block alone; `is_equal` and `copy` include the
			-- shadow, and `twin` gives the copy its own SHADOW (a custom effect stays shared).
			-- SHADOW: default offset (1, 1), the kinds, builders, and `is_equal` (custom effects
			-- by reference, as Ratatui's `Arc::ptr_eq`).
		local
			l_block, l_with, l_copy: TUI_BLOCK
			l_dark, l_other: SHADOW
			l_effect: DIMMED_EFFECT
		do
			create l_dark.make_dark_shade
			create l_block.make
			l_with := l_block.with_shadow (l_dark)
			assert ("original has no shadow", l_block.shadow = Void)
			assert ("copy has it", l_with.shadow = l_dark)
			assert ("shadow counts in is_equal", not l_block.is_equal (l_with) and not l_with.is_equal (l_block))
			l_copy := l_with.twin
			assert ("twin equal", l_copy.is_equal (l_with))
			assert ("twin has its own shadow", l_copy.shadow /= l_dark and l_copy.shadow ~ l_dark)
			check attached l_copy.shadow as s then
				s.set_offset (3, 4)
			end
			assert ("original shadow unchanged", l_dark.offset_x = 1 and l_dark.offset_y = 1)
			assert ("changed copy differs", not l_copy.is_equal (l_with))
			assert ("other symbol differs", not l_with.is_equal (l_block.with_shadow (create {SHADOW}.make_light_shade)))
			assert ("equal shadow, equal block", l_with.is_equal (l_block.with_shadow (create {SHADOW}.make_dark_shade)))
			l_with.set_shadow (Void)
			assert ("cleared", l_with.shadow = Void and l_with.is_equal (l_block))

				-- SHADOW kinds and builders
			create l_other
			assert ("default is overlay", l_other.is_overlay and not l_other.has_symbol and not l_other.is_custom)
			assert ("default offset", l_other.offset_x = 1 and l_other.offset_y = 1)
			assert ("overlay is not a space shadow", not l_other.is_equal (create {SHADOW}.make_symbol (' ')))
			assert ("same symbol equal", l_dark.is_equal (create {SHADOW}.make_symbol ('%/0x2593/')))
			assert ("block symbol", (create {SHADOW}.make_block).symbol = '%/0x2588/')
			assert ("with_offset", l_dark.with_offset (-2, 5).offset_x = -2 and l_dark.with_offset (-2, 5).offset_y = 5)
			assert ("with_offset differs", not l_dark.is_equal (l_dark.with_offset (2, 1)))
			assert ("with_style differs", not l_dark.is_equal (l_dark.with_style ((create {STYLE}).with_bold)))
			assert ("builders leave the original", l_dark.offset_x = 1 and l_dark.style.is_equal (create {STYLE}))

			create l_effect
			create l_other.make_custom (l_effect)
			assert ("custom", l_other.is_custom and not l_other.is_overlay and l_other.effect = l_effect)
			assert ("same effect equal", l_other.is_equal (create {SHADOW}.make_custom (l_effect)))
			assert ("other effect object differs", not l_other.is_equal (create {SHADOW}.make_custom (create {DIMMED_EFFECT})))
			assert ("twin shares the effect", l_other.twin.effect = l_effect)
			check attached l_block.with_shadow (l_other).twin.shadow as s then
				assert ("block twin shares the effect", s /= l_other and s.effect = l_effect)
			end
		end

	test_shadow_refuses_wide_symbol
			-- A shadow symbol must be one column wide: a wide (U+5BBD) or zero-width (U+0301)
			-- character is refused by `make_symbol` and by `put_shadow_symbol`.
		local
			l_buf: BUFFER
		do
			create l_buf.make (2, 1)
			assert ("wide refused", precondition_raised (agent make_symbol_shadow ('%/0x5BBD/'), "one_column"))
			assert ("zero width refused", precondition_raised (agent make_symbol_shadow ('%/0x301/'), "one_column"))
			assert ("put wide refused", precondition_raised (agent (create {SHADOW}).put_shadow_symbol (l_buf, 0, 0, '%/0x5BBD/'), "one_column"))
			assert ("one column accepted", not precondition_raised (agent make_symbol_shadow ('%/0xD7/'), "one_column"))
			assert ("valid symbol", {SHADOW}.is_valid_symbol ('#') and not {SHADOW}.is_valid_symbol ('%/0x5BBD/'))
		end

feature -- Wide characters

	test_shadow_over_wide_characters
			-- The buffer keeps each wide character with its continuation cell. The shadow of
			-- (0, 0, 4, 1) is row 1, columns 1..4, over "宽宽宽" (columns 0-1, 2-3, 4-5) in green:
			--  * a symbol shadow splits the two cut characters: '#' in columns 1..4, and the
			--    halves outside (columns 0 and 5) become blanks that keep green, without the
			--    shadow's blue background;
			--  * an overlay keeps the symbols: the characters starting in the shadow (columns 2
			--    and 4) take the blue background, the one starting outside keeps its style;
			--  * Dimmed keeps the symbols too.
			-- Every row stays continuation-consistent.
		local
			l_buf: BUFFER
			l_green, l_blue: STYLE
			l_base: RECT
			l_wide: STRING_32
			c: INTEGER
		do
			create l_base.make (0, 0, 4, 1)
			create l_green.make_fg ({COLOR}.Green)
			create l_blue.make_bg ({COLOR}.Blue)
			l_wide := {STRING_32} "%/0x5BBD/%/0x5BBD/%/0x5BBD/"

			l_buf := wide_row_buffer (l_wide, l_green)
			(create {SHADOW}.make_symbol ('#')).with_style (l_blue).render (l_base, l_buf)
			assert_buffer_lines ("symbol over wide", l_buf, <<"      ", " #### ", "      ">>)
			assert ("symbol consistent", l_buf.is_consistent)
			from c := 1 until c > 4 loop
				assert ("# keeps green and gets blue " + c.out, l_buf.cell (1, c).style.foreground ~ {COLOR}.Green
					and l_buf.cell (1, c).style.background ~ {COLOR}.Blue)
				c := c + 1
			end
			assert ("left half kept green, not blue", l_buf.cell (1, 0).style.foreground ~ {COLOR}.Green
				and l_buf.cell (1, 0).style.background.is_default)
			assert ("right half kept green, not blue", l_buf.cell (1, 5).style.foreground ~ {COLOR}.Green
				and l_buf.cell (1, 5).style.background.is_default)

			l_buf := wide_row_buffer (l_wide, l_green)
			(create {SHADOW}.make_overlay).with_style (l_blue).render (l_base, l_buf)
			assert_buffer_lines ("overlay over wide", l_buf, <<"      ", l_wide, "      ">>)
			assert ("overlay consistent", l_buf.is_consistent)
			assert ("starts outside: unchanged", l_buf.cell (1, 0).style.background.is_default)
			assert ("inside: blue", l_buf.cell (1, 2).style.background ~ {COLOR}.Blue)
			assert ("starts inside, ends outside: blue", l_buf.cell (1, 4).style.background ~ {COLOR}.Blue)
			assert ("green kept", l_buf.cell (1, 2).style.foreground ~ {COLOR}.Green)

			l_buf := wide_row_buffer (l_wide, l_green)
			(create {SHADOW}.make_custom (create {DIMMED_EFFECT})).render (l_base, l_buf)
			assert_buffer_lines ("dimmed over wide", l_buf, <<"      ", l_wide, "      ">>)
			assert ("dimmed consistent", l_buf.is_consistent)
			assert ("dimmed head", l_buf.cell (1, 2).style.is_dim and not l_buf.cell (1, 0).style.is_dim)

				-- Custom effect through `put_shadow_symbol`
			l_buf := wide_row_buffer (l_wide, l_green)
			(create {SHADOW}.make_custom (create {PLUS_TEST_EFFECT})).render (l_base, l_buf)
			assert_buffer_lines ("plus over wide", l_buf, <<"      ", " ++++ ", "      ">>)
			assert ("plus consistent", l_buf.is_consistent)
		end

feature -- Popup

	test_popup_with_shadow_over_list
			-- A popup with an overlay shadow over a list: the shadow keeps the list's
			-- characters and gives them the shadow background; nothing else changes.
			-- `with_shadow` on a popup with a block keeps its borders and leaves the shared
			-- block alone; on a popup without a block it adds a borderless one.
		local
			l_buf: BUFFER
			l_list: TUI_LIST
			l_popup, l_shadowed: TUI_POPUP
			l_block: TUI_BLOCK
			l_shadow: SHADOW
			l_rows: ARRAY [STRING_32]
			r, c: INTEGER
			l_in_shadow: BOOLEAN
		do
			l_rows := <<"0123456789", "abcdefghij", "ABCDEFGHIJ", "klmnopqrst", "KLMNOPQRST">>
			create l_list.make (<<create {LIST_ITEM}.make_raw (l_rows [1]), create {LIST_ITEM}.make_raw (l_rows [2]),
				create {LIST_ITEM}.make_raw (l_rows [3]), create {LIST_ITEM}.make_raw (l_rows [4]),
				create {LIST_ITEM}.make_raw (l_rows [5])>>)
			create l_block.make
			create l_popup.make
			l_popup := l_popup.with_block (l_block)
			l_shadow := (create {SHADOW}.make_overlay).with_style (create {STYLE}.make_bg ({COLOR}.Blue))
			l_shadowed := l_popup.with_shadow (l_shadow)
			assert ("popup shadow", l_shadowed.shadow = l_shadow)
			assert ("original popup unchanged", l_popup.shadow = Void and l_block.shadow = Void)
			assert ("borders kept", attached l_shadowed.block as b and then b.borders = {BORDERS}.all_borders)

			create l_buf.make (10, 5)
			l_list.render (l_buf.area, l_buf)
			l_shadowed.render (create {RECT}.make (1, 0, 5, 3), l_buf)
			assert_buffer_lines ("popup over list", l_buf, <<
				{STRING_32} "0%/0x250C/%/0x2500/%/0x2500/%/0x2500/%/0x2510/6789",
				{STRING_32} "a%/0x2502/   %/0x2502/ghij",
				{STRING_32} "A%/0x2514/%/0x2500/%/0x2500/%/0x2500/%/0x2518/GHIJ",
				{STRING_32} "klmnopqrst",
				{STRING_32} "KLMNOPQRST">>)
			from r := 0 until r > 4 loop
				from c := 0 until c > 9 loop
					l_in_shadow := (c = 6 and (r = 1 or r = 2)) or (r = 3 and c >= 2 and c <= 6)
					assert ("shadow background " + r.out + "," + c.out,
						(l_buf.cell (r, c).style.background ~ {COLOR}.Blue) = l_in_shadow)
					c := c + 1
				end
				r := r + 1
			end

				-- No block: a borderless one carries the shadow
			create l_popup.make
			l_shadowed := l_popup.with_shadow (create {SHADOW}.make_symbol ('#'))
			assert ("block made", attached l_shadowed.block as b and then b.borders = {BORDERS}.none)
			assert ("original has none", l_popup.block = Void and l_popup.shadow = Void)
			create l_buf.make (6, 4)
			l_shadowed.render (create {RECT}.make (0, 0, 3, 2), l_buf)
			assert_buffer_lines ("borderless popup", l_buf, <<"      ", "   #  ", " ###  ", "      ">>)
			l_shadowed.set_shadow (Void)
			assert ("cleared", l_shadowed.shadow = Void)
		end

	test_popup_shadow_hit_testing
			-- The shadow registers no hit region (see the TUI_POPUP note). Non-modal: a click
			-- on the shadow hits the background control under it. Modal: it hits nothing, as
			-- the rest of the background, and a control registered after the popup is clipped
			-- to the popup's area, so it is not reachable on the shadow either.
		local
			l_frame: FRAME
			l_focus: FOCUS_MANAGER
			l_under, l_ok: WIDGET_ID
			l_popup: TUI_POPUP
			l_rect: RECT
		do
			create l_under.make (2)
			create l_ok.make (10)
			create l_rect.make (2, 0, 6, 3)
			create l_popup.make
			l_popup := l_popup.with_block (create {TUI_BLOCK}.make).with_shadow (create {SHADOW}.make_medium_shade)

			create l_frame.make (create {BUFFER}.make (20, 6))
			l_frame.register_hit (l_under, create {RECT}.make (2, 3, 10, 1))
			l_frame.render_widget (l_popup, l_rect)
			assert ("shadow drawn", l_frame.buffer.cell (3, 5).symbol.same_string ({STRING_32} "%/0x2592/"))
			assert ("non-modal registers nothing", l_frame.hit_map.count = 1)
			assert ("non-modal: shadow click hits the background", attached l_frame.hit_map.hit (5, 3) as id and then id ~ l_under)

			create l_focus.make
			l_focus.register (l_under)
			l_popup.begin_modal_with (l_focus, <<l_ok>>)
			create l_frame.make (create {BUFFER}.make (20, 6))
			l_frame.register_hit (l_under, create {RECT}.make (2, 3, 10, 1))
			l_frame.render_widget (l_popup, l_rect)
			l_frame.register_hit (l_ok, create {RECT}.make (3, 1, 8, 3))
			assert ("modal: shadow click hits nothing", l_frame.hit_map.hit (5, 3) = Void)
			assert ("modal: shadow column hits nothing", l_frame.hit_map.hit (8, 1) = Void)
			assert ("modal: dialog control reachable in the popup", attached l_frame.hit_map.hit (4, 1) as id and then id ~ l_ok)
			l_popup.end_modal (l_focus)
		end

feature {NONE} -- Helpers

	buffer_with_lines (a_lines: ARRAY [READABLE_STRING_GENERAL]): BUFFER
			-- New buffer with `a_lines` as rows (Ratatui `Buffer::with_lines`)
		require
			not_empty: not a_lines.is_empty
		local
			i: INTEGER
		do
			create Result.make ({UNICODE_WIDTH}.string_width (a_lines [a_lines.lower]).to_integer_32, a_lines.count)
			from i := a_lines.lower until i > a_lines.upper loop
				Result.put_string (i - a_lines.lower, 0, a_lines [i], create {STYLE})
				i := i + 1
			end
		end

	wide_row_buffer (a_row: STRING_32; a_style: STYLE): BUFFER
			-- New 6 x 3 buffer with `a_row` on row 1 in `a_style`
		do
			create Result.make (6, 3)
			Result.put_string (1, 0, a_row, a_style)
		end

	assert_symbol_shadow (a_tag: STRING; a_shadow: SHADOW; a_symbol: STRING_32)
			-- The shadow of (0, 0, 2, 2) on an empty 4 x 4 buffer puts `a_symbol` in the three
			-- visible shadow cells only, with the default style everywhere.
		local
			l_buf: BUFFER
			r, c: INTEGER
		do
			create l_buf.make (4, 4)
			a_shadow.render (create {RECT}.make (0, 0, 2, 2), l_buf)
			assert_buffer_lines (a_tag, l_buf, <<"    ", {STRING_32} "  " + a_symbol + " ", {STRING_32} " " + a_symbol + a_symbol + " ", "    ">>)
			assert (a_tag + ": block cell is a space", l_buf.cell (1, 1).symbol.same_string (" "))
			from r := 0 until r > 3 loop
				from c := 0 until c > 3 loop
					assert (a_tag + ": default style", l_buf.cell (r, c).style.renders_as_default)
					c := c + 1
				end
				r := r + 1
			end
		end

	assert_shadow_styles (a_tag: STRING; a_buf: BUFFER; a_cells: ARRAY [TUPLE [row, col: INTEGER]]; a_fg, a_bg: COLOR)
			-- The cells `a_cells` of `a_buf` have `a_fg` on `a_bg`; every other cell has the
			-- default colours.
		local
			r, c: INTEGER
			l_listed: BOOLEAN
			l_style: STYLE
		do
			from r := 0 until r >= a_buf.height loop
				from c := 0 until c >= a_buf.width loop
					l_listed := across a_cells as t some t.row = r and t.col = c end
					l_style := a_buf.cell (r, c).style
					if l_listed then
						assert (a_tag + ": shadow style " + r.out + "," + c.out, l_style.foreground ~ a_fg and l_style.background ~ a_bg)
					else
						assert (a_tag + ": default style " + r.out + "," + c.out, l_style.foreground.is_default and l_style.background.is_default)
					end
					c := c + 1
				end
				r := r + 1
			end
		end

	make_symbol_shadow (a_char: CHARACTER_32)
			-- Create a symbol shadow of `a_char` (for `precondition_raised`).
		local
			l_shadow: SHADOW
		do
			create l_shadow.make_symbol (a_char)
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
