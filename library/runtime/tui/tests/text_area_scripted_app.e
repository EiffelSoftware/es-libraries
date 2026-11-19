note
	description: "[
		EXAMPLE_TEXT_AREA run on a given terminal (a FAKE_CONSOLE_DRIVER and an output sink,
		set up by the test) until it has processed a given number of key presses, then
		stopped. The test scripts the keys on the driver before `run`.
		P2b K6 (`make_clipboard_scripted`): Ctrl+V reads the clipboard. The run then also
		waits for the clipboard's answer, the text the example has when it is processed is
		kept, and a terminal reply given to the creation procedure is scripted on the driver
		at the first frame after the read's request was written (a reply scripted before that
		frame would be dropped as late).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEXT_AREA_SCRIPTED_APP

inherit
	EXAMPLE_TEXT_AREA
		redefine
			render,
			process
		end

create
	make_scripted,
	make_clipboard_scripted

feature {NONE} -- Initialization

	make_scripted (a_terminal: TERMINAL [ANSI_TERMINAL_BACKEND]; a_presses: INTEGER)
			-- Example on `a_terminal` that stops after `a_presses` key presses.
		require
			terminal_attached: a_terminal /= Void
			positive_presses: a_presses > 0
		do
			presses_to_stop := a_presses
			make_on (a_terminal)
			event_thread.set_poll_interval (5)
		ensure
			not_running: not is_running
		end

	make_clipboard_scripted (a_terminal: TERMINAL [ANSI_TERMINAL_BACKEND]; a_presses: INTEGER; a_reply: detachable READABLE_STRING_8)
			-- Example on `a_terminal` that stops once it has processed `a_presses` key presses
			-- and one clipboard answer; `a_reply`, if any, is the terminal's input once the
			-- read's request is written.
		require
			terminal_attached: a_terminal /= Void
			positive_presses: a_presses > 0
		do
			make_scripted (a_terminal, a_presses)
			answers_to_stop := 1
			reply := a_reply
		ensure
			not_running: not is_running
		end

feature -- Access

	status_line: STRING_32
			-- The example's status line
		do
			Result := status
		end

	selected_text: STRING_32
			-- The text area's selection
		do
			Result := area_state.selected_text
		end

	presses: INTEGER
			-- Key presses processed

	text: STRING_32
			-- The text area's text
		do
			Result := area_state.value
		end

	clipboard_answers: INTEGER
			-- Clipboard answers processed

	last_answer: detachable CLIPBOARD_EVENT
			-- The last clipboard answer processed

	text_at_answer: detachable STRING_32
			-- The text right after the last clipboard answer was processed

	status_at_answer: detachable STRING_32
			-- The status line right after the last clipboard answer was processed

	pending_status: detachable STRING_32
			-- The status line at the last frame drawn while a read was pending

	is_reply_scripted: BOOLEAN
			-- Has `reply` been scripted on the driver?

	Frame_limit: INTEGER = 2000
			-- Frames after which the run stops, in case a press never arrives

feature {NONE} -- Application Hooks

	render (a_frame: FRAME)
			-- Draw; stop after `Frame_limit` frames.
		do
			if attached reply as r and then not is_reply_scripted and then is_clipboard_request_sent then
				is_reply_scripted := True
				check attached {FAKE_CONSOLE_DRIVER} backend.driver as d then
					d.script (r)
				end
			end
			Precursor (a_frame)
			if is_clipboard_read_pending then
				pending_status := status.twin
			end
			frames := frames + 1
			if frames >= Frame_limit then
				stop
			end
		end

	process (a_event: EVENT)
			-- Process, then stop once `presses_to_stop` presses were processed.
		do
			Precursor (a_event)
			if attached {CLIPBOARD_EVENT} a_event as c then
				clipboard_answers := clipboard_answers + 1
				last_answer := c
				text_at_answer := area_state.value.twin
				status_at_answer := status.twin
			elseif attached {KEY_EVENT} a_event as k and then k.is_press then
				presses := presses + 1
			end
			if presses >= presses_to_stop and clipboard_answers >= answers_to_stop then
				stop
			end
		end

feature {NONE} -- Implementation

	presses_to_stop: INTEGER
			-- Presses after which the run stops

	answers_to_stop: INTEGER
			-- Clipboard answers the run also waits for

	reply: detachable READABLE_STRING_8
			-- Terminal input scripted once the read's request is written

	frames: INTEGER
			-- Frames drawn

end
