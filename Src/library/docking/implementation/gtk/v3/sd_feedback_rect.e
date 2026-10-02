note
	description: "[
			Translucent area showing where a dragged zone would be docked, on GTK 3.
			Either one rectangle, or two for the tabbed case: the content area and the
			tab below it.
		]"
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date$"
	revision: "$Revision$"

class
	SD_FEEDBACK_RECT

inherit
	SD_FEEDBACK_WINDOW
		rename
			hide as clear
		redefine
			show,
			clear
		end

create
	make

feature {NONE} -- Initialization

	make
			-- Creation method.
		do
			create internal_shared
			create areas.make (2)
			create bounds
			make_feedback_window
		end

feature -- Command

	show
			-- <Precursor>
			--| Does nothing until an area is set: `SD_FEEDBACK_DRAWER' calls this before
			--| `set_area', and showing then would flash the window where it last was.
		do
			if not areas.is_empty and not is_show_requested then
				Precursor
				across
					indicators_on_screen as w
				loop
					w.raise_window
				end
			end
		end

	clear
			-- <Precursor>
		do
			Precursor
			areas.wipe_out
		end

	set_area (a_rect: EV_RECTANGLE)
			-- Cover `a_rect', in screen coordinates.
		require
			not_void: a_rect /= Void
		do
			if areas.count /= 1 or else not areas.first.is_equal (a_rect) then
				areas.wipe_out
				areas.extend (a_rect.twin)
				update_geometry
			end
		end

	set_tab_area (a_top_rect, a_bottom_rect: EV_RECTANGLE)
			-- Cover `a_top_rect' and `a_bottom_rect', in screen coordinates.
		require
			a_top_rect_not_void: a_top_rect /= Void
			a_bottom_rect_not_void: a_bottom_rect /= Void
		do
			if
				areas.count /= 2 or else
				not (areas.first.is_equal (a_top_rect) and areas.last.is_equal (a_bottom_rect))
			then
				areas.wipe_out
				areas.extend (a_top_rect.twin)
				areas.extend (a_bottom_rect.twin)
				update_geometry
			end
		end

feature {NONE} -- Implementation

	update_geometry
			-- Fit `Current' around `areas' and repaint it.
		require
			not_empty: not areas.is_empty
		local
			l_left, l_top, l_right, l_bottom: INTEGER
		do
			l_left := areas.first.left
			l_top := areas.first.top
			l_right := areas.first.left + areas.first.width
			l_bottom := areas.first.top + areas.first.height
			across
				areas as r
			loop
				l_left := l_left.min (r.left)
				l_top := l_top.min (r.top)
				l_right := l_right.max (r.left + r.width)
				l_bottom := l_bottom.max (r.top + r.height)
			end
			create bounds.make (l_left, l_top, (l_right - l_left).max (1), (l_bottom - l_top).max (1))
			set_position (bounds.left, bounds.top)
			set_size (bounds.width, bounds.height)
			drawing.redraw
			show
		end

	paint
			-- <Precursor>
		do
			across
				areas as r
			loop
				fill_translucent_rectangle (r.left - bounds.left, r.top - bounds.top, r.width, r.height,
					internal_shared.focused_color, alpha)
			end
		end

	areas: ARRAYED_LIST [EV_RECTANGLE]
			-- Areas covered, in screen coordinates.

	bounds: EV_RECTANGLE
			-- Screen area of `Current', the union of `areas'.

	alpha: REAL_64 = 0.6
			-- Opacity of the areas, the same as on Windows.

	internal_shared: SD_SHARED;
			-- All singletons

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
