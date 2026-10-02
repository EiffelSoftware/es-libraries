note
	description: "[
			Docking indicator on GTK 3: one of the arrow icons showing where a dragged
			zone can be docked, painted with its transparency on top of the screen.
		]"
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date$"
	revision: "$Revision$"

class
	SD_FEEDBACK_INDICATOR

inherit
	SD_FEEDBACK_WINDOW
		redefine
			show
		end

create
	make

feature {NONE} -- Initialization

	make (a_pixel_buffer: attached like pixel_buffer; a_parent_window: EV_WINDOW)
			-- Create an indicator showing `a_pixel_buffer'.
			--| `a_parent_window' is only needed on Windows, where the indicator is a
			--| layered child of it; here stacking is handled by `indicators_on_screen'.
		require
			not_void: a_pixel_buffer /= Void
		do
			pixel_buffer := a_pixel_buffer
			make_feedback_window
			set_size (a_pixel_buffer.width, a_pixel_buffer.height)
		ensure
			set: pixel_buffer = a_pixel_buffer
		end

feature -- Command

	show
			-- <Precursor>
		do
			if not is_show_requested then
				Precursor
				if not indicators_on_screen.has (Current) then
					indicators_on_screen.extend (Current)
				end
			end
		end

	set_pixel_buffer (a_pixel_buffer: attached like pixel_buffer)
			-- Show `a_pixel_buffer' instead.
		do
			if a_pixel_buffer /= pixel_buffer then
				pixel_buffer := a_pixel_buffer
				if a_pixel_buffer.width /= width or a_pixel_buffer.height /= height then
					set_size (a_pixel_buffer.width, a_pixel_buffer.height)
				end
				drawing.redraw
			end
		ensure
			set: pixel_buffer = a_pixel_buffer
		end

	clear
			-- Remove `Current' from the screen for good.
		require
			exists: exists
		do
			indicators_on_screen.prune_all (Current)
			destroy
		ensure
			not_exists: not exists
		end

feature -- Query

	pixel_buffer: detachable EV_PIXEL_BUFFER
			-- Icon shown.

	exists: BOOLEAN
			-- Has `Current' not been cleared yet?
		do
			Result := not is_destroyed
		end

feature {NONE} -- Implementation

	paint
			-- <Precursor>
		do
			if attached pixel_buffer as l_pixel_buffer then
				drawing.draw_pixel_buffer (0, 0, l_pixel_buffer)
			end
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
