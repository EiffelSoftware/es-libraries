note
	description: "[
		Deferred base class for shapes drawn on TUI_CANVAS.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	SHAPE

feature -- Execution

	paint (a_painter: CANVAS_PAINTER)
			-- Paint this shape onto `a_painter`.
		require
			painter_not_void: a_painter /= Void
		deferred
		end

end
