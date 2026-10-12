note
	description: "[
		Keyboard/Mouse modifier keys (Shift, Control, Alt, Super).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	MODIFIERS

inherit
	ANY
		redefine
			default_create,
			is_equal,
			out
		end

create
	default_create,
	make_with_bits

feature {NONE} -- Initialization

	default_create
			-- Initialize with no modifiers active.
		do
			bits := 0
		ensure then
			is_empty: is_empty
		end

	make_with_bits (a_bits: NATURAL_8)
			-- Initialize with raw bitmask.
		do
			bits := a_bits
		ensure
			bits_set: bits = a_bits
		end

feature -- Access

	bits: NATURAL_8
			-- Modifier bitmask

feature -- Status report

	is_empty: BOOLEAN
			-- Are no modifier keys pressed?
		do
			Result := bits = 0
		end

	is_shift: BOOLEAN
			-- Is Shift key pressed?
		do
			Result := (bits & Flag_shift) /= 0
		end

	is_control: BOOLEAN
			-- Is Control key pressed?
		do
			Result := (bits & Flag_control) /= 0
		end

	is_alt: BOOLEAN
			-- Is Alt / Option key pressed?
		do
			Result := (bits & Flag_alt) /= 0
		end

	is_super: BOOLEAN
			-- Is Super / Windows / Command key pressed?
		do
			Result := (bits & Flag_super) /= 0
		end

feature -- Element change

	set_shift (a_val: BOOLEAN)
			-- Set Shift status.
		do
			if a_val then
				bits := bits | Flag_shift
			else
				bits := bits & (Flag_shift.bit_not)
			end
		ensure
			shift_set: is_shift = a_val
		end

	set_control (a_val: BOOLEAN)
			-- Set Control status.
		do
			if a_val then
				bits := bits | Flag_control
			else
				bits := bits & (Flag_control.bit_not)
			end
		ensure
			control_set: is_control = a_val
		end

	set_alt (a_val: BOOLEAN)
			-- Set Alt status.
		do
			if a_val then
				bits := bits | Flag_alt
			else
				bits := bits & (Flag_alt.bit_not)
			end
		ensure
			alt_set: is_alt = a_val
		end

	set_super (a_val: BOOLEAN)
			-- Set Super status.
		do
			if a_val then
				bits := bits | Flag_super
			else
				bits := bits & (Flag_super.bit_not)
			end
		ensure
			super_set: is_super = a_val
		end

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Is `Current` equal to `a_other`?
		do
			Result := bits = a_other.bits
		end

feature -- Output

	out: STRING_8
			-- String representation
		do
			create Result.make (16)
			if is_control then
				Result.append ("Ctrl+")
			end
			if is_alt then
				Result.append ("Alt+")
			end
			if is_shift then
				Result.append ("Shift+")
			end
			if is_super then
				Result.append ("Super+")
			end
			if Result.is_empty then
				Result.append ("None")
			elseif Result.ends_with ("+") then
				Result.remove_tail (1)
			end
		end

feature {NONE} -- Constants

	Flag_shift: NATURAL_8 = 1
	Flag_control: NATURAL_8 = 2
	Flag_alt: NATURAL_8 = 4
	Flag_super: NATURAL_8 = 8

end
