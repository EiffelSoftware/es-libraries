note
	description: "[
		EXAMPLE_MENU_BAR driven directly, without `run`, so that a test can render it into a
		frame and feed it events (P2 W4). `stop_count` counts the calls of `stop`, which a
		run that never started cannot show through `is_running` (P2b U3: File > Quit, Yes).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	MENU_BAR_SNAPSHOT_APP

inherit
	EXAMPLE_MENU_BAR
		redefine
			stop
		end

create
	make_on

feature -- Direct driving

	render_now (a_frame: FRAME)
			-- Render the example into `a_frame`.
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

	is_focused_id (a_value: INTEGER): BOOLEAN
			-- Is the checkbox whose id has `a_value` (1 or 2) focused?
		do
			Result := attached focus_manager.focused_id as l_id and then l_id.value = a_value
		end

	has_focus: BOOLEAN
			-- Is any control focused in the active focus scope?
		do
			Result := focus_manager.has_focus
		end

	scope_depth: INTEGER
			-- Focus scopes open on the focus manager
		do
			Result := focus_manager.scope_depth
		end

	is_focused_widget (a_id: WIDGET_ID): BOOLEAN
			-- Is `a_id` focused?
		do
			Result := focus_manager.is_focused (a_id)
		end

	stop_count: INTEGER
			-- Calls of `stop` so far

feature -- Control

	stop
			-- Count the call, then stop.
		do
			stop_count := stop_count + 1
			Precursor
		end

end
