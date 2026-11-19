note
	description: "[
		Mixin for widgets that can take part in mouse hit-testing. When `hit_id` is set,
		FRAME.render_widget and FRAME.render_stateful_widget register the widget's
		`hit_area` under that id, so the application does not have to call `register_hit`
		itself. The `hit_area` is the whole area the widget was rendered into, unless the
		widget draws on part of it only (TUI_CHECKBOX, TUI_SLIDER) and redefines it.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	HIT_TARGET

feature -- Access

	hit_id: detachable WIDGET_ID
			-- Id registered for the rendered area, or Void for none

	hit_area (a_area: RECT; a_state: detachable WIDGET_STATE): RECT
			-- Part of `a_area` registered under `hit_id` when the widget is rendered into
			-- `a_area` (with `a_state` for a stateful widget, Void otherwise): all of `a_area`.
		require
			area_attached: a_area /= Void
		do
			Result := a_area
		ensure
			result_attached: Result /= Void
			inside: Result.is_empty or else a_area.contains_rect (Result)
		end

feature -- Element change

	set_hit_id (a_id: detachable WIDGET_ID)
			-- Register the rendered area under `a_id` (Void: do not register).
		do
			hit_id := a_id
		ensure
			set: hit_id = a_id
		end

	with_hit_id (a_id: detachable WIDGET_ID): like Current
			-- Copy of Current with `hit_id` set to `a_id`.
		do
			Result := twin
			Result.set_hit_id (a_id)
		ensure
			set: Result.hit_id = a_id
		end

end
