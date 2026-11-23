note
	description: "[
		Concrete TUI_APPLICATION for testing the runtime: counts ticks, keys and frames,
		records clipboard answers (`clipboard_events`),
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

	reply_count: INTEGER
			-- Keyboard flags and device attributes replies processed

	key_count: INTEGER
			-- Number of KEY_EVENTs processed

	custom_count: INTEGER
			-- Number of CUSTOM_EVENTs processed

	last_custom_payload: detachable ANY
			-- Payload of the most recent CUSTOM_EVENT, if any

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

	custom_hook: detachable PROCEDURE [CUSTOM_EVENT]
			-- Called for every CUSTOM_EVENT while `run` is active

	set_custom_hook (a_hook: like custom_hook)
			-- Set `custom_hook` to `a_hook`.
		do
			custom_hook := a_hook
		end

	draw_hook: detachable PROCEDURE [FRAME]
			-- Called with every frame after it is rendered while `run` is active

	set_draw_hook (a_hook: like draw_hook)
			-- Set `draw_hook` to `a_hook`.
		do
			draw_hook := a_hook
		end

	clipboard_events: ARRAYED_LIST [CLIPBOARD_EVENT]
			-- CLIPBOARD_EVENTs processed, in order
		attribute
			create Result.make (2)
		end

	clipboard_hook: detachable PROCEDURE [CLIPBOARD_EVENT]
			-- Called for every CLIPBOARD_EVENT while `run` is active, after it is recorded

	set_clipboard_hook (a_hook: like clipboard_hook)
			-- Set `clipboard_hook` to `a_hook`.
		do
			clipboard_hook := a_hook
		end

	tick_hook: detachable PROCEDURE
			-- Called for every TICK_EVENT while `run` is active

	set_tick_hook (a_hook: like tick_hook)
			-- Set `tick_hook` to `a_hook`.
		do
			tick_hook := a_hook
		end

	mouse_hook: detachable PROCEDURE [MOUSE_EVENT]
			-- Called for every MOUSE_EVENT while `run` is active

	set_mouse_hook (a_hook: like mouse_hook)
			-- Set `mouse_hook` to `a_hook`.
		do
			mouse_hook := a_hook
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
			if attached draw_hook as h then
				h.call ([a_frame])
			end
		end

	dispatch_now (a_event: EVENT)
			-- Handle `a_event` as the event loop does (`dispatch`), right now.
		require
			event_attached: a_event /= Void
		do
			dispatch (a_event)
		end

feature {NONE} -- Abstract hooks implementation

	process (a_event: EVENT)
		do
			if a_event.is_tick then
				tick_count := tick_count + 1
				if attached tick_hook as h then
					h.call
				end
			elseif attached {CLIPBOARD_EVENT} a_event as l_clip then
				clipboard_events.extend (l_clip)
				if attached clipboard_hook as h then
					h.call ([l_clip])
				end
			elseif a_event.is_keyboard_flags or a_event.is_device_attributes then
				reply_count := reply_count + 1
			elseif attached {CUSTOM_EVENT} a_event as c then
				custom_count := custom_count + 1
				last_custom_payload := c.payload
				if attached custom_hook as h then
					h.call ([c])
				end
			elseif attached {MOUSE_EVENT} a_event as m then
				if attached mouse_hook as h then
					h.call ([m])
				end
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
