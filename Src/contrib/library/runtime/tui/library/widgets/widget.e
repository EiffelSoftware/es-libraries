note
	description: "[
		Deferred base interface for all immediate-mode EiffelTUI widgets.
		Widgets implement `render` to paint themselves onto a `BUFFER` within a bounding `RECT`.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	WIDGET

feature -- Rendering

	render (a_area: RECT; a_buffer: BUFFER)
			-- Render widget into `a_buffer` bounded by `a_area`.
		require
			area_not_void: a_area /= Void
			buffer_not_void: a_buffer /= Void
		deferred
		end

end
