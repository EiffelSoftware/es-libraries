note
	description: "[
		Modal popup / dialog container widget with background clearing,
		enclosing container block, and rectangle layout helpers.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_POPUP

inherit
	BLOCK_CONTAINER
		redefine
			default_create
		end

create
	default_create,
	make,
	make_with_widget

feature {NONE} -- Initialization

	default_create
			-- Initialize popup with clear_background enabled.
		do
			clear_background := True
		ensure then
			clears_background_by_default: clear_background
		end

	make
			-- Synonym for `default_create`.
		do
			default_create
		end

	make_with_widget (a_widget: WIDGET)
			-- Initialize with `a_widget` as inner content.
		require
			widget_not_void: a_widget /= Void
		do
			default_create
			inner_widget := a_widget
		ensure
			inner_widget_set: inner_widget = a_widget
		end

feature -- Access

	inner_widget: detachable WIDGET
			-- Widget rendered inside popup's inner area

	clear_background: BOOLEAN
			-- Whether cells behind the popup are cleared before rendering

feature -- Geometry Helpers

	centered_rect (a_percent_x, a_percent_y: NATURAL_16; a_area: RECT): RECT
			-- Calculate a centered rectangle inside `a_area` with percentage dimensions `a_percent_x` and `a_percent_y`.
		require
			area_not_void: a_area /= Void
			valid_percent_x: a_percent_x <= 100
			valid_percent_y: a_percent_y <= 100
		local
			l_w, l_h, l_x, l_y: NATURAL_16
		do
			l_w := ((a_area.width.to_natural_32 * a_percent_x.to_natural_32) // 100).to_natural_16
			l_h := ((a_area.height.to_natural_32 * a_percent_y.to_natural_32) // 100).to_natural_16
			l_x := a_area.x + ((a_area.width - l_w) // 2)
			l_y := a_area.y + ((a_area.height - l_h) // 2)
			create Result.make (l_x, l_y, l_w, l_h)
		ensure
			result_not_void: Result /= Void
		end

	fixed_rect (a_width, a_height: NATURAL_16; a_area: RECT): RECT
			-- Calculate a centered rectangle of fixed dimensions `a_width` and `a_height` inside `a_area`.
			-- Clamped to `a_area` dimensions if larger.
		require
			area_not_void: a_area /= Void
		local
			l_w, l_h, l_x, l_y: NATURAL_16
		do
			l_w := a_width.min (a_area.width)
			l_h := a_height.min (a_area.height)
			l_x := a_area.x + ((a_area.width - l_w) // 2)
			l_y := a_area.y + ((a_area.height - l_h) // 2)
			create Result.make (l_x, l_y, l_w, l_h)
		ensure
			result_not_void: Result /= Void
		end

feature -- Element Change

	set_inner_widget (a_widget: detachable WIDGET)
			-- Set inner content widget.
		do
			inner_widget := a_widget
		ensure
			inner_widget_set: inner_widget = a_widget
		end

	set_clear_background (a_val: BOOLEAN)
			-- Set whether background is cleared before rendering.
		do
			clear_background := a_val
		ensure
			clear_background_set: clear_background = a_val
		end

feature -- Fluent Builders

	with_inner_widget (a_widget: detachable WIDGET): like Current
			-- Return a copy of Current with `inner_widget` set.
		do
			Result := twin
			Result.set_inner_widget (a_widget)
		ensure
			result_not_void: Result /= Void
			inner_widget_set: Result.inner_widget = a_widget
		end

	with_clear_background (a_val: BOOLEAN): like Current
			-- Return a copy of Current with `clear_background` set.
		do
			Result := twin
			Result.set_clear_background (a_val)
		ensure
			result_not_void: Result /= Void
			clear_background_set: Result.clear_background = a_val
		end

feature -- Rendering

	render (a_area: RECT; a_buffer: BUFFER)
			-- Render popup dialog within `a_area` on `a_buffer`.
		local
			l_clear: TUI_CLEAR
			l_inner: RECT
		do
			if not a_area.is_empty then
				if clear_background then
					create l_clear
					l_clear.render (a_area, a_buffer)
				end
				render_block (a_area, a_buffer)
				if attached inner_widget as l_w then
					l_inner := inner_area (a_area)
					if not l_inner.is_empty then
						l_w.render (l_inner, a_buffer)
					end
				end
			end
		end

end
