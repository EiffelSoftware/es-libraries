note
	description: "[
		EXAMPLE_MODAL_DIALOG driven by a script of input steps on a FAKE_CONSOLE_DRIVER,
		one step per frame: a step is scripted only after the previous one was processed and
		a frame drawn, so every click is hit-tested against the frame now on screen. The
		state after each step is kept in `log`.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	MODAL_DIALOG_SCRIPTED_APP

inherit
	EXAMPLE_MODAL_DIALOG
		redefine
			render,
			process
		end

create
	make_scripted

feature {NONE} -- Initialization

	make_scripted (a_driver: FAKE_CONSOLE_DRIVER; a_terminal: TERMINAL [ANSI_TERMINAL_BACKEND]; a_steps: ARRAY [READABLE_STRING_8])
			-- Example on `a_terminal`, fed `a_steps` through `a_driver`, one per frame.
		require
			driver_attached: a_driver /= Void
			terminal_attached: a_terminal /= Void
			steps_attached: a_steps /= Void
		do
			driver := a_driver
			steps := a_steps
			create log.make (a_steps.count)
			make_on (a_terminal)
		ensure
			not_running: not is_running
		end

feature -- Access

	log: ARRAYED_LIST [TUPLE [files: INTEGER; selected: INTEGER; modal: BOOLEAN; hint: BOOLEAN; blocked: INTEGER]]
			-- State after each processed step

	file_names: ARRAYED_LIST [STRING_32]
			-- Files still listed
		do
			Result := files
		end

	Frame_limit: INTEGER = 2000
			-- Frames after which the run stops, in case a step is never processed

feature -- Direct driving (snapshot tests, without `run`)

	render_now (a_frame: FRAME)
			-- Render the example into `a_frame` (for a VIRTUAL_TERMINAL draw).
		require
			frame_attached: a_frame /= Void
		do
			render (a_frame)
		end

	process_now (a_event: EVENT)
			-- Process `a_event` as the example does.
		require
			event_attached: a_event /= Void
		do
			process (a_event)
		end

	is_focused (a_id: INTEGER): BOOLEAN
			-- Is the control with id number `a_id` focused?
		do
			Result := attached focus_manager.focused_id as l_id and then l_id ~ create {WIDGET_ID}.make (a_id)
		end

	dialog_button_id (i: INTEGER): WIDGET_ID
			-- Hit and focus id of the confirmation's button `i` (1: Yes, 2: No)
		require
			valid_index: i = 1 or i = 2
		do
			Result := confirm.button_id (i)
		end

	is_dialog_button_focused (i: INTEGER): BOOLEAN
			-- Is the confirmation's button `i` (1: Yes, 2: No) focused, in the focus manager
			-- and in the dialog?
		require
			valid_index: i = 1 or i = 2
		do
			Result := focus_manager.is_focused (confirm.button_id (i)) and confirm.focused_button = i
		end

feature {NONE} -- Application Hooks

	render (a_frame: FRAME)
			-- Draw, then script the next step once the previous one was processed.
		do
			Precursor (a_frame)
			frames := frames + 1
			if frames >= Frame_limit then
				stop
			elseif handled_steps = sent_steps and sent_steps < steps.count then
				sent_steps := sent_steps + 1
				driver.script (steps [steps.lower + sent_steps - 1])
			end
		end

	process (a_event: EVENT)
			-- Process, then log the state after a press (mouse button or key).
		do
			Precursor (a_event)
			if (attached {MOUSE_EVENT} a_event as m and then m.is_down)
				or else (attached {KEY_EVENT} a_event as k and then k.is_press)
			then
				handled_steps := handled_steps + 1
				log.extend ([files.count, selected_index, confirm.is_open, is_hint_open, blocked_clicks])
			end
		end

feature {NONE} -- Implementation

	driver: FAKE_CONSOLE_DRIVER
			-- Console the steps are scripted on

	steps: ARRAY [READABLE_STRING_8]
			-- Input of each step

	sent_steps, handled_steps: INTEGER
			-- Steps scripted, steps processed

	frames: INTEGER
			-- Frames drawn

end
