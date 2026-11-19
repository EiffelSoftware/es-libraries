note
	description: "[
		EXAMPLE_DEMO2 set up on a given terminal without `run`, for snapshot tests: its
		state is initialized as `make` does, a tab can be shown, and a frame rendered
		directly. The batch run shows only tab 1, so the other tabs are reached this way.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	DEMO2_SNAPSHOT_APP

inherit
	EXAMPLE_DEMO2

create
	make_on_terminal

feature {NONE} -- Initialization

	make_on_terminal (a_terminal: TERMINAL [ANSI_TERMINAL_BACKEND])
			-- Example with its initial state, on `a_terminal`.
		require
			terminal_attached: a_terminal /= Void
		do
			init_state
			make_with_terminal (a_terminal)
		ensure
			not_running: not is_running
		end

feature -- Direct driving (snapshot tests, without `run`)

	show_tab (a_tab: INTEGER)
			-- Show tab `a_tab` (1: About, 2: Recipe, 3: Email, 4: Traceroute, 5: Weather).
		require
			valid_tab: a_tab >= 1 and a_tab <= 5
		do
			active_tab := a_tab
		ensure
			shown: active_tab = a_tab
		end

	render_now (a_frame: FRAME)
			-- Render the example into `a_frame`.
		require
			frame_attached: a_frame /= Void
		do
			render (a_frame)
		end

	ping_values: ARRAYED_LIST [NATURAL_64]
			-- The ping wave the Traceroute tab draws (0: a lost packet)
		do
			Result := ping_telemetry
		end

end
