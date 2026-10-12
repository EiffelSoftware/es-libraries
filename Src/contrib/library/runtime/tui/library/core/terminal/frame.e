note
	description: "[
		Drawing context passed to rendering agents during a single terminal draw pass.
		Provides access to the frame buffer, screen area, and widget rendering helpers.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	FRAME

create
	make

feature {NONE} -- Initialization

	make (a_buffer: BUFFER)
			-- Initialize frame bound to `a_buffer`.
		require
			buffer_not_void: a_buffer /= Void
		do
			buffer := a_buffer
		ensure
			buffer_set: buffer = a_buffer
		end

feature -- Access

	buffer: BUFFER
			-- Backing frame buffer for this frame

	area: RECT
			-- Entire available drawing area for this frame
		do
			create Result.make (0, 0, buffer.width.to_natural_16, buffer.height.to_natural_16)
		ensure
			result_not_void: Result /= Void
			correct_width: Result.width = buffer.width.to_natural_16
			correct_height: Result.height = buffer.height.to_natural_16
		end

feature -- Rendering

	render_widget (a_widget: WIDGET; a_area: RECT)
			-- Render immediate-mode `a_widget` into `a_area` on this frame.
		require
			widget_not_void: a_widget /= Void
			area_not_void: a_area /= Void
		do
			a_widget.render (a_area, buffer)
		end

	render_stateful_widget (a_widget: STATEFUL_WIDGET_BASE; a_area: RECT; a_state: WIDGET_STATE)
			-- Render `a_widget` using mutable state `a_state` into `a_area` on this frame.
		require
			widget_not_void: a_widget /= Void
			area_not_void: a_area /= Void
			state_not_void: a_state /= Void
			state_type_matches: a_widget.accepts_state (a_state)
		do
			a_widget.render_stateful_base (a_area, buffer, a_state)
		end

feature -- Cursor Management

	cursor_position: detachable TUPLE [col, row: INTEGER]
			-- Desired hardware cursor position, or Void if cursor should not be explicitly positioned.

	is_cursor_visible: BOOLEAN
			-- Should the hardware cursor be visible after rendering?

	set_cursor_position (a_col, a_row: INTEGER)
			-- Set hardware cursor position to (`a_col`, `a_row`) and make it visible.
		require
			valid_col: a_col >= 0 and a_col < buffer.width
			valid_row: a_row >= 0 and a_row < buffer.height
		do
			cursor_position := [a_col, a_row]
			is_cursor_visible := True
		ensure
			cursor_position_attached: cursor_position /= Void
			cursor_visible: is_cursor_visible = True
		end

	show_cursor
			-- Make hardware cursor visible.
		do
			is_cursor_visible := True
		ensure
			cursor_visible: is_cursor_visible = True
		end

	hide_cursor
			-- Hide hardware cursor.
		do
			is_cursor_visible := False
			cursor_position := Void
		ensure
			cursor_hidden: is_cursor_visible = False
			cursor_cleared: cursor_position = Void
		end

invariant
	buffer_not_void: buffer /= Void

end
