note
	description: "[
		Concrete TUI_APPLICATION for testing the runtime: counts ticks, keys and frames,
		stops on 'q', and can raise from `render' on a chosen frame.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_TUI_APP_IMPL

inherit
	TUI_APPLICATION

create
	make,
	make_with_terminal

feature -- Access

	draw_pass_count: INTEGER
			-- Number of frames rendered

	tick_count: INTEGER
			-- Number of TICK_EVENTs processed

	key_count: INTEGER
			-- Number of KEY_EVENTs processed

	failing_frame: INTEGER
			-- Frame number on which `render` raises, or 0 for never

feature -- Settings

	set_failing_frame (a_frame: INTEGER)
			-- Make `render` raise on frame `a_frame`.
		do
			failing_frame := a_frame
		end

	key_hook: detachable PROCEDURE [KEY_EVENT]
			-- Called for every KEY_EVENT, before the 'q' check, while `run` is active

	set_key_hook (a_hook: like key_hook)
			-- Set `key_hook` to `a_hook`.
		do
			key_hook := a_hook
		end

feature -- Test Hooks

	test_render_pass (a_frame: FRAME)
			-- Frame rendering callback
		do
			draw_pass_count := draw_pass_count + 1
			if draw_pass_count = failing_frame then
				(create {DEVELOPER_EXCEPTION}).raise
			end
			a_frame.buffer.put_string (0, 0, "frame", create {STYLE})
		end

feature {NONE} -- Abstract hooks implementation

	process (a_event: EVENT)
		do
			if a_event.is_tick then
				tick_count := tick_count + 1
			elseif attached {KEY_EVENT} a_event as k then
				key_count := key_count + 1
				if attached key_hook as h then
					h.call ([k])
				end
				if k.code.is_char and then k.code.character = 'q' then
					stop
				end
			end
		end

	render (a_frame: FRAME)
		do
			test_render_pass (a_frame)
		end

end
