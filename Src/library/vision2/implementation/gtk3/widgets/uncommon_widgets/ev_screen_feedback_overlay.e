note
	description: "[
			Shared state of the transparent window `EV_SCREEN_IMP' paints drag feedback
			into when the X11 root window cannot be drawn on.

			There is one of these per application rather than one per `EV_SCREEN': the
			docking library alone creates several `EV_SCREEN' objects (`SD_LINE_DRAWER'
			and `SD_FEEDBACK_RECT' each build their own) and they all have to paint into
			the same window, otherwise each would stack its own full-screen overlay.

			`shapes' emulates the XOR drawing the callers expect. On X11 they draw a
			rectangle to show it and draw the identical rectangle again to erase it,
			which works because the operation is its own inverse. Nothing composited can
			invert what is underneath it, so instead `toggle_rectangle' adds a shape the
			first time and removes it the second: the same call sequence, the same
			result on screen, without needing the destination pixels.
		]"
	legal: "See notice at end of class."
	status: "See notice at end of class."

class
	EV_SCREEN_FEEDBACK_OVERLAY

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize `Current'.
		do
			create shapes.make (4)
		end

feature -- Access

	window: POINTER
			-- GtkWindow the feedback is painted in, null until first needed.

	drawing: detachable EV_DRAWING_AREA
			-- Drawing area filling `window'.

	origin_x, origin_y: INTEGER
			-- Logical position of `window', subtracted from shape coordinates when
			-- painting since those are screen coordinates and cairo works in
			-- window ones.

	shapes: ARRAYED_LIST [TUPLE [filled: BOOLEAN; x, y, width, height, line_width: INTEGER; red, green, blue: REAL_64]]
			-- Feedback currently on screen.
			--
			--| Set in `make' rather than through an attribute body: that body is not
			--| executed when the class is compiled without void safety, which would
			--| leave this Void.

feature -- Status report

	is_overloaded: BOOLEAN
			-- Are there more shapes than any sane feedback would use?
			--
			--| Every caller pairs its draws, so the list stays tiny. If one ever fails
			--| to, the leftovers would sit on top of the screen for the rest of the
			--| session; this is the cue to throw them away instead.
		do
			Result := shapes.count > maximum_shape_count
		end

	maximum_shape_count: INTEGER = 8

feature -- Element change

	set_window (a_window: POINTER)
		do
			window := a_window
		end

	set_drawing (a_drawing: EV_DRAWING_AREA)
		do
			drawing := a_drawing
		end

	set_origin (a_x, a_y: INTEGER)
		do
			origin_x := a_x
			origin_y := a_y
		ensure
			set: origin_x = a_x and origin_y = a_y
		end

	toggle_rectangle (a_filled: BOOLEAN; a_x, a_y, a_width, a_height, a_line_width: INTEGER; a_red, a_green, a_blue: REAL_64)
			-- Show the rectangle if it is not on screen, erase it if it is.
		local
			i: INTEGER
		do
			i := index_of_rectangle (a_filled, a_x, a_y, a_width, a_height)
			if i > 0 then
				shapes.go_i_th (i)
				shapes.remove
			elseif is_overloaded then
					-- Unpaired draws have piled up; start again from a clean screen
					-- rather than leaving them there.
				shapes.wipe_out
			else
				shapes.extend ([a_filled, a_x, a_y, a_width, a_height, a_line_width, a_red, a_green, a_blue])
			end
		end

	wipe_out
		do
			shapes.wipe_out
		ensure
			empty: shapes.is_empty
		end

feature {NONE} -- Implementation

	index_of_rectangle (a_filled: BOOLEAN; a_x, a_y, a_width, a_height: INTEGER): INTEGER
			-- Index in `shapes' of the rectangle matching the arguments, 0 if none.
			--
			--| Colour and line width are deliberately not compared: what identifies a
			--| shape for the erase-by-redrawing protocol is where it is, and a caller
			--| that changed colour between the two draws still means the same one.
		local
			i, n: INTEGER
		do
			from
				i := 1
				n := shapes.count
			until
				i > n or Result > 0
			loop
				if
					attached shapes.i_th (i) as s and then
					(s.filled = a_filled and s.x = a_x and s.y = a_y and
					 s.width = a_width and s.height = a_height)
				then
					Result := i
				end
				i := i + 1
			end
		ensure
			valid: Result = 0 or else (Result >= 1 and Result <= shapes.count)
		end

note
	copyright:	"Copyright (c) 1984-2026, Eiffel Software and others"
	license:	"Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"

end -- class EV_SCREEN_FEEDBACK_OVERLAY
