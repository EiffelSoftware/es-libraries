note
	description: "[
		Visual appearance of a cell or text fragment, combining foreground color,
		background color, underline color, and text style modifier flags.
		Supports value operations (`twin`, `is_equal`, `same_rendering`), fluent builders that
		return copies (`with_*`), and patch composition. Styles are immutable for clients: the
		setters (`set_*`), `copy` and the `STYLE_FLAGS` mutators are exported to {STYLE} only,
		so one style object can be shared by many cells and widgets (see TERMINAL_CELL).
		Use `twin` for a copy.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	STYLE

inherit
	ANY
		export
			{STYLE} copy
		redefine
			default_create,
			is_equal,
			copy
		end

create
	default_create,
	make_with_colors,
	make_fg,
	make_bg

feature {NONE} -- Initialization

	default_create
			-- Initialize with default colors and no modifier flags.
		do
			create foreground
			create background
			create underline_color
			create flags
			create add_modifier
			create sub_modifier
		ensure then
			default_fg: foreground.is_default
			default_bg: background.is_default
			default_ul: underline_color.is_default
			no_flags: flags.is_empty
		end

	make_with_colors (a_fg, a_bg: COLOR)
			-- Initialize with given foreground and background colors.
		do
			foreground := a_fg
			background := a_bg
			create underline_color
			create flags
			create add_modifier
			create sub_modifier
		ensure
			fg_set: foreground = a_fg
			bg_set: background = a_bg
		end

	make_fg (a_fg: COLOR)
			-- Initialize with foreground color and default background.
		do
			foreground := a_fg
			create background
			create underline_color
			create flags
			create add_modifier
			create sub_modifier
		ensure
			fg_set: foreground = a_fg
			default_bg: background.is_default
		end

	make_bg (a_bg: COLOR)
			-- Initialize with background color and default foreground.
		do
			create foreground
			background := a_bg
			create underline_color
			create flags
			create add_modifier
			create sub_modifier
		ensure
			default_fg: foreground.is_default
			bg_set: background = a_bg
		end

feature -- Access

	foreground: COLOR
			-- Text foreground color

	background: COLOR
			-- Cell background color

	underline_color: COLOR
			-- Underline color

	flags: STYLE_FLAGS
			-- Active modifier flags (bold, italic, underline, etc.)

	add_modifier: STYLE_FLAGS
			-- Modifiers to add during patch composition

	sub_modifier: STYLE_FLAGS
			-- Modifiers to remove during patch composition

	is_bold: BOOLEAN
			-- Is bold attribute active?
		do
			Result := flags.is_bold
		end

	is_dim: BOOLEAN
			-- Is dim attribute active?
		do
			Result := flags.is_dim
		end

	is_italic: BOOLEAN
			-- Is italic attribute active?
		do
			Result := flags.is_italic
		end

	is_underlined: BOOLEAN
			-- Is underline attribute active?
		do
			Result := flags.is_underline
		end

	is_reversed: BOOLEAN
			-- Is reverse video attribute active?
		do
			Result := flags.is_reverse
		end

feature {STYLE} -- Element change (internal)

	set_foreground (a_fg: COLOR)
			-- Set foreground color.
		do
			foreground := a_fg
		ensure
			fg_set: foreground = a_fg
		end

	set_background (a_bg: COLOR)
			-- Set background color.
		do
			background := a_bg
		ensure
			bg_set: background = a_bg
		end

	set_underline_color (a_color: COLOR)
			-- Set underline color.
		do
			underline_color := a_color
		ensure
			ul_set: underline_color = a_color
		end

	set_bold (a_enabled: BOOLEAN)
			-- Set bold attribute.
		do
			flags.set_bold (a_enabled)
			if a_enabled then
				add_modifier.add_flag ({STYLE_FLAGS}.flag_bold)
				sub_modifier.remove_flag ({STYLE_FLAGS}.flag_bold)
			else
				add_modifier.remove_flag ({STYLE_FLAGS}.flag_bold)
				sub_modifier.add_flag ({STYLE_FLAGS}.flag_bold)
			end
		end

	set_dim (a_enabled: BOOLEAN)
			-- Set dim attribute.
		do
			flags.set_dim (a_enabled)
			if a_enabled then
				add_modifier.add_flag ({STYLE_FLAGS}.flag_dim)
				sub_modifier.remove_flag ({STYLE_FLAGS}.flag_dim)
			else
				add_modifier.remove_flag ({STYLE_FLAGS}.flag_dim)
				sub_modifier.add_flag ({STYLE_FLAGS}.flag_dim)
			end
		end

	set_italic (a_enabled: BOOLEAN)
			-- Set italic attribute.
		do
			flags.set_italic (a_enabled)
			if a_enabled then
				add_modifier.add_flag ({STYLE_FLAGS}.flag_italic)
				sub_modifier.remove_flag ({STYLE_FLAGS}.flag_italic)
			else
				add_modifier.remove_flag ({STYLE_FLAGS}.flag_italic)
				sub_modifier.add_flag ({STYLE_FLAGS}.flag_italic)
			end
		end

	set_underline (a_enabled: BOOLEAN)
			-- Set underline attribute.
		do
			flags.set_underline (a_enabled)
			if a_enabled then
				add_modifier.add_flag ({STYLE_FLAGS}.flag_underline)
				sub_modifier.remove_flag ({STYLE_FLAGS}.flag_underline)
			else
				add_modifier.remove_flag ({STYLE_FLAGS}.flag_underline)
				sub_modifier.add_flag ({STYLE_FLAGS}.flag_underline)
			end
		end

	set_blink (a_enabled: BOOLEAN)
			-- Set blink attribute.
		do
			flags.set_blink (a_enabled)
			if a_enabled then
				add_modifier.add_flag ({STYLE_FLAGS}.flag_blink)
				sub_modifier.remove_flag ({STYLE_FLAGS}.flag_blink)
			else
				add_modifier.remove_flag ({STYLE_FLAGS}.flag_blink)
				sub_modifier.add_flag ({STYLE_FLAGS}.flag_blink)
			end
		end

	set_reverse (a_enabled: BOOLEAN)
			-- Set reverse video attribute.
		do
			flags.set_reverse (a_enabled)
			if a_enabled then
				add_modifier.add_flag ({STYLE_FLAGS}.flag_reverse)
				sub_modifier.remove_flag ({STYLE_FLAGS}.flag_reverse)
			else
				add_modifier.remove_flag ({STYLE_FLAGS}.flag_reverse)
				sub_modifier.add_flag ({STYLE_FLAGS}.flag_reverse)
			end
		end

	set_hidden (a_enabled: BOOLEAN)
			-- Set hidden text attribute.
		do
			flags.set_hidden (a_enabled)
			if a_enabled then
				add_modifier.add_flag ({STYLE_FLAGS}.flag_hidden)
				sub_modifier.remove_flag ({STYLE_FLAGS}.flag_hidden)
			else
				add_modifier.remove_flag ({STYLE_FLAGS}.flag_hidden)
				sub_modifier.add_flag ({STYLE_FLAGS}.flag_hidden)
			end
		end

	set_strikethrough (a_enabled: BOOLEAN)
			-- Set strikethrough attribute.
		do
			flags.set_strikethrough (a_enabled)
			if a_enabled then
				add_modifier.add_flag ({STYLE_FLAGS}.flag_strikethrough)
				sub_modifier.remove_flag ({STYLE_FLAGS}.flag_strikethrough)
			else
				add_modifier.remove_flag ({STYLE_FLAGS}.flag_strikethrough)
				sub_modifier.add_flag ({STYLE_FLAGS}.flag_strikethrough)
			end
		end

	remove_modifier (a_flag: NATURAL_16)
			-- Remove modifier flag `a_flag`.
		do
			flags.remove_flag (a_flag)
			add_modifier.remove_flag (a_flag)
			sub_modifier.add_flag (a_flag)
		ensure
			flag_removed: not flags.has_flag (a_flag)
		end

feature -- Fluent Builders

	with_fg (a_fg: COLOR): STYLE
			-- Synonym for `with_foreground`.
		do
			Result := with_foreground (a_fg)
		ensure
			fg_set: Result.foreground = a_fg
		end

	with_bg (a_bg: COLOR): STYLE
			-- Synonym for `with_background`.
		do
			Result := with_background (a_bg)
		ensure
			bg_set: Result.background = a_bg
		end

	with_reversed: STYLE
			-- Synonym for `with_reverse`.
		do
			Result := with_reverse
		ensure
			reverse_set: Result.flags.is_reverse
		end

	with_foreground (a_fg: COLOR): STYLE
			-- New style with foreground color `a_fg`
		do
			Result := twin
			Result.set_foreground (a_fg)
		ensure
			fg_set: Result.foreground = a_fg
		end

	with_background (a_bg: COLOR): STYLE
			-- New style with background color `a_bg`
		do
			Result := twin
			Result.set_background (a_bg)
		ensure
			bg_set: Result.background = a_bg
		end

	with_underline_color (a_color: COLOR): STYLE
			-- New style with underline color `a_color`
		do
			Result := twin
			Result.set_underline_color (a_color)
		ensure
			ul_set: Result.underline_color = a_color
		end

	with_bold: STYLE
			-- New style with bold enabled
		do
			Result := twin
			Result.set_bold (True)
		ensure
			bold_set: Result.flags.is_bold
		end

	with_dim: STYLE
			-- New style with dim enabled
		do
			Result := twin
			Result.set_dim (True)
		ensure
			dim_set: Result.flags.is_dim
		end

	with_italic: STYLE
			-- New style with italic enabled
		do
			Result := twin
			Result.set_italic (True)
		ensure
			italic_set: Result.flags.is_italic
		end

	with_underline: STYLE
			-- New style with underline enabled
		do
			Result := twin
			Result.set_underline (True)
		ensure
			underline_set: Result.flags.is_underline
		end

	with_blink: STYLE
			-- New style with blink enabled
		do
			Result := twin
			Result.set_blink (True)
		ensure
			blink_set: Result.flags.is_blink
		end

	with_reverse: STYLE
			-- New style with reverse enabled
		do
			Result := twin
			Result.set_reverse (True)
		ensure
			reverse_set: Result.flags.is_reverse
		end

	with_hidden: STYLE
			-- New style with hidden enabled
		do
			Result := twin
			Result.set_hidden (True)
		ensure
			hidden_set: Result.flags.is_hidden
		end

	with_strikethrough: STYLE
			-- New style with strikethrough enabled
		do
			Result := twin
			Result.set_strikethrough (True)
		ensure
			strikethrough_set: Result.flags.is_strikethrough
		end

	without_modifier (a_flag: NATURAL_16): STYLE
			-- New style with modifier `a_flag` removed
		do
			Result := twin
			Result.remove_modifier (a_flag)
		ensure
			modifier_removed: not Result.flags.has_flag (a_flag)
		end

feature -- Combination

	patch (a_overlay: STYLE): STYLE
			-- Return a new style applying attributes of `a_overlay` over `Current`.
		local
			l_res_flags: NATURAL_16
		do
			Result := twin

			-- A default overlay color leaves the base color; a reset color clears it.
			if a_overlay.foreground.is_reset then
				Result.set_foreground (Default_color)
			elseif not a_overlay.foreground.is_default then
				Result.set_foreground (a_overlay.foreground)
			end

			if a_overlay.background.is_reset then
				Result.set_background (Default_color)
			elseif not a_overlay.background.is_default then
				Result.set_background (a_overlay.background)
			end

			if a_overlay.underline_color.is_reset then
				Result.set_underline_color (Default_color)
			elseif not a_overlay.underline_color.is_default then
				Result.set_underline_color (a_overlay.underline_color)
			end

			l_res_flags := (flags.bits & (a_overlay.sub_modifier.bits.bit_not)) | a_overlay.add_modifier.bits | a_overlay.flags.bits
			Result.flags.set_bits (l_res_flags)

			Result.add_modifier.set_bits ((add_modifier.bits & (a_overlay.sub_modifier.bits.bit_not)) | a_overlay.add_modifier.bits)
			Result.sub_modifier.set_bits ((sub_modifier.bits & (a_overlay.add_modifier.bits.bit_not)) | a_overlay.sub_modifier.bits)
		ensure
			reset_foreground_cleared: a_overlay.foreground.is_reset implies Result.foreground.is_default
			reset_background_cleared: a_overlay.background.is_reset implies Result.background.is_default
		end

feature {NONE} -- Constants

	Default_color: COLOR
			-- Shared default color
		once
			create Result
		ensure
			instance_free: class
		end

feature -- ANSI SGR Sequence

	sgr_sequence: STRING_8
			-- Full ANSI escape sequence setting this style (`\e[...m`)
		local
			l_codes: STRING_8
		do
			create l_codes.make (32)
			-- Reset first
			l_codes.append ("0")

			if not foreground.is_default then
				l_codes.append_character (';')
				l_codes.append (foreground.sgr_fg)
			end

			if not background.is_default then
				l_codes.append_character (';')
				l_codes.append (background.sgr_bg)
			end

			if not underline_color.is_default then
				l_codes.append_character (';')
				l_codes.append (underline_color.sgr_ul)
			end

			if not flags.is_empty then
				l_codes.append_character (';')
				l_codes.append (flags.sgr_codes)
			end

			Result := "%/27/[" + l_codes + "m"
		ensure
			valid_sgr: Result.starts_with ("%/27/[") and Result.ends_with ("m")
		end

feature -- Comparison

	same_rendering (a_other: STYLE): BOOLEAN
			-- Would `Current` and `a_other` look the same on screen?
			-- Unlike `is_equal`, ignores the patch-only `add_modifier` / `sub_modifier` sets
			-- and treats default and reset colors alike.
		do
			Result := flags.bits = a_other.flags.bits and
				foreground.same_rendering (a_other.foreground) and
				background.same_rendering (a_other.background) and
				underline_color.same_rendering (a_other.underline_color)
		end

	renders_as_default: BOOLEAN
			-- Does `Current` look like the terminal's default attributes?
		do
			Result := flags.is_empty and foreground.renders_as_default and
				background.renders_as_default and underline_color.renders_as_default
		end

	is_equal (a_other: like Current): BOOLEAN
			-- Is `Current` equal to `a_other` in every attribute, including the patch modifiers?
		do
			Result := foreground.is_equal (a_other.foreground) and
				background.is_equal (a_other.background) and
				underline_color.is_equal (a_other.underline_color) and
				flags.is_equal (a_other.flags) and
				add_modifier.is_equal (a_other.add_modifier) and
				sub_modifier.is_equal (a_other.sub_modifier)
		end

	copy (a_other: like Current)
			-- Copy `a_other` into `Current`.
		do
			if a_other /= Current then
				standard_copy (a_other)
				foreground := a_other.foreground
				background := a_other.background
				underline_color := a_other.underline_color
				flags := a_other.flags.twin
				add_modifier := a_other.add_modifier.twin
				sub_modifier := a_other.sub_modifier.twin
			end
		end

end
