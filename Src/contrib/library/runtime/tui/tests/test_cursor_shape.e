note
	description: "[
		P2 T1, cursor shape (DECSCUSR): CURSOR_SHAPE, the backends, TERMINAL writing the
		shape only when it changes and again after `forget_shown_frame`, TUI_APPLICATION
		giving the default shape back on restore, and the text widgets' shape.
		The sequence `ESC [ n SP q` (n = 0 .. 6) is checked against crossterm's
		`SetCursorStyle` documentation (DefaultUserShape 0, BlinkingBlock 1, SteadyBlock 2,
		BlinkingUnderScore 3, SteadyUnderScore 4, BlinkingBar 5, SteadyBar 6). It was not
		checked against the crossterm source, which is not in this repository.
		The suspend sequence and the signal handlers' reset strings are checked in
		TEST_SUSPEND_RESUME and TEST_PLATFORM_DRIVER.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_CURSOR_SHAPE

inherit
	EQA_TEST_SET

feature -- Shapes

	test_cursor_shape_values
			-- The seven shapes: their codes, kinds, blinking, names and equality.
		local
			l_shapes: ARRAY [CURSOR_SHAPE]
			i: INTEGER
		do
			l_shapes := all_shapes
			from i := 1 until i > 7 loop
				assert ("code " + i.out, l_shapes [i].code = (i - 1).to_natural_8)
				assert ("one kind " + i.out, (l_shapes [i].is_default.to_integer + l_shapes [i].is_block.to_integer
					+ l_shapes [i].is_underline.to_integer + l_shapes [i].is_bar.to_integer) = 1)
				assert ("equal to a new one " + i.out, l_shapes [i] ~ create {CURSOR_SHAPE}.make ((i - 1).to_natural_8))
				i := i + 1
			end
			assert ("default", {CURSOR_SHAPE}.Default_user.is_default and not {CURSOR_SHAPE}.Default_user.is_blinking)
			assert ("blinking block", {CURSOR_SHAPE}.Blinking_block.is_block and {CURSOR_SHAPE}.Blinking_block.is_blinking)
			assert ("steady block", {CURSOR_SHAPE}.Steady_block.is_block and not {CURSOR_SHAPE}.Steady_block.is_blinking)
			assert ("blinking underline", {CURSOR_SHAPE}.Blinking_underline.is_underline and {CURSOR_SHAPE}.Blinking_underline.is_blinking)
			assert ("steady underline", {CURSOR_SHAPE}.Steady_underline.is_underline and not {CURSOR_SHAPE}.Steady_underline.is_blinking)
			assert ("blinking bar", {CURSOR_SHAPE}.Blinking_bar.is_bar and {CURSOR_SHAPE}.Blinking_bar.is_blinking)
			assert ("steady bar", {CURSOR_SHAPE}.Steady_bar.is_bar and not {CURSOR_SHAPE}.Steady_bar.is_blinking)
			assert ("bar is not block", {CURSOR_SHAPE}.Steady_bar /~ {CURSOR_SHAPE}.Steady_block)
			assert ("crossterm name", {CURSOR_SHAPE}.Blinking_underline.out.same_string ("BlinkingUnderScore"))
			assert ("default name", {CURSOR_SHAPE}.Default_user.out.same_string ("DefaultUserShape"))
			assert ("6 valid", {CURSOR_SHAPE}.is_valid_code (6))
			assert ("7 not valid", not {CURSOR_SHAPE}.is_valid_code (7))
			assert ("7 refused", precondition_raised (agent new_shape (7), "valid_code"))
		end

feature -- Backends

	test_ansi_backend_writes_decscusr
			-- `set_cursor_shape` writes exactly `ESC [ n SP q` for each shape, and records it.
		local
			l_backend: ANSI_TERMINAL_BACKEND
			l_sink: STRING_32
		do
			create l_sink.make_empty
			create l_backend.make_with_driver_and_sink (create {FAKE_CONSOLE_DRIVER}, l_sink)
			assert ("default before the first", l_backend.cursor_shape.is_default)
			across all_shapes as s loop
				l_sink.wipe_out
				l_backend.set_cursor_shape (s)
				assert ("bytes for " + s.out, l_sink.same_string_general (decscusr (s.code)))
				assert ("recorded " + s.out, l_backend.cursor_shape ~ s)
			end
			l_sink.wipe_out
			l_backend.set_cursor_shape ({CURSOR_SHAPE}.Blinking_bar)
			assert ("ESC [ 5 SP q", l_sink.same_string_general ("%/27/[5 q"))
		end

	test_virtual_terminal_records_shape
			-- VIRTUAL_TERMINAL records the shape and logs it.
		local
			l_vt: VIRTUAL_TERMINAL
		do
			create l_vt.make (10, 3)
			assert ("default before the first", l_vt.cursor_shape.is_default)
			l_vt.set_cursor_shape ({CURSOR_SHAPE}.Steady_underline)
			assert ("recorded", l_vt.cursor_shape ~ {CURSOR_SHAPE}.Steady_underline)
			assert ("logged", l_vt.operations.has ("set_cursor_shape(4)"))
		end

feature -- Drawing

	test_draw_writes_shape_when_it_changes
			-- A frame's shape is written once, not again while the frames keep it, again when
			-- it changes, and the default is written for a frame that sets none afterwards.
			-- Frames that never set a shape write nothing.
		local
			l_terminal: TERMINAL [ANSI_TERMINAL_BACKEND]
			l_sink: STRING_32
		do
			l_terminal := new_terminal
			l_sink := sink_of (l_terminal)
			l_terminal.draw (agent draw_with_shape (?, Void))
			l_terminal.draw (agent draw_with_shape (?, Void))
			assert ("nothing for default frames", decscusr_count (l_sink) = 0)
			l_terminal.draw (agent draw_with_shape (?, {CURSOR_SHAPE}.Steady_bar))
			assert ("bar written", decscusr_count (l_sink) = 1 and l_sink.has_substring (decscusr (6)))
			l_terminal.draw (agent draw_with_shape (?, {CURSOR_SHAPE}.Steady_bar))
			assert ("same shape not repeated", decscusr_count (l_sink) = 1)
			l_terminal.draw (agent draw_with_shape (?, {CURSOR_SHAPE}.Blinking_block))
			assert ("change written", decscusr_count (l_sink) = 2 and l_sink.ends_with (decscusr (1) + "%/27/[?25l"))
			l_terminal.draw (agent draw_with_shape (?, Void))
			assert ("default after a frame that sets none", decscusr_count (l_sink) = 3
				and l_sink.ends_with (decscusr (0) + "%/27/[?25l"))
			assert ("backend has the default", l_terminal.backend.cursor_shape.is_default)
		end

	test_forget_writes_shape_again
			-- After `forget_shown_frame` (a resume, where a signal handler may have reset the
			-- shape), the next frame writes its shape even if it was the last one written;
			-- the default is not written again when it was the last one.
		local
			l_terminal: TERMINAL [ANSI_TERMINAL_BACKEND]
			l_sink: STRING_32
		do
			l_terminal := new_terminal
			l_sink := sink_of (l_terminal)
			l_terminal.forget_shown_frame
			assert ("uncertain", l_terminal.is_cursor_shape_uncertain)
			l_terminal.draw (agent draw_with_shape (?, Void))
			assert ("no default written", decscusr_count (l_sink) = 0)
			assert ("certain after a draw", not l_terminal.is_cursor_shape_uncertain)
			l_terminal.draw (agent draw_with_shape (?, {CURSOR_SHAPE}.Steady_bar))
			l_terminal.forget_shown_frame
			l_terminal.draw (agent draw_with_shape (?, {CURSOR_SHAPE}.Steady_bar))
			assert ("bar written again", occurrences (l_sink, decscusr (6)) = 2)
			l_terminal.draw (agent draw_with_shape (?, {CURSOR_SHAPE}.Steady_bar))
			assert ("then not repeated", occurrences (l_sink, decscusr (6)) = 2)
			l_terminal.force_full_redraw
			l_terminal.draw (agent draw_with_shape (?, Void))
			assert ("default after a forget", occurrences (l_sink, decscusr (0)) = 1)
		end

	test_reset_cursor_shape
			-- `reset_cursor_shape` writes the default only when another shape was written last.
		local
			l_terminal: TERMINAL [ANSI_TERMINAL_BACKEND]
			l_sink: STRING_32
		do
			l_terminal := new_terminal
			l_sink := sink_of (l_terminal)
			l_terminal.reset_cursor_shape
			assert ("nothing after the default", decscusr_count (l_sink) = 0)
			l_terminal.draw (agent draw_with_shape (?, {CURSOR_SHAPE}.Blinking_underline))
			l_sink.wipe_out
			l_terminal.reset_cursor_shape
			assert ("default written", l_sink.same_string_general (decscusr (0)))
			l_terminal.reset_cursor_shape
			assert ("once", l_sink.same_string_general (decscusr (0)))
		end

feature -- Restore

	test_restore_after_bar_writes_default
			-- An application whose frames ask for a bar gives the default shape back when it
			-- quits, before showing the cursor and leaving the alternate screen.
		local
			l_app: TEST_TUI_APP_IMPL
			l_sink: STRING_32
		do
			l_app := new_app ("q")
			l_sink := app_sink (l_app)
			l_app.set_draw_hook (agent (f: FRAME) do f.set_cursor_shape ({CURSOR_SHAPE}.Steady_bar) end)
			l_app.run
			assert ("bar written once", occurrences (l_sink, decscusr (6)) = 1)
			assert ("default written once", occurrences (l_sink, decscusr (0)) = 1)
			assert ("default after the bar", l_sink.substring_index (decscusr (0), 1) > l_sink.substring_index (decscusr (6), 1))
			assert ("restore order", l_sink.has_substring (decscusr (0) + "%/27/[?25h%/27/[?1049l"))
		end

	test_restore_after_default_writes_nothing
			-- An application that never asks for a shape writes no DECSCUSR at all.
		local
			l_app: TEST_TUI_APP_IMPL
			l_sink: STRING_32
		do
			l_app := new_app ("q")
			l_sink := app_sink (l_app)
			l_app.run
			assert ("restored", l_sink.has_substring ("%/27/[?1049l"))
			assert ("no shape written", decscusr_count (l_sink) = 0)
		end

feature -- Widgets

	test_text_widgets_ask_for_a_bar
			-- TUI_TEXT_INPUT and TUI_TEXT_AREA default to a steady bar; `with_cursor_shape`
			-- returns a copy and leaves the original alone.
		local
			l_input, l_input2: TUI_TEXT_INPUT
			l_area, l_area2: TUI_TEXT_AREA
		do
			create l_input.make
			assert ("input bar", l_input.cursor_shape ~ {CURSOR_SHAPE}.Steady_bar)
			l_input2 := l_input.with_cursor_shape ({CURSOR_SHAPE}.Blinking_block)
			assert ("input copy", l_input2 /= l_input and l_input2.cursor_shape ~ {CURSOR_SHAPE}.Blinking_block)
			assert ("input original kept", l_input.cursor_shape ~ {CURSOR_SHAPE}.Steady_bar)
			create l_area.make
			assert ("area bar", l_area.cursor_shape ~ {CURSOR_SHAPE}.Steady_bar)
			l_area2 := l_area.with_cursor_shape ({CURSOR_SHAPE}.Steady_underline)
			assert ("area copy", l_area2 /= l_area and l_area2.cursor_shape ~ {CURSOR_SHAPE}.Steady_underline)
			assert ("area original kept", l_area.cursor_shape ~ {CURSOR_SHAPE}.Steady_bar)
		end

	test_frame_shape_defaults_per_frame
			-- A new FRAME asks for the default shape; `set_cursor_shape` changes only that frame.
		local
			l_buffer: BUFFER
			l_frame: FRAME
		do
			create l_buffer.make (4, 2)
			create l_frame.make (l_buffer)
			assert ("default", l_frame.cursor_shape.is_default)
			l_frame.set_cursor_shape ({CURSOR_SHAPE}.Steady_bar)
			assert ("set", l_frame.cursor_shape ~ {CURSOR_SHAPE}.Steady_bar)
			assert ("next frame default", (create {FRAME}.make (l_buffer)).cursor_shape.is_default)
		end

feature {NONE} -- Helpers

	all_shapes: ARRAY [CURSOR_SHAPE]
			-- The seven shapes in code order
		do
			Result := <<{CURSOR_SHAPE}.Default_user, {CURSOR_SHAPE}.Blinking_block, {CURSOR_SHAPE}.Steady_block,
				{CURSOR_SHAPE}.Blinking_underline, {CURSOR_SHAPE}.Steady_underline,
				{CURSOR_SHAPE}.Blinking_bar, {CURSOR_SHAPE}.Steady_bar>>
		end

	decscusr (a_code: NATURAL_8): STRING_32
			-- `ESC [ a_code SP q`
		do
			Result := {STRING_32} "%/27/[" + a_code.out + " q"
		end

	decscusr_count (a_sink: READABLE_STRING_32): INTEGER
			-- Number of DECSCUSR sequences in `a_sink`
		local
			n: NATURAL_8
		do
			from n := 0 until n > 6 loop
				Result := Result + occurrences (a_sink, decscusr (n))
				n := n + 1
			end
		end

	draw_with_shape (a_frame: FRAME; a_shape: detachable CURSOR_SHAPE)
			-- Draw some text in `a_frame`, asking for `a_shape` if attached.
		do
			a_frame.buffer.put_string (0, 0, "text", create {STYLE})
			if attached a_shape as s then
				a_frame.set_cursor_shape (s)
			end
		end

	new_shape (a_code: NATURAL_8)
			-- Make a shape with `a_code` (for the precondition check).
		local
			l_shape: CURSOR_SHAPE
		do
			create l_shape.make (a_code)
		end

	new_terminal: TERMINAL [ANSI_TERMINAL_BACKEND]
			-- Fullscreen terminal on a fake console, output captured
		do
			create Result.make (create {ANSI_TERMINAL_BACKEND}.make_with_driver_and_sink (create {FAKE_CONSOLE_DRIVER}, create {STRING_32}.make_empty))
		end

	sink_of (a_terminal: TERMINAL [ANSI_TERMINAL_BACKEND]): STRING_32
			-- The output capture of `a_terminal`.
		do
			check attached a_terminal.backend.output_sink as s then
				Result := s
			end
		end

	new_app (a_input: READABLE_STRING_8): TEST_TUI_APP_IMPL
			-- Fullscreen application on a fake console replaying `a_input`, output captured.
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_sink: STRING_32
			l_backend: ANSI_TERMINAL_BACKEND
		do
			create l_driver
			create l_sink.make_empty
			l_driver.watch_sink (l_sink)
			l_driver.script (a_input)
			create l_backend.make_with_driver_and_sink (l_driver, l_sink)
			create Result.make_with_terminal (create {TERMINAL [ANSI_TERMINAL_BACKEND]}.make (l_backend))
			Result.event_thread.set_poll_interval (5)
		end

	app_sink (a_app: TEST_TUI_APP_IMPL): STRING_32
			-- The output capture of `a_app`.
		do
			check attached a_app.backend.output_sink as s then
				Result := s
			end
		end

	occurrences (a_text, a_part: READABLE_STRING_32): INTEGER
			-- Number of non-overlapping occurrences of `a_part` in `a_text`.
		local
			i: INTEGER
		do
			from
				i := a_text.substring_index (a_part, 1)
			until
				i = 0
			loop
				Result := Result + 1
				i := a_text.substring_index (a_part, i + a_part.count)
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
					(attached {PRECONDITION_VIOLATION} e.original as v and then
					(attached v.description as d and then d.same_string (a_tag)))
				retry
			end
		end

end
