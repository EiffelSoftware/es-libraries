note
	description: "[
		EXAMPLE_MENU_BAR run through the real event loop on a given terminal (a
		FAKE_CONSOLE_DRIVER and an output sink, set up by the test) until it has processed one
		clipboard answer (P2b K6: Edit > Paste), then stopped. The test scripts the keys on the
		driver before `run`. A terminal reply given to the creation procedure is scripted on
		the driver at the first frame after the read's request was written (a reply scripted
		before that frame would be dropped as late). After the run, `render_now` draws the
		example into a frame of the test's size.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	MENU_BAR_SCRIPTED_APP

inherit
	EXAMPLE_MENU_BAR
		redefine
			render,
			process
		end

create
	make_scripted

feature {NONE} -- Initialization

	make_scripted (a_terminal: TERMINAL [ANSI_TERMINAL_BACKEND]; a_reply: detachable READABLE_STRING_8)
			-- Example on `a_terminal` that stops after one clipboard answer; `a_reply`, if any,
			-- is the terminal's input once the read's request is written.
		require
			terminal_attached: a_terminal /= Void
		do
			make_on (a_terminal)
			event_thread.set_poll_interval (5)
			reply := a_reply
		ensure
			not_running: not is_running
		end

feature -- Access

	clipboard_answers: INTEGER
			-- Clipboard answers processed

	last_answer: detachable CLIPBOARD_EVENT
			-- The last clipboard answer processed

	pending_command: detachable STRING_32
			-- `last_command` at the last frame drawn while a read was pending

	is_reply_scripted: BOOLEAN
			-- Has `reply` been scripted on the driver?

	Frame_limit: INTEGER = 2000
			-- Frames after which the run stops, in case the answer never arrives

feature -- Direct driving

	render_now (a_frame: FRAME)
			-- Render the example into `a_frame`.
		require
			frame_attached: a_frame /= Void
		do
			render (a_frame)
		end

feature {NONE} -- Application Hooks

	render (a_frame: FRAME)
			-- Script the reply once the request is written, draw, and stop after
			-- `Frame_limit` frames.
		do
			if attached reply as r and then not is_reply_scripted and then is_clipboard_request_sent then
				is_reply_scripted := True
				check attached {FAKE_CONSOLE_DRIVER} backend.driver as d then
					d.script (r)
				end
			end
			Precursor (a_frame)
			if is_clipboard_read_pending then
				pending_command := last_command.twin
			end
			frames := frames + 1
			if frames >= Frame_limit then
				stop
			end
		end

	process (a_event: EVENT)
			-- Process, then stop once a clipboard answer was processed.
		do
			Precursor (a_event)
			if attached {CLIPBOARD_EVENT} a_event as c then
				clipboard_answers := clipboard_answers + 1
				last_answer := c
				stop
			end
		end

feature {NONE} -- Implementation

	reply: detachable READABLE_STRING_8
			-- Terminal input scripted once the read's request is written

	frames: INTEGER
			-- Frames drawn

end
