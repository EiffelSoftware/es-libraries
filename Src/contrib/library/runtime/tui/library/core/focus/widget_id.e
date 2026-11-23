note
	description: "[
		Stable identifier for a focusable control in an immediate-mode UI.
		Apps typically use small integer constants for form fields and buttons.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	WIDGET_ID

inherit
	ANY
		redefine
			is_equal,
			out
		end

create
	make

feature {NONE} -- Initialization

	make (a_value: INTEGER)
			-- Initialize with numeric `a_value`.
		do
			value := a_value
		ensure
			value_set: value = a_value
		end

feature -- Access

	value: INTEGER
			-- Numeric identity of this widget

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Same numeric identity?
		do
			Result := value = a_other.value
		end

feature -- Output

	out: STRING
			-- Textual form of `value`.
		do
			Result := value.out
		end

end
