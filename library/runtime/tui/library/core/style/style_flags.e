note
	description: "[
		Bitwise text style attributes (bold, italic, underline, reverse, etc.)
		with ANSI SGR conversion.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	STYLE_FLAGS

inherit
	ANY
		redefine
			default_create,
			is_equal
		end

create
	default_create,
	make_with_bits

feature {NONE} -- Initialization

	default_create
			-- Initialize with no flags set.
		do
			bits := 0
		ensure then
			is_empty: is_empty
		end

	make_with_bits (a_bits: NATURAL_16)
			-- Initialize with given bitmask.
		do
			bits := a_bits
		ensure
			bits_set: bits = a_bits
		end

feature -- Access

	bits: NATURAL_16
			-- Raw bitmask representation

feature -- Status report

	is_empty: BOOLEAN
			-- Are no style flags enabled?
		do
			Result := bits = 0
		end

	is_bold: BOOLEAN
			-- Is bold enabled?
		do
			Result := (bits & Flag_bold) /= 0
		end

	is_dim: BOOLEAN
			-- Is dim/faint enabled?
		do
			Result := (bits & Flag_dim) /= 0
		end

	is_italic: BOOLEAN
			-- Is italic enabled?
		do
			Result := (bits & Flag_italic) /= 0
		end

	is_underline: BOOLEAN
			-- Is underline enabled?
		do
			Result := (bits & Flag_underline) /= 0
		end

	is_blink: BOOLEAN
			-- Is blinking enabled?
		do
			Result := (bits & Flag_blink) /= 0
		end

	is_reverse: BOOLEAN
			-- Is reverse video enabled?
		do
			Result := (bits & Flag_reverse) /= 0
		end

	is_hidden: BOOLEAN
			-- Is text hidden?
		do
			Result := (bits & Flag_hidden) /= 0
		end

	is_strikethrough: BOOLEAN
			-- Is text crossed out?
		do
			Result := (bits & Flag_strikethrough) /= 0
		end

feature {STYLE, STYLE_FLAGS} -- Element change
		-- Restricted like the `STYLE` setters: the flag sets of a (shared, immutable) style must
		-- not be changed through `{STYLE}.flags`. Build new sets with `make_with_bits`, `+` and `-`.

	set_bold (a_enabled: BOOLEAN)
			-- Set bold attribute.
		do
			if a_enabled then
				bits := bits | Flag_bold
			else
				bits := bits & (Flag_bold.bit_not)
			end
		ensure
			bold_set: is_bold = a_enabled
		end

	set_dim (a_enabled: BOOLEAN)
			-- Set dim attribute.
		do
			if a_enabled then
				bits := bits | Flag_dim
			else
				bits := bits & (Flag_dim.bit_not)
			end
		ensure
			dim_set: is_dim = a_enabled
		end

	set_italic (a_enabled: BOOLEAN)
			-- Set italic attribute.
		do
			if a_enabled then
				bits := bits | Flag_italic
			else
				bits := bits & (Flag_italic.bit_not)
			end
		ensure
			italic_set: is_italic = a_enabled
		end

	set_underline (a_enabled: BOOLEAN)
			-- Set underline attribute.
		do
			if a_enabled then
				bits := bits | Flag_underline
			else
				bits := bits & (Flag_underline.bit_not)
			end
		ensure
			underline_set: is_underline = a_enabled
		end

	set_reverse (a_enabled: BOOLEAN)
			-- Set reverse video attribute.
		do
			if a_enabled then
				bits := bits | Flag_reverse
			else
				bits := bits & (Flag_reverse.bit_not)
			end
		ensure
			reverse_set: is_reverse = a_enabled
		end

	set_blink (a_enabled: BOOLEAN)
			-- Set blinking attribute.
		do
			if a_enabled then
				bits := bits | Flag_blink
			else
				bits := bits & (Flag_blink.bit_not)
			end
		ensure
			blink_set: is_blink = a_enabled
		end

	set_hidden (a_enabled: BOOLEAN)
			-- Set hidden text attribute.
		do
			if a_enabled then
				bits := bits | Flag_hidden
			else
				bits := bits & (Flag_hidden.bit_not)
			end
		ensure
			hidden_set: is_hidden = a_enabled
		end

	set_strikethrough (a_enabled: BOOLEAN)
			-- Set strikethrough attribute.
		do
			if a_enabled then
				bits := bits | Flag_strikethrough
			else
				bits := bits & (Flag_strikethrough.bit_not)
			end
		ensure
			strikethrough_set: is_strikethrough = a_enabled
		end

	add_flag (a_flag: NATURAL_16)
			-- Enable modifier `a_flag`.
		do
			bits := bits | a_flag
		ensure
			flag_added: has_flag (a_flag)
		end

	remove_flag (a_flag: NATURAL_16)
			-- Disable modifier `a_flag`.
		do
			bits := bits & (a_flag.bit_not)
		ensure
			flag_removed: not has_flag (a_flag)
		end

	set_bits (a_bits: NATURAL_16)
			-- Set raw bits.
		do
			bits := a_bits
		ensure
			bits_set: bits = a_bits
		end

	wipe_out
			-- Clear all flags.
		do
			bits := 0
		ensure
			empty: is_empty
		end

feature -- Status report

	has_flag (a_flag: NATURAL_16): BOOLEAN
			-- Is modifier `a_flag` enabled?
		do
			Result := (bits & a_flag) = a_flag
		end

feature -- Operations

	plus alias "+" (a_other: STYLE_FLAGS): STYLE_FLAGS
			-- Union of current flags with `a_other`
		do
			create Result.make_with_bits (bits | a_other.bits)
		end

	minus alias "-" (a_other: STYLE_FLAGS): STYLE_FLAGS
			-- Difference of current flags removing `a_other`
		do
			create Result.make_with_bits (bits & (a_other.bits.bit_not))
		end

feature -- ANSI Generation

	sgr_codes: STRING_8
			-- Semicolon-separated SGR codes for active flags
		do
			create Result.make (16)
			if is_bold then
				append_code (Result, "1")
			end
			if is_dim then
				append_code (Result, "2")
			end
			if is_italic then
				append_code (Result, "3")
			end
			if is_underline then
				append_code (Result, "4")
			end
			if is_blink then
				append_code (Result, "5")
			end
			if is_reverse then
				append_code (Result, "7")
			end
			if is_hidden then
				append_code (Result, "8")
			end
			if is_strikethrough then
				append_code (Result, "9")
			end
		end

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Is `Current` equal to `a_other`?
		do
			Result := bits = a_other.bits
		end

feature -- Constants: Flags

	Flag_bold: NATURAL_16 = 1
	Flag_dim: NATURAL_16 = 2
	Flag_italic: NATURAL_16 = 4
	Flag_underline: NATURAL_16 = 8
	Flag_blink: NATURAL_16 = 16
	Flag_reverse: NATURAL_16 = 32
	Flag_hidden: NATURAL_16 = 64
	Flag_strikethrough: NATURAL_16 = 128

feature {NONE} -- Implementation

	append_code (a_target: STRING_8; a_code: STRING_8)
			-- Append `a_code` to `a_target`, adding a semicolon if not empty.
		do
			if not a_target.is_empty then
				a_target.append_character (';')
			end
			a_target.append (a_code)
		end

end
