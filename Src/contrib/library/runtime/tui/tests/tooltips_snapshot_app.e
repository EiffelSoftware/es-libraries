note
	description: "[
		EXAMPLE_TOOLTIPS driven directly, without `run` (`render_now`, `process_now`), or run
		for real with a hook called after each frame, so that a test can script input on the
		fake console one step at a time and look at the frame it produced (P2 W6).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TOOLTIPS_SNAPSHOT_APP

inherit
	EXAMPLE_TOOLTIPS
		redefine
			render
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

	is_focused_index (a_index: INTEGER): BOOLEAN
			-- Is control `a_index` (1 .. 4) focused?
		do
			Result := attached focus_manager.focused_id as l_id and then l_id.value = Id_base + a_index
		end

feature -- Frame hook

	frame_hook: detachable PROCEDURE [FRAME]
			-- Called with each frame once the example has drawn it

	set_frame_hook (a_hook: like frame_hook)
			-- Call `a_hook` after each frame.
		do
			frame_hook := a_hook
		ensure
			set: frame_hook = a_hook
		end

feature {NONE} -- Application Hooks

	render (a_frame: FRAME)
			-- Draw, then call `frame_hook`.
		do
			Precursor (a_frame)
			if attached frame_hook as l_hook then
				l_hook.call ([a_frame])
			end
		end

end
