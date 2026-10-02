note
	description: "[
			Borderless, translucent window used for docking feedback on GTK 3: the
			docking indicators and the area a dragged zone would take.

			It never takes the focus nor any pointer event, so a drag in progress keeps
			receiving the motion over the widgets underneath. Everything `paint' does
			not cover is fully transparent, which requires a compositing manager; see
			`SD_HOT_ZONE_FACTORY_FACTORY_IMP' for how the other case is handled.
		]"
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date$"
	revision: "$Revision$"

deferred class
	SD_FEEDBACK_WINDOW

inherit
	EV_POPUP_WINDOW
		redefine
			create_implementation
		end

feature {NONE} -- Initialization

	make_feedback_window
			-- Initialize `Current'.
		do
				-- Before `default_create', which lets `Current' escape to the
				-- implementation and so needs every attribute set.
			create drawing
			default_create
			disconnect_from_window_manager
			extend (drawing)
			drawing.expose_actions.extend (agent on_expose)
		end

feature -- Basic operations

	raise_window
			-- Stack `Current' above the other feedback windows.
		do
			if is_show_requested and then attached {SD_FEEDBACK_WINDOW_IMP} implementation as l_imp then
				l_imp.raise_window
			end
		end

feature {NONE} -- Stacking

	indicators_on_screen: ARRAYED_LIST [SD_FEEDBACK_WINDOW]
			-- Indicators currently shown, which have to stay above the feedback area.
			--| Every newly mapped popup lands on top of the others. The area comes up
			--| after the indicators, when the pointer first reaches a hot zone, and
			--| would cover the arrows the user is aiming at unless they are raised
			--| again. Shared by all feedback windows.
		once
			create Result.make (5)
		end

feature {NONE} -- Drawing

	drawing: EV_DRAWING_AREA
			-- Area filling `Current', where the feedback is painted.

	paint
			-- Paint the feedback on `drawing', whose content is already transparent.
		deferred
		end

	fill_translucent_rectangle (a_x, a_y, a_width, a_height: INTEGER; a_color: EV_COLOR; a_alpha: REAL_64)
			-- Fill the given area of `drawing' with `a_color' at opacity `a_alpha'.
		require
			valid_alpha: 0.0 <= a_alpha and a_alpha <= 1.0
		do
			if attached {SD_FEEDBACK_WINDOW_IMP} implementation as l_imp then
				l_imp.fill_translucent_rectangle (drawing, a_x, a_y, a_width, a_height, a_color, a_alpha)
			end
		end

	on_expose (a_x, a_y, a_width, a_height: INTEGER)
			-- Repaint `drawing'.
		do
			drawing.start_drawing_session
			if attached {SD_FEEDBACK_WINDOW_IMP} implementation as l_imp then
				l_imp.clear_to_transparent (drawing)
			end
			paint
			drawing.end_drawing_session
		end

feature {NONE} -- Implementation

	create_implementation
			-- <Precursor>
		do
			create {SD_FEEDBACK_WINDOW_IMP} implementation.make
		end

note
	library:	"SmartDocking: Library of reusable components for Eiffel."
	copyright:	"Copyright (c) 1984-2026, Eiffel Software and others"
	license:	"Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"

end
