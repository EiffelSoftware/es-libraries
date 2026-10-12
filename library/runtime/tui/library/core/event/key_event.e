note
	description: "[
		Keyboard event carrying a key code, active modifier keys, and event kind
		(press, repeat, or release).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	KEY_EVENT

inherit
	EVENT
		redefine
			is_key,
			is_equal,
			out
		end

create
	make,
	make_with_kind,
	make_char,
	make_special

feature {NONE} -- Initialization

	make (a_code: KEY_CODE; a_modifiers: MODIFIERS)
			-- Initialize with key `a_code` and `a_modifiers` as press event.
		do
			make_with_kind (a_code, a_modifiers, Kind_press)
		ensure
			code_set: code = a_code
			modifiers_set: modifiers = a_modifiers
			is_press: is_press
		end

	make_with_kind (a_code: KEY_CODE; a_modifiers: MODIFIERS; a_kind: NATURAL_8)
			-- Initialize with key `a_code`, `a_modifiers`, and event `a_kind`.
		require
			valid_kind: a_kind = Kind_press or a_kind = Kind_repeat or a_kind = Kind_release
		do
			code := a_code
			modifiers := a_modifiers
			kind := a_kind
		ensure
			code_set: code = a_code
			modifiers_set: modifiers = a_modifiers
			kind_set: kind = a_kind
		end

	make_char (a_char: CHARACTER_32)
			-- Initialize with plain printable character without modifiers as press event.
		do
			create code.make_char (a_char)
			create modifiers.default_create
			kind := Kind_press
		ensure
			char_set: code.is_char and then code.character = a_char
			no_modifiers: modifiers.is_empty
			is_press: is_press
		end

	make_special (a_special: KEY_CODE)
			-- Initialize with special key without modifiers as press event.
		do
			code := a_special
			create modifiers.default_create
			kind := Kind_press
		ensure
			code_set: code = a_special
			no_modifiers: modifiers.is_empty
			is_press: is_press
		end

feature -- Access

	code: KEY_CODE
			-- Key that was pressed or released

	modifiers: MODIFIERS
			-- Active modifiers (Ctrl, Alt, Shift, Super)

	kind: NATURAL_8
			-- Event kind (Kind_press, Kind_repeat, or Kind_release)

feature -- Status report

	is_key: BOOLEAN = True

	is_press: BOOLEAN
			-- Is key press action?
		do
			Result := kind = Kind_press
		end

	is_repeat: BOOLEAN
			-- Is key repeat action?
		do
			Result := kind = Kind_repeat
		end

	is_release: BOOLEAN
			-- Is key release action?
		do
			Result := kind = Kind_release
		end

feature -- Constants

	Kind_press: NATURAL_8 = 1
	Kind_repeat: NATURAL_8 = 2
	Kind_release: NATURAL_8 = 3

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Is `Current` equal to `a_other`?
		do
			Result := code ~ a_other.code and
				modifiers ~ a_other.modifiers and
				kind = a_other.kind
		end

feature -- Output

	out: STRING_8
			-- String representation
		do
			create Result.make (32)
			Result.append (code.out)
			if not modifiers.is_empty then
				Result.append (" [")
				Result.append (modifiers.out)
				Result.append ("]")
			end
			inspect kind
			when Kind_press then
				Result.append (" (Press)")
			when Kind_repeat then
				Result.append (" (Repeat)")
			when Kind_release then
				Result.append (" (Release)")
			else
			end
		end

invariant
	valid_kind: kind = Kind_press or kind = Kind_repeat or kind = Kind_release

end
