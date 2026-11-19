note
	description: "[
		P2 item W3, TUI_SLIDER and SLIDER_STATE (review/p2_terminal_widgets_plan.md).
		Ratatui has no slider, so these are EiffelTUI's own tests: the state's clamping,
		snapping and stepping at both ends, the whole INTEGER_64 range without overflow (as
		P1 X3), `minimum` = `maximum`; `set_from_position` at the first, middle and last cell,
		horizontal and vertical, through the widget's `track_cell`; row-exact buffer snapshots
		in both directions, with and without a label, focused, with styles checked; the hit
		region; and a scripted click, drag, release and keys through `hit_test`, `track_area`
		and `set_from_position`, as the class note of TUI_SLIDER shows.

		Expected rows are written with `bar`: '=' filled (U+2501), '-' track (U+2500),
		'#' vertical filled (U+2503), '|' vertical track (U+2502), 'o' thumb (U+25CF).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_SLIDER

inherit
	BUFFER_TEST_HELPER

feature -- State

	test_slider_state_clamp_and_snap
			-- Clamped at both ends, snapped to the nearest step (a tie goes up), `maximum` valid
			-- even off the step grid; `increase` / `decrease` and the page moves stop at the ends;
			-- `set_range` and `set_step` snap the value again.
		local
			s: SLIDER_STATE
		do
			create s
			assert ("default", s.minimum = 0 and s.maximum = 100 and s.step = 1 and s.value = 0)
				-- 0 .. 10 by 3: 0, 3, 6, 9, 10
			create s.make (0, 10, 3)
			s.set_value (-5)
			assert ("below clamps", s.value = 0 and s.is_at_minimum)
			s.set_value (15)
			assert ("above clamps", s.value = 10 and s.is_at_maximum)
			s.set_value (4)
			assert ("4 to 3", s.value = 3)
			s.set_value (5)
			assert ("5 to 6", s.value = 6)
			s.set_value (9)
			assert ("9 kept", s.value = 9)
			s.set_value (10)
			assert ("maximum kept", s.value = 10)
			assert ("valid values", s.is_valid_value (9) and s.is_valid_value (10) and not s.is_valid_value (8)
				and not s.is_valid_value (11) and not s.is_valid_value (-3))
			s.set_to_minimum
			s.increase
			assert ("up 3", s.value = 3)
			s.increase; s.increase
			assert ("up 9", s.value = 9)
			s.increase
			assert ("up to the maximum off the grid", s.value = 10)
			s.increase
			assert ("stays at the maximum", s.value = 10)
			s.decrease
			assert ("down from the maximum to the grid", s.value = 9)
			s.decrease; s.decrease; s.decrease
			assert ("down 0", s.value = 0)
			s.decrease
			assert ("stays at the minimum", s.value = 0)
				-- Ties go to the larger value: 0 .. 10 by 4 is 0, 4, 8, 10
			create s.make (0, 10, 4)
			s.set_value (2)
			assert ("tie 2 to 4", s.value = 4)
			s.set_value (6)
			assert ("tie 6 to 8", s.value = 8)
			s.set_value (9)
			assert ("tie 9 to 10", s.value = 10)
				-- A negative range: -10, -6, -2, -1
			create s.make (-10, -1, 4)
			s.set_value (-4)
			assert ("negative tie up", s.value = -2)
			s.set_value (-9)
			assert ("negative down", s.value = -10)
			s.set_to_maximum
			s.decrease
			assert ("negative decrease", s.value = -2)
				-- Pages of ten steps
			create s.make (0, 1000, 7)
			s.increase_page
			assert ("page up", s.value = 70)
			s.decrease_page
			assert ("page down", s.value = 0)
			s.decrease_page
			assert ("page at the minimum", s.value = 0)
			s.set_value (995)
			assert ("995 to 994", s.value = 994)
			s.increase_page
			assert ("page stops at the maximum", s.value = 1000)
			s.set_value (994)
			s.set_step (10)
			assert ("set_step snaps", s.step = 10 and s.value = 990)
			s.set_range (0, 50)
			assert ("set_range clamps", s.minimum = 0 and s.maximum = 50 and s.value = 50)
			s.set_range (100, 200)
			assert ("set_range clamps up", s.value = 100)
		end

	test_slider_state_large_ranges
			-- The whole INTEGER_64 range (2^64 - 1 apart) and steps near 2^63, with no overflow:
			-- the offsets are NATURAL_64 and `scaled_rounded` is exact (as P1 X3).
		local
			s: SLIDER_STATE
			l_min, l_max: INTEGER_64
			l_n: NATURAL_64
		do
			l_min := {INTEGER_64}.min_value
			l_max := {INTEGER_64}.max_value
			create s.make (l_min, l_max, 1)
			assert ("span", s.span = {NATURAL_64}.max_value)
			assert ("thumb at the minimum", s.thumb_cell (101) = 0)
			s.set_value (0)
			assert ("zero kept", s.value = 0)
			assert ("zero is the middle", s.thumb_cell (101) = 50)
			assert ("just over half rounds up", s.thumb_cell (2) = 1)
			s.set_value (l_max - 1)
			assert ("max - 1 on a long track", s.thumb_cell (65535) = 65534)
			s.set_to_maximum
			assert ("thumb at the end", s.thumb_cell (65535) = 65534)
			s.increase
			assert ("increase at the maximum", s.value = l_max)
			s.set_value (l_max - 1)
			s.increase
			assert ("increase to the maximum", s.value = l_max)
			s.set_to_minimum
			s.decrease
			assert ("decrease at the minimum", s.value = l_min)
			s.increase_page
			assert ("page from the minimum", s.value = l_min + 10)
			s.set_from_position (50, 101)
			assert ("middle cell is zero", s.value = 0)
			s.set_from_position (0, 101)
			assert ("first cell", s.value = l_min)
			s.set_from_position (100, 101)
			assert ("last cell", s.value = l_max)
			s.set_from_position (1, 3)
			assert ("half of 2^64 - 1 rounds up to zero", s.value = 0)
				-- A step of 2^63 - 1: min, -1, max - 1, max
			create s.make (l_min, l_max, l_max)
			s.increase
			assert ("big step 1", s.value = -1)
			s.increase
			assert ("big step 2", s.value = l_max - 1)
			s.increase
			assert ("big step to the maximum", s.value = l_max)
			s.decrease
			assert ("big step down 1", s.value = l_max - 1)
			s.decrease
			assert ("big step down 2", s.value = -1)
			s.decrease
			assert ("big step down to the minimum", s.value = l_min)
			s.set_value (0)
			assert ("0 snaps to -1", s.value = -1)
			s.set_value (l_max - 2)
			assert ("max - 2 snaps to max - 1", s.value = l_max - 1)
			s.set_value (l_max)
			s.increase_page
			assert ("page at the maximum", s.value = l_max)
				-- Exact scaling where the product overflows NATURAL_64
			l_n := {NATURAL_64}.max_value
			assert ("scaled a = c", {SLIDER_STATE}.scaled_rounded (l_n, 7, l_n) = 7)
			assert ("scaled long product", {SLIDER_STATE}.scaled_rounded (l_n - 1, l_n, l_n) = l_n - 1)
			assert ("scaled half up", {SLIDER_STATE}.scaled_rounded (1, l_n, 2) = (1).to_natural_64 |<< 63)
			assert ("scaled 3/4 of max", {SLIDER_STATE}.scaled_rounded (3, l_n, 4) = ((3).to_natural_64 |<< 62) - 1)
			assert ("scaled zero", {SLIDER_STATE}.scaled_rounded (0, l_n, l_n) = 0)
		end

	test_slider_state_empty_range
			-- `minimum` = `maximum`: the only value, the thumb at the start, nothing moves it.
		local
			s: SLIDER_STATE
		do
			create s.make (5, 5, 1)
			assert ("value", s.value = 5 and s.is_at_minimum and s.is_at_maximum)
			assert ("thumb at the start", s.thumb_cell (10) = 0 and s.thumb_cell (1) = 0)
			s.increase
			s.increase_page
			assert ("increase", s.value = 5)
			s.decrease
			s.decrease_page
			assert ("decrease", s.value = 5)
			s.set_value (100)
			assert ("set above", s.value = 5)
			s.set_value (-100)
			assert ("set below", s.value = 5)
			s.set_from_position (9, 10)
			assert ("last cell", s.value = 5 and s.thumb_cell (10) = 0)
			create s.make ({INTEGER_64}.min_value, {INTEGER_64}.min_value, {INTEGER_64}.max_value)
			s.increase
			s.set_from_position (3, 4)
			assert ("empty range at the INTEGER_64 minimum", s.value = {INTEGER_64}.min_value and s.thumb_cell (4) = 0)
		end

	test_slider_set_from_position
			-- First, middle and last cell, cells past the ends, rounding half up, snapping after
			-- the mapping, a one-cell track, and every cell back through `thumb_cell`.
		local
			s: SLIDER_STATE
			c: INTEGER
			l_round_trip: BOOLEAN
		do
			create s.make (0, 100, 1)
			s.set_from_position (0, 11)
			assert ("first", s.value = 0)
			s.set_from_position (5, 11)
			assert ("middle", s.value = 50)
			s.set_from_position (10, 11)
			assert ("last", s.value = 100)
			s.set_from_position (-3, 11)
			assert ("before the track", s.value = 0)
			s.set_from_position (20, 11)
			assert ("after the track", s.value = 100)
			s.set_value (40)
			s.set_from_position (0, 1)
			assert ("one cell leaves the value", s.value = 40)
			l_round_trip := True
			from c := 0 until c > 10 loop
				s.set_from_position (c, 11)
				l_round_trip := l_round_trip and s.thumb_cell (11) = c
				c := c + 1
			end
			assert ("round trip", l_round_trip)
				-- Rounding: 0 .. 10 on four cells is 0, 3.33, 6.67, 10
			create s.make (0, 10, 1)
			s.set_from_position (1, 4)
			assert ("3.33 to 3", s.value = 3)
			s.set_from_position (2, 4)
			assert ("6.67 to 7", s.value = 7)
			s.set_value (1)
			assert ("thumb 0.3 to 0", s.thumb_cell (4) = 0)
			s.set_value (5)
			assert ("thumb 1.5 to 2", s.thumb_cell (4) = 2)
			create s.make (0, 5, 1)
			s.set_from_position (1, 3)
			assert ("2.5 to 3", s.value = 3)
				-- Snapped after the mapping
			create s.make (0, 100, 25)
			s.set_from_position (3, 11)
			assert ("30 snaps to 25", s.value = 25)
			s.set_from_position (4, 11)
			assert ("40 snaps to 50", s.value = 50)
		end

	test_slider_track_cell_both_directions
			-- `track_cell` maps a frame point to a cell counted from the `minimum` end; with
			-- `set_from_position` the first, middle and last cell give 0, 50 and 100.
		local
			s: SLIDER_STATE
			h, v: TUI_SLIDER
			l_area: RECT
		do
			create s.make (0, 100, 1)
				-- Horizontal at (3, 2), 11 wide: the track is columns 3 .. 13
			create h.make
			l_area := create {RECT}.make (3, 2, 11, 1)
			assert ("h track", h.track_area (l_area, s) ~ create {RECT}.make (3, 2, 11, 1) and h.track_length (l_area, s) = 11)
			assert ("h cells", h.track_cell (l_area, s, 3, 2) = 0 and h.track_cell (l_area, s, 8, 2) = 5
				and h.track_cell (l_area, s, 13, 2) = 10)
			assert ("h past the ends", h.track_cell (l_area, s, 1, 2) = -2 and h.track_cell (l_area, s, 20, 9) = 17)
			s.set_from_position (h.track_cell (l_area, s, 3, 2), h.track_length (l_area, s))
			assert ("h first", s.value = 0)
			s.set_from_position (h.track_cell (l_area, s, 8, 2), h.track_length (l_area, s))
			assert ("h middle", s.value = 50)
			s.set_from_position (h.track_cell (l_area, s, 13, 2), h.track_length (l_area, s))
			assert ("h last", s.value = 100)
				-- With a label on the left ("100" is 3 columns, then the gap): track from column 7
			l_area := create {RECT}.make (3, 2, 15, 1)
			assert ("h label track", h.with_label_position ({SLIDER_LABEL_POSITION}.left).track_area (l_area, s)
				~ create {RECT}.make (7, 2, 11, 1))
			assert ("h label first cell", h.with_label_position ({SLIDER_LABEL_POSITION}.left).track_cell (l_area, s, 7, 2) = 0)
			assert ("h right label track", h.with_label_position ({SLIDER_LABEL_POSITION}.right).track_area (l_area, s)
				~ create {RECT}.make (3, 2, 11, 1))
				-- Vertical at (2, 1), 5 rows: the bottom row is the minimum
			create v.make_vertical
			l_area := create {RECT}.make (2, 1, 4, 5)
			assert ("v track", v.track_area (l_area, s) ~ create {RECT}.make (2, 1, 1, 5) and v.track_length (l_area, s) = 5)
			assert ("v cells", v.track_cell (l_area, s, 2, 5) = 0 and v.track_cell (l_area, s, 2, 3) = 2
				and v.track_cell (l_area, s, 2, 1) = 4)
			assert ("v past the ends", v.track_cell (l_area, s, 2, 9) = -4 and v.track_cell (l_area, s, 2, 0) = 5)
			s.set_from_position (v.track_cell (l_area, s, 2, 5), v.track_length (l_area, s))
			assert ("v first", s.value = 0)
			s.set_from_position (v.track_cell (l_area, s, 2, 3), v.track_length (l_area, s))
			assert ("v middle", s.value = 50)
			s.set_from_position (v.track_cell (l_area, s, 2, 1), v.track_length (l_area, s))
			assert ("v last", s.value = 100)
				-- Vertical with a label above: the track starts one row lower
			assert ("v label above", v.with_label_position ({SLIDER_LABEL_POSITION}.left).track_area (l_area, s)
				~ create {RECT}.make (2, 2, 1, 4))
			assert ("v label below", v.with_label_position ({SLIDER_LABEL_POSITION}.right).track_area (l_area, s)
				~ create {RECT}.make (2, 1, 1, 4))
			assert ("on track", v.is_on_track (l_area, s, 2, 3) and not v.is_on_track (l_area, s, 3, 3)
				and not v.is_on_track (l_area, s, 2, 6))
				-- Empty area: empty track
			assert ("empty", h.track_length (create {RECT}.make (3, 2, 0, 1), s) = 0
				and not h.is_on_track (create {RECT}.make (3, 2, 0, 1), s, 3, 2))
		end

feature -- Snapshots

	test_slider_horizontal_snapshots
			-- Thumb at the start, the middle and the end; other rows untouched; a label right
			-- and left (one blank from the track), with a format agent, dropped when it leaves
			-- no track cell.
		local
			l_buf: BUFFER
			s: SLIDER_STATE
			h: TUI_SLIDER
		do
			create h.make
			create s.make (0, 100, 1)
			create l_buf.make (11, 2)
			h.render_stateful (create {RECT}.make (0, 0, 11, 2), l_buf, s)
			assert_buffer_lines ("at 0", l_buf, <<bar ("o----------"), "           ">>)
			s.set_value (50)
			create l_buf.make (11, 2)
			h.render_stateful (create {RECT}.make (0, 0, 11, 2), l_buf, s)
			assert_buffer_lines ("at 50", l_buf, <<bar ("=====o-----"), "           ">>)
			s.set_to_maximum
			create l_buf.make (11, 1)
			h.render_stateful (create {RECT}.make (0, 0, 11, 1), l_buf, s)
			assert_buffer_lines ("at 100", l_buf, <<bar ("==========o")>>)
			s.set_value (40)
			create l_buf.make (17, 1)
			h.with_label_position ({SLIDER_LABEL_POSITION}.right).render_stateful (create {RECT}.make (1, 0, 15, 1), l_buf, s)
			assert_buffer_lines ("label right", l_buf, <<bar (" ====o------ 40  ")>>)
			create l_buf.make (17, 1)
			h.with_label_position ({SLIDER_LABEL_POSITION}.left).render_stateful (create {RECT}.make (1, 0, 15, 1), l_buf, s)
			assert_buffer_lines ("label left", l_buf, <<bar ("  40 ====o------ ")>>)
			create l_buf.make (16, 1)
			h.with_label_position ({SLIDER_LABEL_POSITION}.right)
				.with_label_format (agent (v: INTEGER_64): STRING do Result := v.out + "%%" end)
				.render_stateful (create {RECT}.make (0, 0, 16, 1), l_buf, s)
			assert_buffer_lines ("format", l_buf, <<bar ("====o------ 40%% ")>>)
				-- The label is drawn over what was there; the gap too
			create l_buf.make (8, 1)
			l_buf.put_string (0, 0, "########", create {STYLE})
			s.set_value (100)
			h.with_label_position ({SLIDER_LABEL_POSITION}.left).render_stateful (create {RECT}.make (0, 0, 8, 1), l_buf, s)
			assert_buffer_lines ("over text", l_buf, <<bar ("100 ===o")>>)
				-- Dropped: 4 columns cannot hold "100", the gap and a track cell
			create l_buf.make (4, 1)
			s.set_value (0)
			h.with_label_position ({SLIDER_LABEL_POSITION}.left).render_stateful (create {RECT}.make (0, 0, 4, 1), l_buf, s)
			assert_buffer_lines ("dropped", l_buf, <<bar ("o---")>>)
			assert ("shows_label", not h.with_label_position ({SLIDER_LABEL_POSITION}.left).shows_label (create {RECT}.make (0, 0, 4, 1), s)
				and h.with_label_position ({SLIDER_LABEL_POSITION}.left).shows_label (create {RECT}.make (0, 0, 5, 1), s))
				-- Minimum = maximum: thumb at the start
			create l_buf.make (5, 1)
			h.render_stateful (create {RECT}.make (0, 0, 5, 1), l_buf, create {SLIDER_STATE}.make (7, 7, 1))
			assert_buffer_lines ("empty range", l_buf, <<bar ("o----")>>)
				-- Own symbols; the stateless render uses 0 .. 100 at 0
			create l_buf.make (5, 1)
			h.with_track_symbol (".").with_filled_symbol ("+").with_thumb_symbol ("|")
				.render_stateful (create {RECT}.make (0, 0, 5, 1), l_buf, create {SLIDER_STATE}.make (0, 4, 1))
			assert_buffer_lines ("own symbols at 0", l_buf, <<"|....">>)
			create s.make (0, 4, 1)
			s.set_value (2)
			create l_buf.make (5, 1)
			h.with_track_symbol (".").with_filled_symbol ("+").with_thumb_symbol ("|")
				.render_stateful (create {RECT}.make (0, 0, 5, 1), l_buf, s)
			assert_buffer_lines ("own symbols", l_buf, <<"++|..">>)
			create l_buf.make (3, 1)
			h.render (create {RECT}.make (0, 0, 3, 1), l_buf)
			assert_buffer_lines ("stateless", l_buf, <<bar ("o--")>>)
		end

	test_slider_vertical_snapshots
			-- The minimum at the bottom; a label above (`left`) or below (`right`) on its own
			-- row, left-aligned; other columns untouched.
		local
			l_buf: BUFFER
			s: SLIDER_STATE
			v: TUI_SLIDER
		do
			create v.make_vertical
			create s.make (0, 100, 1)
			s.set_value (50)
			create l_buf.make (2, 5)
			v.render_stateful (create {RECT}.make (0, 0, 2, 5), l_buf, s)
			assert_buffer_lines ("at 50", l_buf, <<bar ("| "), bar ("| "), bar ("o "), bar ("# "), bar ("# ")>>)
			s.set_to_minimum
			create l_buf.make (1, 5)
			v.render_stateful (create {RECT}.make (0, 0, 1, 5), l_buf, s)
			assert_buffer_lines ("at 0", l_buf, <<bar ("|"), bar ("|"), bar ("|"), bar ("|"), bar ("o")>>)
			s.set_to_maximum
			create l_buf.make (1, 5)
			v.render_stateful (create {RECT}.make (0, 0, 1, 5), l_buf, s)
			assert_buffer_lines ("at 100", l_buf, <<bar ("o"), bar ("#"), bar ("#"), bar ("#"), bar ("#")>>)
			s.set_value (50)
			create l_buf.make (4, 6)
			v.with_label_position ({SLIDER_LABEL_POSITION}.left).render_stateful (create {RECT}.make (0, 0, 4, 6), l_buf, s)
			assert_buffer_lines ("label above", l_buf, <<"50  ", bar ("|   "), bar ("|   "), bar ("o   "), bar ("#   "), bar ("#   ")>>)
			create l_buf.make (4, 6)
			v.with_label_position ({SLIDER_LABEL_POSITION}.right).render_stateful (create {RECT}.make (0, 0, 4, 6), l_buf, s)
			assert_buffer_lines ("label below", l_buf, <<bar ("|   "), bar ("|   "), bar ("o   "), bar ("#   "), bar ("#   "), "50  ">>)
				-- The label is never cut (100 would read 10 or 1): an area narrower than the
				-- label drops it, and the track takes every row; one that fits it keeps it
			create l_buf.make (2, 3)
			s.set_to_maximum
			v.with_label_position ({SLIDER_LABEL_POSITION}.left).render_stateful (create {RECT}.make (0, 0, 2, 3), l_buf, s)
			assert_buffer_lines ("label too wide: dropped", l_buf, <<bar ("o "), bar ("# "), bar ("# ")>>)
			assert ("too wide: not shown", not v.with_label_position ({SLIDER_LABEL_POSITION}.left).shows_label (create {RECT}.make (0, 0, 2, 3), s))
			create l_buf.make (1, 4)
			v.with_label_position ({SLIDER_LABEL_POSITION}.right).render_stateful (create {RECT}.make (0, 0, 1, 4), l_buf, s)
			assert_buffer_lines ("one column: dropped", l_buf, <<bar ("o"), bar ("#"), bar ("#"), bar ("#")>>)
			create l_buf.make (3, 3)
			v.with_label_position ({SLIDER_LABEL_POSITION}.left).render_stateful (create {RECT}.make (0, 0, 3, 3), l_buf, s)
			assert_buffer_lines ("label fits whole", l_buf, <<"100", bar ("o  "), bar ("#  ")>>)
			create l_buf.make (1, 1)
			v.with_label_position ({SLIDER_LABEL_POSITION}.left).render_stateful (create {RECT}.make (0, 0, 1, 1), l_buf, s)
			assert_buffer_lines ("one row", l_buf, <<bar ("o")>>)
		end

	test_slider_focused_and_styles
			-- `style`, then `focused_style` when focused (reversed by default), over the track and
			-- the label (gap included) only, the rest of the area left as it is; `filled_style`
			-- and `thumb_style` on top; a background under the slider is kept.
		local
			l_buf: BUFFER
			s: SLIDER_STATE
			l_rev, l_green, l_red, l_blue: STYLE
		do
			l_rev := (create {STYLE}).with_reverse
			l_green := create {STYLE}.make_fg ({COLOR}.green)
			l_red := create {STYLE}.make_fg ({COLOR}.red)
			l_blue := create {STYLE}.make_bg ({COLOR}.blue)
			create s.make (0, 4, 1)
			s.set_value (2)
				-- Focused: the track, the gap and the label reversed; the second row of the
				-- area and anything outside it untouched
			create l_buf.make (10, 2)
			(create {TUI_SLIDER}).with_focused (True).with_label_position ({SLIDER_LABEL_POSITION}.right)
				.render_stateful (create {RECT}.make (0, 0, 7, 2), l_buf, s)
			assert_buffer_lines ("focused", l_buf, <<bar ("==o-- 2   "), "          ">>)
			assert_cell_style ("focused filled", l_buf, 0, 0, l_rev)
			assert_cell_style ("focused thumb", l_buf, 0, 2, l_rev)
			assert_cell_style ("focused track", l_buf, 0, 4, l_rev)
			assert_cell_style ("focused gap", l_buf, 0, 5, l_rev)
			assert_cell_style ("focused label", l_buf, 0, 6, l_rev)
			assert_cell_style ("second row untouched", l_buf, 1, 3, create {STYLE})
			assert_cell_style ("outside", l_buf, 0, 7, create {STYLE})
				-- Not focused: no reverse
			create l_buf.make (5, 1)
			(create {TUI_SLIDER}).with_focused (False).render_stateful (create {RECT}.make (0, 0, 5, 1), l_buf, s)
			assert_cell_style ("unfocused", l_buf, 0, 0, create {STYLE})
				-- Filled and thumb styles over a blue background; focused adds reverse under them
			create l_buf.make (5, 1)
			l_buf.set_style (l_buf.area, l_blue)
			(create {TUI_SLIDER}).with_filled_style (l_green).with_thumb_style (l_red)
				.render_stateful (create {RECT}.make (0, 0, 5, 1), l_buf, s)
			assert_buffer_lines ("styled", l_buf, <<bar ("==o--")>>)
			assert_cell_style ("filled", l_buf, 0, 1, l_blue.patch (l_green))
			assert_cell_style ("thumb", l_buf, 0, 2, l_blue.patch (l_red))
			assert_cell_style ("track", l_buf, 0, 3, l_blue)
			create l_buf.make (5, 1)
			(create {TUI_SLIDER}).with_style (l_blue).with_thumb_style (l_red).with_focused (True)
				.render_stateful (create {RECT}.make (0, 0, 5, 1), l_buf, s)
			assert_cell_style ("focused over style", l_buf, 0, 4, l_blue.patch (l_rev))
			assert_cell_style ("thumb over focus", l_buf, 0, 2, l_blue.patch (l_rev).patch (l_red))
			create l_buf.make (5, 1)
			(create {TUI_SLIDER}).with_focused (True).with_focused_style (l_green)
				.render_stateful (create {RECT}.make (0, 0, 5, 1), l_buf, s)
			assert_cell_style ("own focused style", l_buf, 0, 0, l_green)
				-- Vertical focused, label below
			create l_buf.make (2, 4)
			(create {TUI_SLIDER}.make_vertical).with_focused (True).with_label_position ({SLIDER_LABEL_POSITION}.right)
				.render_stateful (create {RECT}.make (0, 0, 1, 4), l_buf, s)
			assert_buffer_lines ("vertical focused", l_buf, <<bar ("| "), bar ("o "), bar ("# "), "2 ">>)
			assert_cell_style ("vertical thumb reversed", l_buf, 1, 0, l_rev)
			assert_cell_style ("vertical label reversed", l_buf, 3, 0, l_rev)
			assert_cell_style ("vertical outside", l_buf, 1, 1, create {STYLE})
				-- Vertical in a 3-column area with a 2-column label: the label's two cells and the
				-- track reversed, the cells beside the track untouched
			create s.make (0, 10, 1)
			s.set_value (10)
			create l_buf.make (3, 3)
			(create {TUI_SLIDER}.make_vertical).with_focused (True).with_label_position ({SLIDER_LABEL_POSITION}.left)
				.render_stateful (create {RECT}.make (0, 0, 3, 3), l_buf, s)
			assert_buffer_lines ("vertical wide label", l_buf, <<"10 ", bar ("o  "), bar ("#  ")>>)
			assert_cell_style ("label first reversed", l_buf, 0, 0, l_rev)
			assert_cell_style ("label second reversed", l_buf, 0, 1, l_rev)
			assert_cell_style ("after the label untouched", l_buf, 0, 2, create {STYLE})
			assert_cell_style ("track reversed", l_buf, 2, 0, l_rev)
			assert_cell_style ("beside the track untouched", l_buf, 1, 1, create {STYLE})
		end

	test_slider_track_does_not_move_with_the_value
			-- The label width does not depend on the value, so `track_area` is the same for
			-- every value: with the default `out` (-5 .. 100: the ends' texts are the widest),
			-- and with a `label_format` whose middle values are wider than the ends ("0",
			-- "50 units", "100"), where a too-wide text is left out instead of cut. With
			-- `with_label_width` the reserved columns hold the widest text.
		local
			s: SLIDER_STATE
			h, f: TUI_SLIDER
			l_area, l_track: RECT
			l_buf: BUFFER
			v: INTEGER_64
		do
			create l_area.make (0, 0, 20, 1)
			create s.make (-5, 100, 1)
			h := (create {TUI_SLIDER}).with_label_position ({SLIDER_LABEL_POSITION}.right)
			l_track := h.track_area (l_area, s)
			from v := -5 until v > 100 loop
				s.set_value (v)
				assert ("default out: same track at " + v.out, h.track_area (l_area, s) ~ l_track)
				assert ("default out: fits at " + v.out, h.label_fits (s))
				v := v + 1
			end
			assert ("default width from the ends", h.label_width (s) = 3)

			create s.make (0, 100, 1)
			f := h.with_label_format (agent (a_v: INTEGER_64): READABLE_STRING_GENERAL
				do
					if a_v = 0 or a_v = 100 then
						Result := a_v.out
					else
						Result := a_v.out + " units"
					end
				end)
			l_track := f.track_area (l_area, s)
			assert ("format: width from the ends", f.label_width (s) = 3)
			s.set_value (50)
			assert ("format: same track in the middle", f.track_area (l_area, s) ~ l_track)
			assert ("format: middle text does not fit", not f.label_fits (s))
			create l_buf.make (20, 1)
			f.render_stateful (l_area, l_buf, s)
			assert_buffer_lines ("too wide: left out, not cut", l_buf, <<bar ("========o-------    ")>>)
			s.set_to_maximum
			create l_buf.make (20, 1)
			f.render_stateful (l_area, l_buf, s)
			assert_buffer_lines ("end text shown", l_buf, <<bar ("===============o 100")>>)

				-- A fixed width for the format's widest text
			f := f.with_label_width (9)
			assert ("fixed width", f.label_width (s) = 9 and f.fixed_label_width = 9)
			s.set_value (50)
			create l_buf.make (20, 1)
			f.render_stateful (l_area, l_buf, s)
			assert_buffer_lines ("fixed: middle text shown", l_buf, <<bar ("=====o---- 50 units ")>>)
			s.set_value (0)
			assert ("fixed: same track at 0", f.track_area (l_area, s) ~ create {RECT}.make (0, 0, 10, 1))
			assert ("width in equality", not (f ~ f.with_label_width (0)))
			assert ("negative width refused", raises (agent f.set_label_width (-1)))
		end

	test_slider_zero_and_clipped_areas
			-- Zero-size areas and areas outside the buffer draw nothing; an area past the right
			-- or the bottom is cut, the track laid out on the whole area; wide characters already
			-- in the buffer are repaired.
		local
			l_buf: BUFFER
			s: SLIDER_STATE
		do
			create s.make (0, 100, 1)
			s.set_value (50)
			create l_buf.make (4, 2)
			(create {TUI_SLIDER}).render_stateful (create {RECT}.make (0, 0, 0, 2), l_buf, s)
			(create {TUI_SLIDER}).render_stateful (create {RECT}.make (0, 0, 4, 0), l_buf, s)
			(create {TUI_SLIDER}.make_vertical).render_stateful (create {RECT}.make (0, 0, 0, 0), l_buf, s)
			(create {TUI_SLIDER}).render_stateful (create {RECT}.make (4, 0, 3, 1), l_buf, s)
			(create {TUI_SLIDER}).render_stateful (create {RECT}.make (0, 2, 3, 1), l_buf, s)
			assert_buffer_lines ("nothing", l_buf, <<"    ", "    ">>)
				-- 11 wide from column 0 in a 4-column buffer: the thumb (cell 5) is off screen
			create l_buf.make (4, 1)
			(create {TUI_SLIDER}).render_stateful (create {RECT}.make (0, 0, 11, 1), l_buf, s)
			assert_buffer_lines ("past right", l_buf, <<bar ("====")>>)
				-- A vertical track of 5 rows from row 0 in a 3-row buffer: the bottom two cut
			create l_buf.make (1, 3)
			(create {TUI_SLIDER}.make_vertical).render_stateful (create {RECT}.make (0, 0, 1, 5), l_buf, s)
			assert_buffer_lines ("past bottom", l_buf, <<bar ("|"), bar ("|"), bar ("o")>>)
				-- From row 2 in a 3-row buffer: only the top cell (the maximum end)
			create l_buf.make (1, 3)
			(create {TUI_SLIDER}.make_vertical).render_stateful (create {RECT}.make (0, 2, 1, 5), l_buf, s)
			assert_buffer_lines ("top only", l_buf, <<" ", " ", bar ("|")>>)
				-- One cell
			create l_buf.make (1, 1)
			(create {TUI_SLIDER}).render_stateful (create {RECT}.make (0, 0, 1, 1), l_buf, s)
			assert_buffer_lines ("one cell", l_buf, <<bar ("o")>>)
				-- Over wide characters
			create l_buf.make (6, 1)
			l_buf.put_string (0, 0, {STRING_32} "%/0x4E16/%/0x754C/%/0x4E16/", create {STYLE})
			(create {TUI_SLIDER}).render_stateful (create {RECT}.make (1, 0, 3, 1), l_buf, s)
			assert ("wide repaired", l_buf.is_consistent)
			assert_buffer_lines ("wide", l_buf, <<{STRING_32} " " + bar ("=o-") + {STRING_32} "%/0x4E16/">>)
				-- A label over wide characters, cut at the right of the buffer
			create l_buf.make (6, 1)
			l_buf.put_string (0, 0, {STRING_32} "%/0x4E16/%/0x754C/%/0x4E16/", create {STYLE})
			(create {TUI_SLIDER}).with_label_position ({SLIDER_LABEL_POSITION}.right)
				.render_stateful (create {RECT}.make (0, 0, 9, 1), l_buf, s)
			assert ("label cut consistent", l_buf.is_consistent)
			assert_buffer_lines ("label cut at the buffer", l_buf, <<bar ("==o-- ")>>)
		end

	test_slider_builders_equality
			-- Defaults, the glyphs per direction, each `with_*` on a copy, `is_equal` (format by
			-- reference, hit id), one-column symbols only.
		local
			h, h2: TUI_SLIDER
			f: FUNCTION [INTEGER_64, READABLE_STRING_GENERAL]
			l_id: WIDGET_ID
		do
			create h
			assert ("defaults", h.direction = {SLIDER_DIRECTION}.horizontal and h.label_position = {SLIDER_LABEL_POSITION}.none
				and not h.is_focused and h.hit_id = Void and h.label_format = Void)
			assert ("h glyphs", h.track_glyph.same_string (bar ("-")) and h.filled_glyph.same_string (bar ("="))
				and h.thumb_glyph.same_string (bar ("o")))
			assert ("v glyphs", h.with_direction ({SLIDER_DIRECTION}.vertical).track_glyph.same_string (bar ("|"))
				and (create {TUI_SLIDER}.make_vertical).filled_glyph.same_string (bar ("#")))
			assert ("one-column defaults", h.is_valid_symbol (h.track_glyph) and h.is_valid_symbol (h.filled_glyph)
				and h.is_valid_symbol (h.thumb_glyph) and h.is_valid_symbol (bar ("|")) and h.is_valid_symbol (bar ("#")))
			assert ("wide symbol not valid", not h.is_valid_symbol ({STRING_32} "%/0x4E16/") and not h.is_valid_symbol ("ab"))
			create h2
			assert ("equal", h ~ h2)
			assert ("focused differs", not (h ~ h.with_focused (True)) and h.with_focused (True).is_focused and not h.is_focused)
			assert ("direction differs", not (h ~ h.with_direction ({SLIDER_DIRECTION}.vertical)))
			assert ("label differs", not (h ~ h.with_label_position ({SLIDER_LABEL_POSITION}.left)))
			assert ("symbol differs", not (h ~ h.with_thumb_symbol ("*")) and h.thumb_symbol = Void)
			assert ("same symbol equal", h.with_thumb_symbol ("*") ~ h2.with_thumb_symbol ("*"))
			assert ("default again", h.with_thumb_symbol ("*").with_thumb_symbol (Void) ~ h)
			assert ("style differs", not (h ~ h.with_filled_style (create {STYLE}.make_fg ({COLOR}.red)))
				and not (h ~ h.with_thumb_style (create {STYLE}.make_fg ({COLOR}.red)))
				and not (h ~ h.with_style (create {STYLE}.make_fg ({COLOR}.red)))
				and not (h ~ h.with_focused_style (create {STYLE})))
			f := agent (v: INTEGER_64): STRING do Result := v.out end
			assert ("format by reference", h.with_label_format (f) ~ h2.with_label_format (f)
				and not (h ~ h.with_label_format (f)))
			create l_id.make (3)
			assert ("hit id", not (h ~ h.with_hit_id (l_id)) and h.with_hit_id (l_id) ~ h2.with_hit_id (create {WIDGET_ID}.make (3)))
			assert ("label text", h.label_text (42).same_string ("42")
				and h.with_label_format (agent (v: INTEGER_64): STRING do Result := "v=" + v.out end).label_text (-3).same_string ("v=-3"))
			assert ("label width without a label", h.label_width (create {SLIDER_STATE}) = 0)
			assert ("label width", h.with_label_position ({SLIDER_LABEL_POSITION}.right).label_width (create {SLIDER_STATE}.make (-1000, 5, 1)) = 5)
			assert ("valid constants", {SLIDER_DIRECTION}.is_valid (1) and {SLIDER_DIRECTION}.is_valid (2) and not {SLIDER_DIRECTION}.is_valid (0)
				and {SLIDER_LABEL_POSITION}.is_valid (0) and {SLIDER_LABEL_POSITION}.is_valid (2) and not {SLIDER_LABEL_POSITION}.is_valid (3))
		end

feature -- Interaction

	test_slider_registers_its_hit_region
			-- With a `hit_id`, `content_area` (the track and the label) is registered; without
			-- one, nothing. Rows of a taller area below the track miss; a vertical slider's
			-- region is its column, as wide as its label.
		local
			l_frame: FRAME
			l_id: WIDGET_ID
			s: SLIDER_STATE
			h: TUI_SLIDER
		do
			create l_frame.make (create {BUFFER}.make (20, 4))
			create l_id.make (5)
			create s
			create h
			l_frame.render_stateful_widget (h, create {RECT}.make (0, 0, 10, 1), s)
			assert ("no id, no region", l_frame.hit_map.is_empty)
			h := h.with_label_position ({SLIDER_LABEL_POSITION}.left)
			l_frame.render_stateful_widget (h.with_hit_id (l_id), create {RECT}.make (2, 1, 12, 1), s)
			assert ("label hit", attached l_frame.hit_map.hit (2, 1) as id and then id ~ l_id)
			assert ("track start hit", attached l_frame.hit_map.hit (6, 1) as id and then id ~ l_id)
			assert ("track end hit", attached l_frame.hit_map.hit (13, 1) as id and then id ~ l_id)
			assert ("right miss", l_frame.hit_map.hit (14, 1) = Void)
			assert ("below miss", l_frame.hit_map.hit (5, 2) = Void)
			assert ("label not on track", not h.is_on_track (create {RECT}.make (2, 1, 12, 1), s, 5, 1)
				and h.is_on_track (create {RECT}.make (2, 1, 12, 1), s, 6, 1))
			assert ("with_hit_id copies", h.hit_id = Void)
				-- A taller area: only the track's row is registered
			create l_frame.make (create {BUFFER}.make (20, 4))
			l_frame.render_stateful_widget (h.with_hit_id (l_id), create {RECT}.make (2, 1, 12, 3), s)
			assert ("tall: track hit", attached l_frame.hit_map.hit (6, 1) as id and then id ~ l_id)
			assert ("tall: second row misses", l_frame.hit_map.hit (6, 2) = Void)
			assert ("tall: third row misses", l_frame.hit_map.hit (6, 3) = Void)
				-- Vertical, label "100" above a 1-column track in a 5-column area: 3 columns
			create l_frame.make (create {BUFFER}.make (20, 6))
			l_frame.render_stateful_widget ((create {TUI_SLIDER}.make_vertical).with_label_position ({SLIDER_LABEL_POSITION}.left)
				.with_hit_id (l_id), create {RECT}.make (2, 1, 5, 4), s)
			assert ("vertical: label hit", attached l_frame.hit_map.hit (4, 1) as id and then id ~ l_id)
			assert ("vertical: track bottom hit", attached l_frame.hit_map.hit (2, 4) as id and then id ~ l_id)
			assert ("vertical: after the label misses", l_frame.hit_map.hit (5, 1) = Void)
			assert ("vertical: area's last column misses", l_frame.hit_map.hit (6, 3) = Void)
			assert ("vertical: hit area", (create {TUI_SLIDER}.make_vertical).with_label_position ({SLIDER_LABEL_POSITION}.left)
				.hit_area (create {RECT}.make (2, 1, 5, 4), s) ~ create {RECT}.make (2, 1, 3, 4))
		end

	test_slider_click_and_drag
			-- The class note's recipe, scripted on a fixed viewport at screen (10, 3): a press on
			-- the track jumps there, drags follow the pointer (past the end too, and off the
			-- track's row), a release ends the drag, a later drag does nothing, a press beside
			-- the slider misses; then keys move the focused slider.
		local
			l_app: TEST_TUI_APP_IMPL
		do
			create drag_focus.make
			drag_focus.register (Slider_id)
			create drag_state.make (0, 100, 1)
			drag_log.wipe_out
				-- Slider at frame (2, 1), 11 wide: the track is screen columns 12 .. 22 of row 4.
				-- Press at cell 5 (screen 17, 4); drag to cell 8 (20, 4); drag past the end
				-- (35, 4); drag back to cell 1 on another row (13, 6); release; drag (17, 4) with
				-- no button down; press beside the slider (25, 4); Right, Page Up, End, Home,
				-- Right; q. SGR is 1-based.
			l_app := new_app (Esc + "[<0;18;5M" + Esc + "[<32;21;5M" + Esc + "[<32;36;5M" + Esc + "[<32;14;7M"
				+ Esc + "[<0;14;7m" + Esc + "[<32;18;5M" + Esc + "[<0;26;5M"
				+ Esc + "[C" + Esc + "[5~" + Esc + "[F" + Esc + "[H" + Esc + "[C" + "q",
				create {VIEWPORT}.make_fixed (create {RECT}.make (10, 3, 30, 5)))
			l_app.set_draw_hook (agent draw_slider)
			l_app.set_mouse_hook (agent on_slider_mouse (?, l_app))
			l_app.set_key_hook (agent on_slider_key)
				-- Every drag delivered, none merged into the next (the queue merges waiting
				-- drags by default), so each one's value can be checked
			l_app.set_event_coalescing (False)
			l_app.run
			assert_log (<<"down 50", "drag 80", "drag 100", "drag 10", "up 10", "drag ignored 10", "miss 10",
				"key 11", "key 21", "key 100", "key 0", "key 1">>)
			assert ("final value", drag_state.value = 1)
			assert ("focused", drag_focus.is_focused (Slider_id))
		end

feature {NONE} -- Drag support

	drag_focus: FOCUS_MANAGER
			-- Focus ring of `test_slider_click_and_drag`
		attribute
			create Result.make
		end

	drag_state: SLIDER_STATE
			-- The application's slider state
		attribute
			create Result
		end

	is_dragging: BOOLEAN
			-- Did a press on the track start a drag that is not released yet?

	drag_log: ARRAYED_LIST [STRING]
			-- What each mouse or key event did, with the value after it
		attribute
			create Result.make (12)
			Result.compare_objects
		end

	drag_slider: TUI_SLIDER
			-- The slider of `test_slider_click_and_drag`
		do
			Result := (create {TUI_SLIDER}).with_focused (drag_focus.is_focused (Slider_id)).with_hit_id (Slider_id)
		end

	drag_area: RECT
			-- Where the slider is drawn, in frame coordinates
		once
			create Result.make (2, 1, 11, 1)
		end

	draw_slider (a_frame: FRAME)
			-- Draw the slider from the application's state.
		do
			a_frame.render_stateful_widget (drag_slider, drag_area, drag_state)
		end

	on_slider_mouse (m: MOUSE_EVENT; a: TEST_TUI_APP_IMPL)
			-- The class note's mouse recipe.
		local
			col, row: INTEGER
			l_slider: TUI_SLIDER
		do
			if attached a.terminal.shown_area as l_shown then
				col := m.column.to_integer_32 - l_shown.x.to_integer_32
				row := m.row.to_integer_32 - l_shown.y.to_integer_32
			end
			l_slider := drag_slider
			if m.is_down then
				if drag_focus.focus_at (a.hit_test (m)) and then drag_focus.is_focused (Slider_id)
					and then l_slider.is_on_track (drag_area, drag_state, col, row)
				then
					is_dragging := True
					drag_state.set_from_position (l_slider.track_cell (drag_area, drag_state, col, row),
						l_slider.track_length (drag_area, drag_state))
					drag_log.extend ("down " + drag_state.value.out)
				else
					drag_log.extend ("miss " + drag_state.value.out)
				end
			elseif m.is_drag then
				if is_dragging then
					drag_state.set_from_position (l_slider.track_cell (drag_area, drag_state, col, row),
						l_slider.track_length (drag_area, drag_state))
					drag_log.extend ("drag " + drag_state.value.out)
				else
					drag_log.extend ("drag ignored " + drag_state.value.out)
				end
			elseif m.is_up then
				is_dragging := False
				drag_log.extend ("up " + drag_state.value.out)
			end
		end

	on_slider_key (k: KEY_EVENT)
			-- The class note's key recipe.
		do
			if k.is_press and then drag_focus.is_focused (Slider_id) and then not k.code.is_char then
				if k.code.is_right or k.code.is_up then
					drag_state.increase
				elseif k.code.is_left or k.code.is_down then
					drag_state.decrease
				elseif k.code.is_page_up then
					drag_state.increase_page
				elseif k.code.is_page_down then
					drag_state.decrease_page
				elseif k.code.is_home then
					drag_state.set_to_minimum
				elseif k.code.is_end then
					drag_state.set_to_maximum
				end
				drag_log.extend ("key " + drag_state.value.out)
			end
		end

	assert_log (a_expected: ARRAY [STRING])
			-- `drag_log` is exactly `a_expected`, in order.
		local
			i: INTEGER
		do
			assert ("log has " + a_expected.count.out + " entries, not " + drag_log.count.out,
				drag_log.count = a_expected.count)
			from i := 1 until i > a_expected.count or i > drag_log.count loop
				assert ("entry " + i.out + " is " + a_expected [i] + ", not " + drag_log [i], drag_log [i] ~ a_expected [i])
				i := i + 1
			end
		end

	Slider_id: WIDGET_ID
			-- Id of the slider in `test_slider_click_and_drag`
		once
			create Result.make (11)
		end

feature {NONE} -- Helpers

	raises (a_action: PROCEDURE): BOOLEAN
			-- Does `a_action` raise an exception?
		local
			l_tried: BOOLEAN
		do
			if not l_tried then
				a_action.call
			end
		rescue
			l_tried := True
			Result := True
			retry
		end


	bar (a_pattern: STRING): STRING_32
			-- `a_pattern` with '=' as U+2501, '-' as U+2500, '#' as U+2503, '|' as U+2502 and
			-- 'o' as U+25CF; other characters as they are.
		local
			i: INTEGER
		do
			create Result.make (a_pattern.count)
			from i := 1 until i > a_pattern.count loop
				inspect a_pattern [i]
				when '=' then Result.append_character ((0x2501).to_character_32)
				when '-' then Result.append_character ((0x2500).to_character_32)
				when '#' then Result.append_character ((0x2503).to_character_32)
				when '|' then Result.append_character ((0x2502).to_character_32)
				when 'o' then Result.append_character ((0x25CF).to_character_32)
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
