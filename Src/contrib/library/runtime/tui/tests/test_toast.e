note
	description: "[
		P2 item W5, TUI_TOAST and TOAST_QUEUE (review/p2_terminal_widgets_plan.md).
		Ratatui has no toast widget, so these are EiffelTUI's own tests:
		  * the queue, driven by times the test passes (it never reads a clock): expiry at
		    exactly the duration and one millisecond before, order, `max_visible` (later toasts
		    wait, their clocks not started), pushing from the expiry action;
		  * row-exact buffer snapshots: each corner and the top / bottom centre, long text
		    wrapped, a toast wider than the area, a toast cut by the area and by the buffer;
		  * styles, the theme, the `with_*` builders and the preconditions.
		Box glyphs (plain): U+250C, U+2500, U+2510, U+2502, U+2514, U+2518. Snapshots fill the
		buffer with '.' first, so the cleared underlay shows.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_TOAST

inherit
	BUFFER_TEST_HELPER

feature -- Queue

	test_toast_queue_expiry_at_exact_duration
			-- A toast starts at the first `expire` after it is pushed (never at the queue's last,
			-- older time); started at t for d ms it is kept at t + d - 1 and dropped at t + d;
			-- times near both ends of INTEGER_64 do not overflow.
		local
			q: TOAST_QUEUE
		do
			create q.make_at (900)
			q.push ("saved", {TOAST_LEVEL}.success, 3000)
			assert ("not started at push", not q.item (1).is_started)
			q.expire (1000)
			assert ("started at the next expire, not at 900", q.item (1).is_started and q.item (1).started_at_ms = 1000)
			q.expire (3999)
			assert ("kept 1 ms before", q.count = 1 and q.last_expired.is_empty)
			q.expire (4000)
			assert ("dropped at the duration", q.is_empty)
			assert ("reported", q.last_expired.count = 1 and then q.last_expired.first.text.to_plain_string.same_string ("saved"))
			q.expire (4000)
			assert ("same time again", q.is_empty and q.last_expired.is_empty)

				-- No time yet: the clock starts at the first `expire`
			create q
			q.push ("early", {TOAST_LEVEL}.info, 100)
			assert ("no time, not started", not q.has_time and not q.item (1).is_started)
			q.expire (500)
			assert ("started at first expire", q.item (1).is_started and q.item (1).started_at_ms = 500 and q.now_ms = 500)
			q.expire (599)
			assert ("kept at 599", q.count = 1)
			q.expire (600)
			assert ("dropped at 600", q.is_empty)

				-- Near INTEGER_64.max_value
			create q.make_at ({INTEGER_64}.max_value - 10)
			q.push ("late", {TOAST_LEVEL}.info, 5)
			q.expire ({INTEGER_64}.max_value - 10)
			q.expire ({INTEGER_64}.max_value - 6)
			assert ("kept near max", q.count = 1)
			q.expire ({INTEGER_64}.max_value - 5)
			assert ("dropped near max", q.is_empty)

				-- From INTEGER_64.min_value for INTEGER_64.max_value ms: the distance is 2^63 - 1
			create q.make_at ({INTEGER_64}.min_value)
			q.push ("long", {TOAST_LEVEL}.info, {INTEGER_64}.max_value)
			q.expire ({INTEGER_64}.min_value)
			q.expire (-2)
			assert ("kept across zero", q.count = 1)
			q.expire (-1)
			assert ("dropped after 2^63 - 1 ms", q.is_empty)
		end

	test_toast_queue_order
			-- Toasts stay oldest first; toasts dropped together are reported oldest first;
			-- `dismiss` removes one and keeps the order of the others.
		local
			q: TOAST_QUEUE
		do
			create q.make_at (0)
			q.set_max_visible (5)
			q.push ("a", {TOAST_LEVEL}.info, 300)
			q.push ("b", {TOAST_LEVEL}.success, 100)
			q.push ("c", {TOAST_LEVEL}.warning, 500)
			q.push ("d", {TOAST_LEVEL}.error, 100)
			q.expire (0)
			assert_texts ("pushed", q, <<"a", "b", "c", "d">>)
			assert ("levels", q.item (1).level = {TOAST_LEVEL}.info and q.item (4).level = {TOAST_LEVEL}.error)
			q.expire (100)
			assert_texts ("b and d gone", q, <<"a", "c">>)
			assert ("reported oldest first", q.last_expired.count = 2
				and then (q.last_expired.i_th (1).text.to_plain_string.same_string ("b")
				and q.last_expired.i_th (2).text.to_plain_string.same_string ("d")))
			q.push ("e", {TOAST_LEVEL}.info, 1000)
			assert ("e not started at push", not q.item (3).is_started)
			q.expire (100)
			assert ("e started at the next expire", q.item (3).started_at_ms = 100)
			assert_texts ("e last", q, <<"a", "c", "e">>)
			q.dismiss (2)
			assert_texts ("c dismissed", q, <<"a", "e">>)
			q.expire (300)
			assert_texts ("a gone", q, <<"e">>)
			q.clear
			assert ("cleared", q.is_empty)
				-- Multi-line text
			q.push ("one%Ntwo", {TOAST_LEVEL}.info, 10)
			assert ("two lines", q.item (1).text.line_count = 2)
		end

	test_toast_queue_max_visible
			-- Toasts past `max_visible` wait, in order, with their clocks stopped; none is
			-- dropped. A waiting toast starts when an older one expires or is dismissed, and is
			-- then shown for its whole duration. Changing `max_visible` starts or stops clocks.
		local
			q: TOAST_QUEUE
			i: INTEGER
		do
			create q.make_at (0)
			assert ("default bound", q.max_visible = 3)
			q.set_max_visible (2)
			q.push ("1", {TOAST_LEVEL}.info, 100)
			q.push ("2", {TOAST_LEVEL}.info, 100)
			q.push ("3", {TOAST_LEVEL}.info, 100)
			q.push ("4", {TOAST_LEVEL}.info, 100)
			q.expire (0)
			assert ("2 shown, 2 waiting", q.visible_count = 2 and q.waiting_count = 2 and q.count = 4)
			assert ("shown started", q.item (1).is_started and q.item (2).is_started)
			assert ("waiting not started", not q.item (3).is_started and not q.item (4).is_started)
			assert ("visibility", q.is_visible (2) and not q.is_visible (3))
			q.expire (50)
			assert ("nothing yet", q.count = 4)
			q.expire (100)
			assert_texts ("first two gone", q, <<"3", "4">>)
			assert ("3 and 4 started at 100", q.item (1).started_at_ms = 100 and q.item (2).started_at_ms = 100)
			q.expire (199)
			assert ("whole duration: kept at 199", q.count = 2)
			q.expire (200)
			assert ("gone at 200", q.is_empty)

				-- Dismiss promotes the next one
			q.push ("5", {TOAST_LEVEL}.info, 100)
			q.push ("6", {TOAST_LEVEL}.info, 100)
			q.push ("7", {TOAST_LEVEL}.info, 100)
			q.expire (200)
			q.expire (250)
			q.dismiss (1)
			assert ("7 shown, its time not started yet", q.item (2).text.to_plain_string.same_string ("7")
				and q.is_visible (2) and not q.item (2).is_started)
			q.expire (260)
			assert ("7 started at the next expire", q.item (2).is_started and q.item (2).started_at_ms = 260)
			q.expire (300)
			assert_texts ("6 gone, 7 kept", q, <<"7">>)

				-- Lower and raise the bound
			q.push ("8", {TOAST_LEVEL}.info, 100)
			q.expire (300)
			assert ("8 started", q.item (2).is_started)
			q.set_max_visible (1)
			assert ("8 stopped", not q.item (2).is_started)
			q.expire (340)
			q.set_max_visible (3)
			q.expire (340)
			assert ("8 started again at 340", q.item (2).is_started and q.item (2).started_at_ms = 340)
			q.expire (359)
			assert_texts ("7 kept until 360", q, <<"7", "8">>)

				-- A burst: none dropped
			create q.make_at (0)
			from i := 1 until i > 10 loop
				q.push (i.out, {TOAST_LEVEL}.info, 10)
				i := i + 1
			end
			q.expire (0)
			assert ("10 kept", q.count = 10 and q.visible_count = 3 and q.waiting_count = 7)
			from i := 1 until q.is_empty or i > 10 loop
				q.expire (i * 10)
				i := i + 1
			end
			assert ("three at a time, every 10 ms", q.is_empty and i = 5)
		end

	test_toast_queue_push_during_expire
			-- The expiry action runs once the queue is consistent: it may push (a follow-up
			-- starts at the next `expire`), and every toast dropped by the call is still
			-- reported. With no room, the follow-up waits.
		local
			q: TOAST_QUEUE
			l_seen: ARRAYED_LIST [STRING_32]
		do
			create l_seen.make (2)
			create q.make_at (0)
			q.set_expired_action (agent (t: TOAST; a_q: TOAST_QUEUE; a_seen: ARRAYED_LIST [STRING_32])
				do
					a_seen.extend (t.text.to_plain_string)
					a_q.push ({STRING_32} "after " + t.text.to_plain_string, {TOAST_LEVEL}.info, 50)
				end (?, q, l_seen))
			q.push ("a", {TOAST_LEVEL}.info, 100)
			q.push ("b", {TOAST_LEVEL}.info, 100)
			q.push ("c", {TOAST_LEVEL}.info, 500)
			q.expire (0)
			q.expire (100)
			assert ("both seen", l_seen.count = 2 and then (l_seen.i_th (1).same_string ("a") and l_seen.i_th (2).same_string ("b")))
			assert ("both reported", q.last_expired.count = 2)
			assert_texts ("follow-ups after c", q, <<"c", "after a", "after b">>)
			assert ("follow-ups not started by that expire", not q.item (2).is_started and not q.item (3).is_started)
			q.expire (100)
			assert ("follow-up started at the next", q.item (2).is_started and q.item (2).started_at_ms = 100)
			assert ("all three shown", q.item (3).is_started)
			q.expire (149)
			assert ("follow-ups kept", q.count = 3)
			q.expire (150)
				-- "after a" and "after b" expire, pushing "after after a" and "after after b"
			assert_texts ("second round", q, <<"c", "after after a", "after after b">>)

				-- No room: the follow-up waits
			create l_seen.make (2)
			create q.make_at (0)
			q.set_max_visible (1)
			q.set_expired_action (agent (t: TOAST; a_q: TOAST_QUEUE; a_seen: ARRAYED_LIST [STRING_32])
				do
					a_seen.extend (t.text.to_plain_string)
					if a_seen.count = 1 then
						a_q.push ("follow-up", {TOAST_LEVEL}.info, 50)
					end
				end (?, q, l_seen))
			q.push ("x", {TOAST_LEVEL}.info, 10)
			q.push ("y", {TOAST_LEVEL}.info, 10)
			q.expire (0)
			q.expire (10)
			assert_texts ("y shown, follow-up waits", q, <<"y", "follow-up">>)
			assert ("y started, follow-up not", q.item (1).is_started and not q.item (2).is_started)

				-- The action may clear the queue
			create q.make_at (0)
			q.set_expired_action (agent (t: TOAST; a_q: TOAST_QUEUE) do a_q.clear end (?, q))
			q.push ("p", {TOAST_LEVEL}.info, 10)
			q.push ("q", {TOAST_LEVEL}.info, 99)
			q.expire (0)
			q.expire (10)
			assert ("cleared by the action", q.is_empty and q.last_expired.count = 1)
		end

	test_toast_queue_copy_and_preconditions
			-- A `with_*` copy has its own toasts; bad levels, durations, bounds, indexes and a
			-- time going back are refused.
		local
			q, c: TOAST_QUEUE
		do
			create q.make_at (0)
			q.push ("a", {TOAST_LEVEL}.info, 10)
			q.expire (0)
			assert ("twin equal", q.twin ~ q and q.twin.item (1) /= q.item (1))
			c := q.with_max_visible (1)
			assert ("copy differs", not (c ~ q))
			c.expire (10)
			assert ("copy expired", c.is_empty)
			assert ("original kept", q.count = 1 and q.max_visible = 3 and q.now_ms = 0)
			assert ("level", precondition_raised (agent q.push ("x", 0, 10), "valid_level"))
			assert ("level 5", precondition_raised (agent q.push ("x", 5, 10), "valid_level"))
			assert ("duration", precondition_raised (agent q.push ("x", {TOAST_LEVEL}.info, 0), "positive_duration"))
			assert ("max visible", precondition_raised (agent q.set_max_visible (0), "positive"))
			assert ("dismiss", precondition_raised (agent q.dismiss (2), "valid_index"))
			assert ("dismiss_id", precondition_raised (agent q.dismiss_id (99), "in_queue"))
			q.expire (20)
			assert ("time back", precondition_raised (agent q.expire (19), "time_forward"))
			assert ("levels valid", {TOAST_LEVEL}.is_valid ({TOAST_LEVEL}.error) and not {TOAST_LEVEL}.is_valid (0))
			assert ("positions", {TOAST_POSITION}.is_valid ({TOAST_POSITION}.bottom_right) and not {TOAST_POSITION}.is_valid (7))
		end

	test_toast_queue_ids
			-- Each toast gets the next id and keeps it; dismissing by id removes that toast
			-- whatever expired before it; ids are not reused.
		local
			q: TOAST_QUEUE
		do
			create q.make_at (0)
			assert ("no id yet", q.last_id = 0 and not q.has_id (1))
			q.push ("a", {TOAST_LEVEL}.info, 100)
			q.push ("b", {TOAST_LEVEL}.info, 500)
			q.push ("c", {TOAST_LEVEL}.info, 500)
			assert ("ids in order", q.item (1).id = 1 and q.item (2).id = 2 and q.item (3).id = 3 and q.last_id = 3)
			q.expire (0)
				-- A frame shows c at index 3; "a" expires before the click is handled
			q.expire (100)
			assert ("c moved to 2", q.index_of_id (3) = 2)
			q.dismiss_id (3)
			assert_texts ("c dismissed, not b", q, <<"b">>)
			assert ("gone", not q.has_id (3) and q.has_id (2))
			q.push ("d", {TOAST_LEVEL}.info, 10)
			assert ("not reused", q.item (2).id = 4)
		end

	test_toast_hit_regions
			-- Each box is registered: under `hit_id_base` + its toast's id, or as a blocker by
			-- default, so a click on a toast does not reach what is under it; nothing when
			-- the queue is empty.
		local
			l_frame: FRAME
			q: TOAST_QUEUE
		do
			create q.make_at (0)
			q.push ("Hi", {TOAST_LEVEL}.info, 100)
			q.push ("Yo!", {TOAST_LEVEL}.warning, 100)
			l_frame := new_toast_frame
			l_frame.render_stateful_widget (create {TUI_TOAST}, l_frame.area, q)
			assert ("first box blocks", l_frame.hit_map.hit (10, 1) = Void)
			assert ("second box blocks", l_frame.hit_map.hit (10, 4) = Void)
			assert ("outside: background", attached l_frame.hit_map.hit (2, 6) as l_hit and then l_hit.value = 90)
			l_frame := new_toast_frame
			l_frame.render_stateful_widget ((create {TUI_TOAST}).with_hit_id_base (100), l_frame.area, q)
			assert ("first box: 101", attached l_frame.hit_map.hit (10, 1) as l_hit and then l_hit.value = 101)
			assert ("second box: 102", attached l_frame.hit_map.hit (8, 3) as l_hit and then l_hit.value = 102)
			q.dismiss_id (1)
			l_frame := new_toast_frame
			l_frame.render_stateful_widget ((create {TUI_TOAST}).with_hit_id_base (100), l_frame.area, q)
			assert ("Yo! moved up, still 102", attached l_frame.hit_map.hit (10, 1) as l_hit and then l_hit.value = 102)
			q.clear
			l_frame := new_toast_frame
			l_frame.render_stateful_widget ((create {TUI_TOAST}).with_hit_id_base (100), l_frame.area, q)
			assert ("empty: background", attached l_frame.hit_map.hit (10, 1) as l_hit and then l_hit.value = 90)
			l_frame := new_toast_frame
			l_frame.render_widget (create {TUI_TOAST}, l_frame.area)
			assert ("stateless: nothing", attached l_frame.hit_map.hit (10, 1) as l_hit and then l_hit.value = 90)
		end

	test_toast_line_alignment
			-- Rows are aligned in the box by their own alignment, else the text's.
		local
			l_buf: BUFFER
			q: TOAST_QUEUE
			l_text: TEXT
		do
			create q.make_at (0)
			create l_text.make_raw ("Saved%Nok")
			l_text.set_alignment ({TEXT_ALIGNMENT}.center)
			q.push_text (l_text, {TOAST_LEVEL}.info, 100)
			create l_buf.make (12, 4)
			(create {TUI_TOAST}).with_position ({TOAST_POSITION}.top_left).render_stateful (l_buf.area, l_buf, q)
			assert_buffer_lines ("centred", l_buf, <<
				{STRING_32} "%/0x250C/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2510/     ",
				{STRING_32} "%/0x2502/Saved%/0x2502/     ",
				{STRING_32} "%/0x2502/ ok  %/0x2502/     ",
				{STRING_32} "%/0x2514/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2518/     ">>)
		end

	new_toast_frame: FRAME
			-- A 12 x 8 frame whose whole area is registered under id 90
		do
			create Result.make (create {BUFFER}.make (12, 8))
			Result.register_hit (create {WIDGET_ID}.make (90), Result.area)
		end

feature -- Snapshots

	test_toast_each_position
			-- "Hi" (info) and then "Yo!" (warning) in a 12 x 8 area, at each corner and at the
			-- top and bottom centre. The first toast is next to the edge; boxes shrink to the
			-- text; the cells under each box are cleared.
		do
			check_position ("top left", {TOAST_POSITION}.top_left, 0, 0, 0, 3)
			check_position ("top centre", {TOAST_POSITION}.top_center, 4, 0, 3, 3)
			check_position ("top right", {TOAST_POSITION}.top_right, 8, 0, 7, 3)
			check_position ("bottom left", {TOAST_POSITION}.bottom_left, 0, 5, 0, 2)
			check_position ("bottom centre", {TOAST_POSITION}.bottom_center, 4, 5, 3, 2)
			check_position ("bottom right", {TOAST_POSITION}.bottom_right, 8, 5, 7, 2)
		end

	test_toast_long_text_wrapped
			-- Long text is word-wrapped to `max_width` - 2 columns (blanks trimmed at the
			-- breaks), the box as wide as its widest row; a word longer than the inside is
			-- broken; %N starts a row.
		local
			l_grid: ARRAYED_LIST [STRING_32]
		do
			l_grid := dots (14, 6)
			put_box (l_grid, 0, 0, 9, <<"The quick", "brown fox", "jumps">>)
			check_render ("wrapped", 14, 6, create {RECT}.make (0, 0, 14, 6),
				(create {TUI_TOAST}).with_position ({TOAST_POSITION}.top_left).with_max_width (12),
				<<"The quick brown fox jumps">>, l_grid)
			l_grid := dots (14, 6)
			put_box (l_grid, 2, 0, 10, <<"abcdefghij", "klmnop">>)
			check_render ("long word", 14, 6, create {RECT}.make (0, 0, 14, 6),
				(create {TUI_TOAST}).with_max_width (12), <<"abcdefghijklmnop">>, l_grid)
			l_grid := dots (14, 6)
			put_box (l_grid, 0, 2, 3, <<"one", "two">>)
			check_render ("two lines", 14, 6, create {RECT}.make (0, 0, 14, 6),
				(create {TUI_TOAST}).with_position ({TOAST_POSITION}.bottom_left), <<"one%Ntwo">>, l_grid)
				-- A wide character: the inside is counted in columns
			l_grid := dots (14, 6)
			put_box (l_grid, 0, 0, 4, <<{STRING_32} "ab%/0x4E16/", {STRING_32} "%/0x754C/">>)
			check_render ("wide", 14, 6, create {RECT}.make (0, 0, 14, 6),
				(create {TUI_TOAST}).with_position ({TOAST_POSITION}.top_left).with_max_width (6),
				<<{STRING_32} "ab%/0x4E16/ %/0x754C/">>, l_grid)
		end

	test_toast_wider_than_area
			-- A toast wider than the area is wrapped to the area's width; one taller than the
			-- rows left is cut (box closed, later toasts not drawn); an area narrower or lower
			-- than 3 draws nothing; an area past the buffer is cut by the buffer.
		local
			l_grid: ARRAYED_LIST [STRING_32]
			l_toast: TUI_TOAST
			q: TOAST_QUEUE
		do
			l_grid := dots (10, 6)
			put_box (l_grid, 2, 0, 5, <<"hello", "world", "again">>)
			check_render ("wrapped to the area", 10, 6, create {RECT}.make (1, 0, 8, 6),
				create {TUI_TOAST}, <<"hello world again">>, l_grid)

				-- Cut to the 4 rows of the area; the second toast is not drawn
			l_grid := dots (10, 6)
			put_box (l_grid, 3, 0, 5, <<"hello", "world">>)
			check_render ("cut", 10, 6, create {RECT}.make (0, 0, 10, 4),
				create {TUI_TOAST}.make, <<"hello world again", "next">>, l_grid)
			create q.make_at (0)
			q.push ("hello world again", {TOAST_LEVEL}.info, 10)
			q.push ("next", {TOAST_LEVEL}.info, 10)
			create l_toast
			assert ("one box", l_toast.toast_areas (create {RECT}.make (0, 0, 10, 4), q).count = 1)
			assert ("cut box", l_toast.toast_areas (create {RECT}.make (0, 0, 10, 4), q).first ~ create {RECT}.make (3, 0, 7, 4))
			assert ("both fit", l_toast.toast_areas (create {RECT}.make (0, 0, 10, 8), q).count = 2)
			assert ("second below", l_toast.toast_areas (create {RECT}.make (0, 0, 10, 8), q).i_th (2) ~ create {RECT}.make (4, 5, 6, 3))

				-- Too narrow, too low: nothing
			check_render ("2 wide", 10, 6, create {RECT}.make (0, 0, 2, 6), create {TUI_TOAST}, <<"hello">>, dots (10, 6))
			check_render ("2 high", 10, 6, create {RECT}.make (0, 0, 10, 2), create {TUI_TOAST}, <<"hello">>, dots (10, 6))
			check_render ("empty", 10, 6, create {RECT}.make (0, 0, 0, 0), create {TUI_TOAST}, <<"hello">>, dots (10, 6))
			assert ("no box when narrow", l_toast.toast_areas (create {RECT}.make (0, 0, 2, 6), q).is_empty)
				-- 3 wide: one column of text
			l_grid := dots (10, 6)
			put_box (l_grid, 0, 0, 1, <<"a", "b">>)
			check_render ("3 wide", 10, 6, create {RECT}.make (0, 0, 3, 6), create {TUI_TOAST}, <<"ab">>, l_grid)

				-- Past the buffer's right edge: the box is closed at the edge, the text clipped
			l_grid := dots (10, 5)
			l_grid [1] := {STRING_32} "...." + tl + h (4) + tr
			l_grid [2] := {STRING_32} "...." + v + "hell" + v
			l_grid [3] := {STRING_32} "...." + bl + h (4) + br
			check_render ("past the buffer", 10, 5, create {RECT}.make (4, 0, 20, 5),
				(create {TUI_TOAST}).with_position ({TOAST_POSITION}.top_left), <<"hello world again">>, l_grid)
		end

	test_toast_styles_and_theme
			-- The border takes the level's style, `style` is patched over the box (the cleared
			-- cells), the text's own styles are patched over that; `with_theme` takes the
			-- theme's base and level styles.
		local
			l_buf: BUFFER
			q: TOAST_QUEUE
			l_theme: TUI_THEME
			l_text: TEXT
		do
			create q.make_at (0)
			q.push ("i", {TOAST_LEVEL}.info, 10)
			q.push ("s", {TOAST_LEVEL}.success, 10)
			q.push ("w", {TOAST_LEVEL}.warning, 10)
			q.set_max_visible (4)
			q.push ("e", {TOAST_LEVEL}.error, 10)
			create l_buf.make (3, 12)
			l_buf.set_style (l_buf.area, create {STYLE}.make_bg ({COLOR}.blue))
			(create {TUI_TOAST}).render_stateful (l_buf.area, l_buf, q)
			assert_cell_style ("info border", l_buf, 0, 0, create {STYLE}.make_fg ({COLOR}.cyan))
			assert_cell_style ("success border", l_buf, 4, 2, create {STYLE}.make_fg ({COLOR}.green))
			assert_cell_style ("warning border", l_buf, 6, 1, create {STYLE}.make_fg ({COLOR}.yellow))
			assert_cell_style ("error border", l_buf, 11, 0, create {STYLE}.make_fg ({COLOR}.red))
			assert_cell_style ("text cleared to default", l_buf, 1, 1, create {STYLE})
			assert_cell_symbol ("error text", l_buf, 10, 1, "e")

				-- Theme: the base patched over the box, the theme's level styles on the border
			l_theme := {TUI_THEME}.dark
			create l_buf.make (3, 12)
			(create {TUI_TOAST}).with_theme (l_theme).render_stateful (l_buf.area, l_buf, q)
			assert_cell_style ("theme text", l_buf, 1, 1, l_theme.base)
			assert_cell_style ("theme error border", l_buf, 9, 0, l_theme.base.patch (l_theme.error))
			assert_cell_style ("theme info border", l_buf, 2, 2, l_theme.base.patch (l_theme.info))

				-- Text styles: the TEXT's, then the span's
			create l_text.make (<<create {TEXT_LINE}.make (<<create {TEXT_SPAN}.make_raw ("a"),
				create {TEXT_SPAN}.make ("b", (create {STYLE}).with_bold)>>)>>)
			l_text.set_style (create {STYLE}.make_fg ({COLOR}.magenta))
			create q.make_at (0)
			q.push_text (l_text, {TOAST_LEVEL}.info, 10)
			create l_buf.make (4, 3)
			(create {TUI_TOAST}).with_style (create {STYLE}.make_bg ({COLOR}.blue)).render_stateful (l_buf.area, l_buf, q)
			assert_buffer_lines ("styled text", l_buf, <<tl + h (2) + tr, v + "ab" + v, bl + h (2) + br>>)
			assert_cell_style ("text style over box", l_buf, 1, 1, create {STYLE}.make_with_colors ({COLOR}.magenta, {COLOR}.blue))
			assert_cell_style ("span style on top", l_buf, 1, 2, (create {STYLE}.make_with_colors ({COLOR}.magenta, {COLOR}.blue)).with_bold)
			assert_cell_style ("box style under the border", l_buf, 0, 0, create {STYLE}.make_with_colors ({COLOR}.cyan, {COLOR}.blue))
		end

	test_toast_render_without_queue_and_over_wide_characters
			-- The stateless `render` draws nothing; a box over wide characters already in the
			-- buffer keeps every row consistent; a rounded border.
		local
			l_buf: BUFFER
			q: TOAST_QUEUE
			r: INTEGER
		do
			create l_buf.make (6, 3)
			(create {TUI_TOAST}).render (l_buf.area, l_buf)
			assert_buffer_lines ("nothing", l_buf, <<"      ", "      ", "      ">>)
			create l_buf.make (7, 3)
			from r := 0 until r >= 3 loop
				l_buf.put_string (r, 0, {STRING_32} "%/0x4E16/%/0x4E16/%/0x4E16/", create {STYLE})
				r := r + 1
			end
			create q.make_at (0)
			q.push ("ab", {TOAST_LEVEL}.info, 10)
			(create {TUI_TOAST}).with_position ({TOAST_POSITION}.top_left).with_border_type ({BORDER_TYPE}.rounded)
				.render_stateful (create {RECT}.make (1, 0, 6, 3), l_buf, q)
			assert ("consistent", l_buf.is_consistent)
			assert_buffer_lines ("rounded over wide", l_buf, <<
				{STRING_32} " %/0x256D/" + h (2) + "%/0x256E/  ",
				{STRING_32} " " + v + "ab" + v + "  ",
				{STRING_32} " %/0x2570/" + h (2) + "%/0x256F/  ">>)
		end

	test_toast_builders_and_equality
			-- Defaults, each `with_*` on a copy, `is_equal`, `level_style`, preconditions.
		local
			t, c: TUI_TOAST
		do
			create t
			assert ("defaults", t.position = {TOAST_POSITION}.top_right and t.max_width = 40
				and t.border_type = {BORDER_TYPE}.plain and t.style ~ create {STYLE})
			assert ("default levels", t.level_style ({TOAST_LEVEL}.info) ~ create {STYLE}.make_fg ({COLOR}.cyan)
				and t.level_style ({TOAST_LEVEL}.error) ~ create {STYLE}.make_fg ({COLOR}.red))
			c := t.with_position ({TOAST_POSITION}.bottom_center)
			assert ("position", c.position = {TOAST_POSITION}.bottom_center and t.position = {TOAST_POSITION}.top_right)
			assert ("not equal", not (c ~ t))
			assert ("equal", t ~ create {TUI_TOAST}.make)
			c := t.with_max_width (3)
			assert ("width", c.max_width = 3 and t.max_width = 40)
			c := t.with_level_style ({TOAST_LEVEL}.warning, create {STYLE}.make_fg ({COLOR}.blue))
			assert ("level style", c.warning_style ~ create {STYLE}.make_fg ({COLOR}.blue) and t.warning_style ~ create {STYLE}.make_fg ({COLOR}.yellow))
			assert ("level style differs", not (c ~ t))
			c := t.with_theme ({TUI_THEME}.nord)
			assert ("theme", c.success_style ~ {TUI_THEME}.nord.success and c.style ~ {TUI_THEME}.nord.base)
			c := t.with_style (create {STYLE}.make_bg ({COLOR}.blue)).with_border_type ({BORDER_TYPE}.double)
			assert ("style and border", c.style ~ create {STYLE}.make_bg ({COLOR}.blue) and c.border_type = {BORDER_TYPE}.double)
			assert ("position refused", precondition_raised (agent t.set_position (0), "valid_position"))
			assert ("width refused", precondition_raised (agent t.set_max_width (2), "room_for_text"))
			assert ("level refused", precondition_raised (agent t.set_level_style (9, create {STYLE}), "valid_level"))
			assert ("border refused", precondition_raised (agent t.set_border_type (99), "valid_type"))
			assert ("unchanged", t ~ create {TUI_TOAST})
		end

feature -- Example

	test_toasts_example
			-- EXAMPLE_TOASTS on a 44 x 12 frame with the test's clock: s pushes a success toast
			-- at the top right of the panel, drawn over it; ticks expire it at exactly 3000 ms
			-- and the expiry action counts it; b pushes five (three shown, two waiting); p moves
			-- them to the next position, the bottom left; c clears.
		local
			l_app: TOASTS_SNAPSHOT_APP
			l_buf: BUFFER
			l_backend: ANSI_TERMINAL_BACKEND
		do
			create l_backend.make_with_driver_and_sink (create {FAKE_CONSOLE_DRIVER}, create {STRING_32}.make_empty)
			create l_app.make_on (create {TERMINAL [ANSI_TERMINAL_BACKEND]}.make_with_viewport (l_backend, create {VIEWPORT}.make_fullscreen))
			l_buf := example_frame (l_app)
			assert ("help", buffer_row_as_string (l_buf, 1).has_substring ("i s w e: info, success, warning, error"))
			assert ("status", buffer_row_as_string (l_buf, 7).has_substring ("Shown 0, waiting 0, expired 0"))
			l_app.set_fake_now (980)
			l_app.process_now (create {KEY_EVENT}.make_char ('s'))
			assert ("pushed, not started", l_app.toasts.count = 1 and then not l_app.toasts.item (1).is_started)
			l_app.set_fake_now (1000)
			l_app.process_now (create {TICK_EVENT})
			assert ("started at the next tick", l_app.toasts.item (1).started_at_ms = 1000)
			l_buf := example_frame (l_app)
				-- "Saved settings.toml" is 19 columns: a 21-column box at the right of the inside
			assert ("box top", buffer_row_as_string (l_buf, 1).substring (23, 44).same_string (
				{STRING_32} "%/0x256D/" + h (19) + "%/0x256E/" + v))
			assert ("box text", buffer_row_as_string (l_buf, 2).substring (23, 44).same_string (
				v + "Saved settings.toml" + v + v))
			assert ("panel kept left of the box", buffer_row_as_string (l_buf, 1).substring (1, 22).has_substring ("i s w e"))
			assert_cell_style ("success border", l_buf, 1, 22, {TUI_THEME}.dark.base.patch ({TUI_THEME}.dark.success))
			l_app.set_fake_now (3999)
			l_app.process_now (create {TICK_EVENT})
			assert ("kept at 3999", l_app.toasts.count = 1 and l_app.expired_count = 0)
			l_app.set_fake_now (4000)
			l_app.process_now (create {TICK_EVENT})
			assert ("expired at 4000", l_app.toasts.is_empty and l_app.expired_count = 1)
			l_buf := example_frame (l_app)
			assert ("box gone", not buffer_row_as_string (l_buf, 2).has_substring ("Saved"))
			assert ("status counts it", buffer_row_as_string (l_buf, 7).has_substring ("Shown 0, waiting 0, expired 1"))
			l_app.process_now (create {KEY_EVENT}.make_char ('b'))
			l_buf := example_frame (l_app)
			assert ("five: three shown", l_app.toasts.visible_count = 3 and l_app.toasts.waiting_count = 2)
				-- The third box covers the end of the status line
			assert ("status", buffer_row_as_string (l_buf, 7).has_substring ("Shown 3, waiting 2"))
			assert ("first on top", buffer_row_as_string (l_buf, 2).has_substring ("Message 1 of 5"))
			assert ("third", buffer_row_as_string (l_buf, 8).has_substring ("Message 3 of 5"))
			l_app.process_now (create {KEY_EVENT}.make_char ('p'))
			assert ("bottom left", l_app.position = {TOAST_POSITION}.bottom_left)
			l_buf := example_frame (l_app)
				-- "Message 1 of 5" is 14 columns: a 16-column box on the bottom of the inside
			assert ("first at the bottom", buffer_row_as_string (l_buf, 9).substring (2, 17).same_string (v + "Message 1 of 5" + v))
			assert ("third above", buffer_row_as_string (l_buf, 3).substring (2, 17).same_string (v + "Message 3 of 5" + v))
			l_app.process_now (create {KEY_EVENT}.make_char ('c'))
			assert ("cleared", l_app.toasts.is_empty)
			assert ("consistent", l_buf.is_consistent)
		end

feature {NONE} -- Helpers

	example_frame (a_app: TOASTS_SNAPSHOT_APP): BUFFER
			-- A 44 x 12 frame drawn by `a_app`
		do
			create Result.make (44, 12)
			a_app.render_now (create {FRAME}.make (Result))
		end

	h (a_count: INTEGER): STRING_32
			-- `a_count` plain horizontal line glyphs
		do
			create Result.make_filled ((0x2500).to_character_32, a_count)
		end

	v: STRING_32
			-- Plain vertical line glyph
		do
			Result := {STRING_32} "%/0x2502/"
		end

	tl: STRING_32 do Result := {STRING_32} "%/0x250C/" end
	tr: STRING_32 do Result := {STRING_32} "%/0x2510/" end
	bl: STRING_32 do Result := {STRING_32} "%/0x2514/" end
	br: STRING_32 do Result := {STRING_32} "%/0x2518/" end

	dots (a_width, a_height: INTEGER): ARRAYED_LIST [STRING_32]
			-- `a_height` rows of `a_width` dots
		local
			r: INTEGER
		do
			create Result.make (a_height)
			from r := 1 until r > a_height loop
				Result.extend (create {STRING_32}.make_filled ('.', a_width))
				r := r + 1
			end
		end

	put_box (a_grid: ARRAYED_LIST [STRING_32]; a_x, a_y, a_inside: INTEGER; a_lines: ARRAY [READABLE_STRING_GENERAL])
			-- Draw in `a_grid` a plain box at (`a_x`, `a_y`), `a_inside` columns inside, holding
			-- `a_lines` left-aligned (each made of one-column characters, or of wide ones whose
			-- second column is left out, as BUFFER rows read).
		local
			r, k: INTEGER
			l_row: STRING_32
		do
			replace (a_grid [a_y + 1], a_x, tl + h (a_inside) + tr)
			from k := 1 until k > a_lines.count loop
				create l_row.make (a_inside + 2)
				l_row.append (v)
				l_row.append_string_general (a_lines [k])
				from r := {UNICODE_WIDTH}.string_width (a_lines [k]).to_integer_32 until r >= a_inside loop
					l_row.append_character (' ')
					r := r + 1
				end
				l_row.append (v)
				replace (a_grid [a_y + 1 + k], a_x, l_row)
				k := k + 1
			end
			replace (a_grid [a_y + a_lines.count + 2], a_x, bl + h (a_inside) + br)
		end

	replace (a_row: STRING_32; a_x: INTEGER; a_text: STRING_32)
			-- Write `a_text` over `a_row` from 0-based column `a_x`, one character per column
			-- (a wide character's second column is dropped from `a_row`).
		local
			i, c: INTEGER
			l_w: INTEGER
		do
			c := a_x + 1
			from i := 1 until i > a_text.count loop
				l_w := {UNICODE_WIDTH}.width (a_text.code (i)).to_integer_32
				a_row [c] := a_text [i]
				if l_w = 2 then
					a_row.remove (c + 1)
				end
				c := c + 1
				i := i + 1
			end
		end

	check_render (a_tag: STRING; a_width, a_height: INTEGER; a_area: RECT; a_toast: TUI_TOAST;
			a_texts: ARRAY [READABLE_STRING_GENERAL]; a_expected: ARRAYED_LIST [STRING_32])
			-- `a_toast` drawing a queue of `a_texts` (info) in `a_area` of a `a_width` x
			-- `a_height` buffer of dots gives `a_expected`.
		local
			l_buf: BUFFER
			q: TOAST_QUEUE
		do
			l_buf := dotted_buffer (a_width, a_height)
			create q.make_at (0)
			across a_texts as t loop
				q.push (t, {TOAST_LEVEL}.info, 1000)
			end
			a_toast.render_stateful (a_area, l_buf, q)
			assert_buffer_lines (a_tag, l_buf, a_expected.to_array)
			assert (a_tag + " consistent", l_buf.is_consistent)
		end

	dotted_buffer (a_width, a_height: INTEGER): BUFFER
			-- A buffer filled with dots
		local
			r: INTEGER
		do
			create Result.make (a_width, a_height)
			from r := 0 until r >= a_height loop
				Result.put_string (r, 0, create {STRING_32}.make_filled ('.', a_width), create {STYLE})
				r := r + 1
			end
		end

	check_position (a_tag: STRING; a_position: NATURAL_8; a_x1, a_y1, a_x2, a_y2: INTEGER)
			-- "Hi" then "Yo!" at `a_position` in a 12 x 8 buffer: boxes at (`a_x1`, `a_y1`)
			-- and (`a_x2`, `a_y2`).
		local
			l_grid: ARRAYED_LIST [STRING_32]
		do
			l_grid := dots (12, 8)
			put_box (l_grid, a_x1, a_y1, 2, <<"Hi">>)
			put_box (l_grid, a_x2, a_y2, 3, <<"Yo!">>)
			check_render (a_tag, 12, 8, create {RECT}.make (0, 0, 12, 8),
				(create {TUI_TOAST}).with_position (a_position), <<"Hi", "Yo!">>, l_grid)
		end

	assert_texts (a_tag: STRING; a_queue: TOAST_QUEUE; a_texts: ARRAY [READABLE_STRING_GENERAL])
			-- `a_queue` holds toasts with `a_texts`, in order.
		local
			i: INTEGER
		do
			assert (a_tag + " count", a_queue.count = a_texts.count)
			from i := 1 until i > a_texts.count loop
				assert (a_tag + " " + i.out, a_queue.item (i).text.to_plain_string.same_string_general (a_texts [i]))
				i := i + 1
			end
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
					(attached {PRECONDITION_VIOLATION} e.original as pv and then
					(attached pv.description as d and then d.same_string (a_tag)))
				retry
			end
		end

end
