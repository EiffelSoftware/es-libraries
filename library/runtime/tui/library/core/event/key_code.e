note
	description: "[
		Key representation distinguishing printable characters from navigation,
		editing, and function keys.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	KEY_CODE

inherit
	ANY
		redefine
			default_create,
			is_equal,
			out
		end

create
	default_create,
	make_char,
	make_special,
	make_function

feature {NONE} -- Initialization

	default_create
			-- Initialize as null/unassigned key.
		do
			kind := Kind_none
			char_value := '%U'
			special_code := 0
		end

	make_char (a_char: CHARACTER_32)
			-- Initialize as printable character key.
		do
			kind := Kind_char
			char_value := a_char
			special_code := 0
		ensure
			is_char: is_char
			char_set: character = a_char
		end

	make_special (a_special: NATURAL_8)
			-- Initialize as special navigation or control key.
		do
			kind := Kind_special
			char_value := '%U'
			special_code := a_special
		ensure
			is_special: is_special
		end

	make_function (a_fn_num: NATURAL_8)
			-- Initialize as function key F1..F35 (F13 and above come from the Kitty protocol).
		require
			valid_fn: a_fn_num >= 1 and a_fn_num <= 35
		do
			kind := Kind_function
			char_value := '%U'
			special_code := a_fn_num
		ensure
			is_function: is_function
			function_number: function_number = a_fn_num
		end

feature -- Status report

	is_char: BOOLEAN
			-- Is this a normal character key?
		do
			Result := kind = Kind_char
		end

	is_special: BOOLEAN
			-- Is this a special navigation/editing key?
		do
			Result := kind = Kind_special
		end

	is_function: BOOLEAN
			-- Is this a function key (F1..F12)?
		do
			Result := kind = Kind_function
		end

	is_up: BOOLEAN
		do
			Result := is_special and special_code = Code_up
		end

	is_down: BOOLEAN
		do
			Result := is_special and special_code = Code_down
		end

	is_left: BOOLEAN
		do
			Result := is_special and special_code = Code_left
		end

	is_right: BOOLEAN
		do
			Result := is_special and special_code = Code_right
		end

	is_enter: BOOLEAN
		do
			Result := is_special and special_code = Code_enter
		end

	is_backspace: BOOLEAN
		do
			Result := is_special and special_code = Code_backspace
		end

	is_tab: BOOLEAN
		do
			Result := is_special and special_code = Code_tab
		end

	is_back_tab: BOOLEAN
		do
			Result := is_special and special_code = Code_back_tab
		end

	is_escape: BOOLEAN
		do
			Result := is_special and special_code = Code_escape
		end

	is_home: BOOLEAN
		do
			Result := is_special and special_code = Code_home
		end

	is_end: BOOLEAN
		do
			Result := is_special and special_code = Code_end
		end

	is_page_up: BOOLEAN
		do
			Result := is_special and special_code = Code_page_up
		end

	is_page_down: BOOLEAN
		do
			Result := is_special and special_code = Code_page_down
		end

	is_delete: BOOLEAN
		do
			Result := is_special and special_code = Code_delete
		end

	is_insert: BOOLEAN
		do
			Result := is_special and special_code = Code_insert
		end

feature -- Access

	character: CHARACTER_32
			-- Character value
		require
			is_char: is_char
		do
			Result := char_value
		end

	function_number: NATURAL_8
			-- Function key index (1..12)
		require
			is_function: is_function
		do
			Result := special_code
		end

feature -- Named Constants (Class features)

	Up: KEY_CODE
		once
			create Result.make_special (Code_up)
		ensure
			instance_free: class
		end

	Down: KEY_CODE
		once
			create Result.make_special (Code_down)
		ensure
			instance_free: class
		end

	Left: KEY_CODE
		once
			create Result.make_special (Code_left)
		ensure
			instance_free: class
		end

	Right: KEY_CODE
		once
			create Result.make_special (Code_right)
		ensure
			instance_free: class
		end

	Enter: KEY_CODE
		once
			create Result.make_special (Code_enter)
		ensure
			instance_free: class
		end

	Backspace: KEY_CODE
		once
			create Result.make_special (Code_backspace)
		ensure
			instance_free: class
		end

	Tab: KEY_CODE
		once
			create Result.make_special (Code_tab)
		ensure
			instance_free: class
		end

	Back_tab: KEY_CODE
		once
			create Result.make_special (Code_back_tab)
		ensure
			instance_free: class
		end

	Escape: KEY_CODE
		once
			create Result.make_special (Code_escape)
		ensure
			instance_free: class
		end

	Home: KEY_CODE
		once
			create Result.make_special (Code_home)
		ensure
			instance_free: class
		end

	End_key: KEY_CODE
		once
			create Result.make_special (Code_end)
		ensure
			instance_free: class
		end

	Page_up: KEY_CODE
		once
			create Result.make_special (Code_page_up)
		ensure
			instance_free: class
		end

	Page_down: KEY_CODE
		once
			create Result.make_special (Code_page_down)
		ensure
			instance_free: class
		end

	Delete: KEY_CODE
		once
			create Result.make_special (Code_delete)
		ensure
			instance_free: class
		end

	Insert: KEY_CODE
		once
			create Result.make_special (Code_insert)
		ensure
			instance_free: class
		end

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Is `Current` equal to `a_other`?
		do
			Result := kind = a_other.kind and
				char_value = a_other.char_value and
				special_code = a_other.special_code
		end

feature -- Output

	out: STRING_8
			-- String representation
		do
			inspect kind
			when Kind_char then
				Result := "Char('" + char_value.out + "')"
			when Kind_function then
				Result := "F" + special_code.out
			when Kind_special then
				inspect special_code
				when Code_up then Result := "Up"
				when Code_down then Result := "Down"
				when Code_left then Result := "Left"
				when Code_right then Result := "Right"
				when Code_enter then Result := "Enter"
				when Code_backspace then Result := "Backspace"
				when Code_tab then Result := "Tab"
				when Code_back_tab then Result := "BackTab"
				when Code_escape then Result := "Escape"
				when Code_home then Result := "Home"
				when Code_end then Result := "End"
				when Code_page_up then Result := "PageUp"
				when Code_page_down then Result := "PageDown"
				when Code_delete then Result := "Delete"
				when Code_insert then Result := "Insert"
				else Result := "Special(" + special_code.out + ")"
				end
			else
				Result := "None"
			end
		end

feature {KEY_CODE} -- Implementation

	Kind_none: NATURAL_8 = 0
	Kind_char: NATURAL_8 = 1
	Kind_special: NATURAL_8 = 2
	Kind_function: NATURAL_8 = 3

	Code_up: NATURAL_8 = 1
	Code_down: NATURAL_8 = 2
	Code_left: NATURAL_8 = 3
	Code_right: NATURAL_8 = 4
	Code_enter: NATURAL_8 = 5
	Code_backspace: NATURAL_8 = 6
	Code_tab: NATURAL_8 = 7
	Code_back_tab: NATURAL_8 = 8
	Code_escape: NATURAL_8 = 9
	Code_home: NATURAL_8 = 10
	Code_end: NATURAL_8 = 11
	Code_page_up: NATURAL_8 = 12
	Code_page_down: NATURAL_8 = 13
	Code_delete: NATURAL_8 = 14
	Code_insert: NATURAL_8 = 15

	kind: NATURAL_8
	char_value: CHARACTER_32
	special_code: NATURAL_8

end
