note
	description: "[
		Terminal color abstraction supporting default, 16-color ANSI,
		256-color palette, and 24-bit TrueColor RGB.

		Colors can be read from text and written back (`make_from_string`, `as_string`), as
		Ratatui's `Color::from_str` and `Display`. Ratatui's names are not EiffelTUI's
		constant names for the grays: "white" is ANSI 15 (`Bright_white`), "gray" is ANSI 7
		(`White`, `Gray`) and "darkgray" is ANSI 8 (`Bright_black`, `Dark_gray`).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	COLOR

inherit
	ANY
		redefine
			default_create,
			is_equal,
			out
		end

create
	default_create,
	make_ansi,
	make_indexed,
	make_rgb,
	make_reset,
	make_from_string

feature {NONE} -- Initialization

	default_create
			-- Initialize as default/reset color.
		do
			kind := Kind_default
			code := 0
			red_val := 0
			green_val := 0
			blue_val := 0
		ensure then
			is_default: is_default
		end

	make_ansi (a_code: NATURAL_8)
			-- Initialize with standard ANSI 16-color code (0..15).
		require
			valid_ansi_code: a_code <= 15
		do
			kind := Kind_ansi
			code := a_code
			red_val := 0
			green_val := 0
			blue_val := 0
		ensure
			is_ansi: is_ansi
			code_set: ansi_code = a_code
		end

	make_indexed (a_index: NATURAL_8)
			-- Initialize with 256-color palette index (0..255).
		do
			kind := Kind_indexed
			code := a_index
			red_val := 0
			green_val := 0
			blue_val := 0
		ensure
			is_indexed: is_indexed
			index_set: index = a_index
		end

	make_rgb (a_r, a_g, a_b: NATURAL_8)
			-- Initialize with 24-bit TrueColor RGB values.
		do
			kind := Kind_rgb
			code := 0
			red_val := a_r
			green_val := a_g
			blue_val := a_b
		ensure
			is_rgb: is_rgb
			r_set: r = a_r
			g_set: g = a_g
			b_set: b = a_b
		end

	make_reset
			-- Initialize as an explicit reset: like the default color on screen, but a style
			-- patch with a reset color clears the underlying color (Ratatui `Color::Reset`),
			-- whereas a default color leaves it unchanged.
		do
			kind := Kind_reset
			code := 0
			red_val := 0
			green_val := 0
			blue_val := 0
		ensure
			is_reset: is_reset
		end

	make_from_string (a_text: READABLE_STRING_GENERAL)
			-- Initialize from `a_text`, read as Ratatui's `Color::from_str` reads it:
			-- * a name, after lower-casing, removing spaces, "-" and "_", and the aliases
			--   "bright" = "light", "grey" = "silver" = "gray", "lightblack" = "darkgray",
			--   "lightwhite" = "lightgray" = "white": one of the 16 ANSI colors, or "reset";
			-- * else a palette index "0" .. "255" (as Rust reads a `u8`: an optional "+",
			--   then decimal digits);
			-- * else "#rrggbb" (each pair as Rust's `u8::from_str_radix`: two hex digits, or
			--   "+" and one).
			-- "default" (any case, as a name) gives the default color, which Ratatui does not
			-- have, so that every color reads back from `as_string`.
		require
			valid_text: is_valid_color_string (a_text)
		do
			if attached parsed (a_text) as l_color then
				kind := l_color.kind
				code := l_color.code
				red_val := l_color.red_val
				green_val := l_color.green_val
				blue_val := l_color.blue_val
			end
		ensure
			parsed: attached parsed (a_text) as l_color and then is_equal (l_color)
		end

feature -- Status report

	is_valid_color_string (a_text: READABLE_STRING_GENERAL): BOOLEAN
			-- Does `a_text` name a color for `make_from_string`? (Ratatui: `from_str` is `Ok`)
		do
			Result := parsed (a_text) /= Void
		ensure
			instance_free: class
		end

	is_reset: BOOLEAN
			-- Is this an explicit reset to the terminal default color?
		do
			Result := kind = Kind_reset
		end

	renders_as_default: BOOLEAN
			-- Is this displayed as the terminal default color (default or reset)?
		do
			Result := kind = Kind_default or kind = Kind_reset
		end

	same_rendering (a_other: COLOR): BOOLEAN
			-- Is `Current` displayed the same as `a_other`?
		do
			if renders_as_default then
				Result := a_other.renders_as_default
			else
				Result := is_equal (a_other)
			end
		end

	is_default: BOOLEAN
			-- Is this the default terminal color?
		do
			Result := kind = Kind_default
		end

	is_ansi: BOOLEAN
			-- Is this a standard 16-color ANSI color?
		do
			Result := kind = Kind_ansi
		end

	is_indexed: BOOLEAN
			-- Is this an 8-bit palette (256-color) indexed color?
		do
			Result := kind = Kind_indexed
		end

	is_rgb: BOOLEAN
			-- Is this a 24-bit TrueColor RGB color?
		do
			Result := kind = Kind_rgb
		end

feature -- Access

	ansi_code: NATURAL_8
			-- Standard ANSI 16-color code (0..15)
		require
			is_ansi: is_ansi
		do
			Result := code
		end

	index: NATURAL_8
			-- 256-color palette index (0..255)
		require
			is_indexed: is_indexed
		do
			Result := code
		end

	r: NATURAL_8
			-- Red component (0..255)
		require
			is_rgb: is_rgb
		do
			Result := red_val
		end

	g: NATURAL_8
			-- Green component (0..255)
		require
			is_rgb: is_rgb
		do
			Result := green_val
		end

	b: NATURAL_8
			-- Blue component (0..255)
		require
			is_rgb: is_rgb
		do
			Result := blue_val
		end

feature -- ANSI SGR Generation

	sgr_fg: STRING_8
			-- ANSI SGR escape sequence parameter for foreground color
		do
			inspect kind
			when Kind_ansi then
				if code < 8 then
					Result := (30 + code.to_integer_32).out
				else
					Result := (90 + (code - 8).to_integer_32).out
				end
			when Kind_indexed then
				Result := "38;5;" + code.out
			when Kind_rgb then
				Result := "38;2;" + red_val.out + ";" + green_val.out + ";" + blue_val.out
			else
				Result := "39" -- Default foreground
			end
		ensure
			sgr_not_empty: not Result.is_empty
		end

	sgr_bg: STRING_8
			-- ANSI SGR escape sequence parameter for background color
		do
			inspect kind
			when Kind_ansi then
				if code < 8 then
					Result := (40 + code.to_integer_32).out
				else
					Result := (100 + (code - 8).to_integer_32).out
				end
			when Kind_indexed then
				Result := "48;5;" + code.out
			when Kind_rgb then
				Result := "48;2;" + red_val.out + ";" + green_val.out + ";" + blue_val.out
			else
				Result := "49" -- Default background
			end
		ensure
			sgr_not_empty: not Result.is_empty
		end

	sgr_ul: STRING_8
			-- ANSI SGR escape sequence parameter for underline color
		do
			inspect kind
			when Kind_ansi then
				Result := "58;5;" + code.out
			when Kind_indexed then
				Result := "58;5;" + code.out
			when Kind_rgb then
				Result := "58;2;" + red_val.out + ";" + green_val.out + ";" + blue_val.out
			else
				Result := "59" -- Default underline color
			end
		ensure
			sgr_not_empty: not Result.is_empty
		end

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Is `Current` equal to `a_other`?
		do
			if kind = a_other.kind then
				inspect kind
				when Kind_default, Kind_reset then
					Result := True
				when Kind_ansi, Kind_indexed then
					Result := code = a_other.code
				when Kind_rgb then
					Result := red_val = a_other.red_val and
						green_val = a_other.green_val and
						blue_val = a_other.blue_val
				end
			end
		end

feature -- Output

	out: STRING_8
			-- String representation of color
		do
			inspect kind
			when Kind_default then
				Result := "Default"
			when Kind_reset then
				Result := "Reset"
			when Kind_ansi then
				Result := "Ansi(" + code.out + ")"
			when Kind_indexed then
				Result := "Indexed(" + code.out + ")"
			when Kind_rgb then
				Result := "Rgb(" + red_val.out + "," + green_val.out + "," + blue_val.out + ")"
			end
		end

	as_string: STRING_8
			-- Text that `make_from_string` reads back as this color, as Ratatui's `Display`:
			-- the ANSI colors by Ratatui name ("LightRed", "Gray", "White" for ANSI 15),
			-- "#RRGGBB", the palette index ("10"), "Reset"; and "Default" for the default color
		do
			inspect kind
			when Kind_ansi then
				Result := Ansi_names.item (code.to_integer_32).twin
			when Kind_indexed then
				Result := code.out
			when Kind_rgb then
				create Result.make (7)
				Result.append_character ('#')
				append_hex (red_val, Result)
				append_hex (green_val, Result)
				append_hex (blue_val, Result)
			when Kind_reset then
				Result := "Reset"
			else
				Result := "Default"
			end
		ensure
			reads_back: is_valid_color_string (Result) and then is_equal (create {COLOR}.make_from_string (Result))
		end

feature -- Named Constants (Once functions)

	Black: COLOR
		once
			create Result.make_ansi (0)
		ensure
			instance_free: class
		end

	Red: COLOR
		once
			create Result.make_ansi (1)
		ensure
			instance_free: class
		end

	Green: COLOR
		once
			create Result.make_ansi (2)
		ensure
			instance_free: class
		end

	Yellow: COLOR
		once
			create Result.make_ansi (3)
		ensure
			instance_free: class
		end

	Blue: COLOR
		once
			create Result.make_ansi (4)
		ensure
			instance_free: class
		end

	Magenta: COLOR
		once
			create Result.make_ansi (5)
		ensure
			instance_free: class
		end

	Cyan: COLOR
		once
			create Result.make_ansi (6)
		ensure
			instance_free: class
		end

	White: COLOR
		once
			create Result.make_ansi (7)
		ensure
			instance_free: class
		end

	Bright_black: COLOR
		once
			create Result.make_ansi (8)
		ensure
			instance_free: class
		end

	Bright_red: COLOR
		once
			create Result.make_ansi (9)
		ensure
			instance_free: class
		end

	Bright_green: COLOR
		once
			create Result.make_ansi (10)
		ensure
			instance_free: class
		end

	Bright_yellow: COLOR
		once
			create Result.make_ansi (11)
		ensure
			instance_free: class
		end

	Bright_blue: COLOR
		once
			create Result.make_ansi (12)
		ensure
			instance_free: class
		end

	Bright_magenta: COLOR
		once
			create Result.make_ansi (13)
		ensure
			instance_free: class
		end

	Bright_cyan: COLOR
		once
			create Result.make_ansi (14)
		ensure
			instance_free: class
		end

	Bright_white: COLOR
		once
			create Result.make_ansi (15)
		ensure
			instance_free: class
		end

	Dark_gray: COLOR
			-- Ratatui `Color::DarkGray` (ANSI 8)
		once
			Result := Bright_black
		ensure
			instance_free: class
		end

	Gray: COLOR
			-- Ratatui `Color::Gray` (ANSI 7; `White` is ANSI 15 in Ratatui)
		once
			Result := White
		ensure
			instance_free: class
		end

	Light_cyan: COLOR
		once
			Result := Bright_cyan
		ensure
			instance_free: class
		end

	rgb (a_r, a_g, a_b: NATURAL_8): COLOR
			-- New 24-bit TrueColor RGB instance.
		do
			create Result.make_rgb (a_r, a_g, a_b)
		ensure
			instance_free: class
			result_not_void: Result /= Void
		end

	Reset_color: COLOR
			-- Explicit reset to the terminal default (clears a color when used in a patch,
			-- like Ratatui `Color::Reset`)
		once
			create Result.make_reset
		ensure
			instance_free: class
		end

feature {NONE} -- Parsing

	parsed (a_text: READABLE_STRING_GENERAL): detachable COLOR
			-- The color `a_text` names (see `make_from_string`), or Void.
			-- As in Ratatui, the index and the hex forms are read from `a_text` itself, not
			-- from the normalized name, so " 10" and "# ff0000" are not colors.
		local
			l_name: STRING_32
			l_index, l_r, l_g, l_b, i: INTEGER
		do
			l_name := normalized_name (a_text)
			if l_name.same_string ("reset") then
				create Result.make_reset
			elseif l_name.same_string ("default") then
				create Result
			else
				from
					i := 0
				until
					i > 15 or Result /= Void
				loop
					if l_name.same_string (Ansi_keys.item (i)) then
						create Result.make_ansi (i.to_natural_8)
					end
					i := i + 1
				end
			end
			if Result = Void then
				l_index := palette_index (a_text)
				if l_index >= 0 then
					create Result.make_indexed (l_index.to_natural_8)
				elseif a_text.count = 7 and then a_text.code (1) = ('#').natural_32_code then
					l_r := hex_byte (a_text, 2)
					l_g := hex_byte (a_text, 4)
					l_b := hex_byte (a_text, 6)
					if l_r >= 0 and l_g >= 0 and l_b >= 0 then
						create Result.make_rgb (l_r.to_natural_8, l_g.to_natural_8, l_b.to_natural_8)
					end
				end
			end
		ensure
			instance_free: class
		end

	normalized_name (a_text: READABLE_STRING_GENERAL): STRING_32
			-- `a_text` as Ratatui compares it with the color names: lower case, without
			-- spaces, "-" and "_", then the aliases replaced in Ratatui's order
		do
			create Result.make_from_string_general (a_text)
			Result.to_lower
			Result.prune_all (' ')
			Result.prune_all ('-')
			Result.prune_all ('_')
			Result.replace_substring_all ({STRING_32} "bright", {STRING_32} "light")
			Result.replace_substring_all ({STRING_32} "grey", {STRING_32} "gray")
			Result.replace_substring_all ({STRING_32} "silver", {STRING_32} "gray")
			Result.replace_substring_all ({STRING_32} "lightblack", {STRING_32} "darkgray")
			Result.replace_substring_all ({STRING_32} "lightwhite", {STRING_32} "white")
			Result.replace_substring_all ({STRING_32} "lightgray", {STRING_32} "white")
		ensure
			instance_free: class
		end

	palette_index (a_text: READABLE_STRING_GENERAL): INTEGER
			-- `a_text` as Rust's `u8::from_str` reads it (an optional "+", then one or more
			-- decimal digits, at most 255), or -1
		local
			i, l_digit: INTEGER
		do
			i := 1
			if a_text.count >= 1 and then a_text.code (1) = ('+').natural_32_code then
				i := 2
			end
			if i > a_text.count then
				Result := -1
			end
			from
			until
				i > a_text.count or Result < 0
			loop
				l_digit := a_text.code (i).to_integer_32 - ('0').code
				if l_digit < 0 or l_digit > 9 then
					Result := -1
				else
					Result := Result * 10 + l_digit
					if Result > 255 then
						Result := -1
					end
				end
				i := i + 1
			end
		ensure
			instance_free: class
			in_range: Result >= -1 and Result <= 255
		end

	hex_byte (a_text: READABLE_STRING_GENERAL; a_pos: INTEGER): INTEGER
			-- The two characters of `a_text` at `a_pos` as Rust's `u8::from_str_radix (_, 16)`
			-- reads them (two hex digits, or "+" and one), or -1
		require
			valid_pos: a_pos >= 1 and a_pos < a_text.count
		local
			l_high, l_low: INTEGER
		do
			l_low := hex_value (a_text.code (a_pos + 1))
			if a_text.code (a_pos) = ('+').natural_32_code then
				Result := l_low
			else
				l_high := hex_value (a_text.code (a_pos))
				if l_high >= 0 and l_low >= 0 then
					Result := l_high * 16 + l_low
				else
					Result := -1
				end
			end
		ensure
			instance_free: class
			in_range: Result >= -1 and Result <= 255
		end

	hex_value (a_code: NATURAL_32): INTEGER
			-- Value of the hex digit `a_code` (either case), or -1
		do
			inspect a_code
			when 48 .. 57 then
				Result := (a_code - 48).to_integer_32
			when 65 .. 70 then
				Result := (a_code - 55).to_integer_32
			when 97 .. 102 then
				Result := (a_code - 87).to_integer_32
			else
				Result := -1
			end
		ensure
			instance_free: class
		end

	append_hex (a_value: NATURAL_8; a_target: STRING_8)
			-- Append `a_value` to `a_target` as two upper-case hex digits.
		do
			a_target.append_character (Hex_digits.item ((a_value // 16).to_integer_32 + 1))
			a_target.append_character (Hex_digits.item ((a_value \\ 16).to_integer_32 + 1))
		ensure
			two_more: a_target.count = old a_target.count + 2
		end

	Hex_digits: STRING_8 = "0123456789ABCDEF"

	Ansi_names: ARRAY [STRING_8]
			-- Ratatui's names of the ANSI colors 0 .. 15 (`Display`)
		once
			Result := <<"Black", "Red", "Green", "Yellow", "Blue", "Magenta", "Cyan", "Gray",
				"DarkGray", "LightRed", "LightGreen", "LightYellow", "LightBlue", "LightMagenta",
				"LightCyan", "White">>
			Result.rebase (0)
		ensure
			instance_free: class
			sixteen: Result.lower = 0 and Result.count = 16
		end

	Ansi_keys: ARRAY [STRING_32]
			-- `Ansi_names` in lower case, as `normalized_name` gives them
		local
			i: INTEGER
		once
			create Result.make_filled ({STRING_32} "", 0, 15)
			from
				i := 0
			until
				i > 15
			loop
				Result.put (Ansi_names.item (i).as_lower.to_string_32, i)
				i := i + 1
			end
		ensure
			instance_free: class
			sixteen: Result.lower = 0 and Result.count = 16
		end

feature {COLOR} -- Implementation

	Kind_default: NATURAL_8 = 0
	Kind_ansi: NATURAL_8 = 1
	Kind_indexed: NATURAL_8 = 2
	Kind_rgb: NATURAL_8 = 3
	Kind_reset: NATURAL_8 = 4

	kind: NATURAL_8
			-- Color category

	code: NATURAL_8
			-- Ansi code or palette index

	red_val, green_val, blue_val: NATURAL_8
			-- RGB components

end
