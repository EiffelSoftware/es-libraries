note
	description: "[
		Mouse event carrying cell coordinates, action kind (click, release, scroll, drag),
		and modifier keys.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	MOUSE_EVENT

inherit
	EVENT
		redefine
			is_mouse
		end

create
	make

feature {NONE} -- Initialization

	make (a_kind, a_button: NATURAL_8; a_col, a_row: NATURAL_16; a_modifiers: MODIFIERS)
			-- Initialize mouse event.
		do
			kind := a_kind
			button := a_button
			column := a_col
			row := a_row
			modifiers := a_modifiers
		ensure
			kind_set: kind = a_kind
			button_set: button = a_button
			column_set: column = a_col
			row_set: row = a_row
			modifiers_set: modifiers = a_modifiers
		end

feature -- Access

	kind: NATURAL_8
			-- Mouse action kind

	button: NATURAL_8
			-- Mouse button (0=Left, 1=Middle, 2=Right)

	column: NATURAL_16
			-- 0-based column coordinate

	row: NATURAL_16
			-- 0-based row coordinate

	modifiers: MODIFIERS
			-- Active modifiers during mouse action

feature -- Status report

	is_mouse: BOOLEAN = True

	is_down: BOOLEAN
		do
			Result := kind = Kind_down
		end

	is_up: BOOLEAN
		do
			Result := kind = Kind_up
		end

	is_drag: BOOLEAN
		do
			Result := kind = Kind_drag
		end

	is_move: BOOLEAN
		do
			Result := kind = Kind_move
		end

	is_scroll_up: BOOLEAN
		do
			Result := kind = Kind_scroll_up
		end

	is_scroll_down: BOOLEAN
		do
			Result := kind = Kind_scroll_down
		end

	is_scroll_left: BOOLEAN
		do
			Result := kind = Kind_scroll_left
		end

	is_scroll_right: BOOLEAN
		do
			Result := kind = Kind_scroll_right
		end

feature -- Constants

	Kind_down: NATURAL_8 = 1
	Kind_up: NATURAL_8 = 2
	Kind_drag: NATURAL_8 = 3
	Kind_move: NATURAL_8 = 4
	Kind_scroll_up: NATURAL_8 = 5
	Kind_scroll_down: NATURAL_8 = 6
	Kind_scroll_left: NATURAL_8 = 7
	Kind_scroll_right: NATURAL_8 = 8

	Button_left: NATURAL_8 = 0
	Button_middle: NATURAL_8 = 1
	Button_right: NATURAL_8 = 2

end
