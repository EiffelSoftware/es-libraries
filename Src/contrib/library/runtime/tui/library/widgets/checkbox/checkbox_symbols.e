note
	description: "[
		Symbol presets for TUI_CHECKBOX. Each call returns a new IMMUTABLE_STRING_32, so a
		preset cannot be changed by the code that uses it (see B1 in
		review/p2_terminal_widgets_plan.md for what shared mutable presets do).
		  * ASCII (the default): "[x]" / "[ ]".
		  * Unicode: U+2611 BALLOT BOX WITH CHECK / U+2610 BALLOT BOX, one column each.
		  * Radio (for the radio-group recipe in TUI_CHECKBOX's class note): "(" U+2022 ")" / "( )".
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	CHECKBOX_SYMBOLS

feature -- ASCII

	ascii_checked: IMMUTABLE_STRING_32
			-- "[x]"
		do
			create Result.make_from_string_general ("[x]")
		ensure
			instance_free: class
		end

	ascii_unchecked: IMMUTABLE_STRING_32
			-- "[ ]"
		do
			create Result.make_from_string_general ("[ ]")
		ensure
			instance_free: class
		end

feature -- Unicode

	unicode_checked: IMMUTABLE_STRING_32
			-- U+2611 BALLOT BOX WITH CHECK
		do
			create Result.make_from_string_general ({STRING_32} "%/0x2611/")
		ensure
			instance_free: class
		end

	unicode_unchecked: IMMUTABLE_STRING_32
			-- U+2610 BALLOT BOX
		do
			create Result.make_from_string_general ({STRING_32} "%/0x2610/")
		ensure
			instance_free: class
		end

feature -- Radio

	radio_selected: IMMUTABLE_STRING_32
			-- "(" U+2022 BULLET ")"
		do
			create Result.make_from_string_general ({STRING_32} "(%/0x2022/)")
		ensure
			instance_free: class
		end

	radio_unselected: IMMUTABLE_STRING_32
			-- "( )"
		do
			create Result.make_from_string_general ("( )")
		ensure
			instance_free: class
		end

end
