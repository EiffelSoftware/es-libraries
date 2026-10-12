note
	description: "[
		Terminal color abstraction supporting default, 16-color ANSI,
		256-color palette, and 24-bit TrueColor RGB.
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
	make_reset

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

feature -- Status report

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
