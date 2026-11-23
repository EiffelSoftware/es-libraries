note
	description: "[
		A STYLE as text (review/p2_terminal_widgets_plan.md, C2): reads and prints the style
		part of a theme section in the theme file format (Q1, TOML_SUBSET_READER), as
		Ratatui reads and writes a `Style` with `serde`.

		The keys, each optional, in the order they are printed:
		* `fg`, `bg`, `underline_color`: a string, a color as `{COLOR}.make_from_string`
		  reads it (C1): a name such as "red" or "LightRed", an index "0" .. "255",
		  "#rrggbb", "reset", or "default". "default" is the unset color (Ratatui's `None`),
		  so it is never printed. Printed as `{COLOR}.as_string` ("LightRed", "#88C0D0").
		* `modifiers`: an array of modifier names, the modifiers the style adds (Ratatui
		  `add_modifier`; `STYLE.add_modifier`).
		* `remove_modifiers`: an array of modifier names, the modifiers the style removes
		  when it is patched over another (Ratatui `sub_modifier`; `STYLE.sub_modifier`).
		Example: `fg = "#88c0d0"`, `bg = "reset"`, `modifiers = ["bold", "italic"]`.

		Ratatui's own serde keys are read too, so a style Ratatui wrote with serde and
		`toml` loads (they are never printed):
		* `add_modifier`, `sub_modifier`: a string in the `bitflags` text form Ratatui
		  writes, the names joined with "|": "BOLD | ITALIC", "UNDERLINED", or "" for none.
		  Spaces around each name are ignored; an empty name ("BOLD |") is an error.
		  Hexadecimal bits ("0x1") are refused: Ratatui's bit values are not EiffelTUI's.
		* `add_modifier` and `modifiers` say the same, so a style that has both is an
		  error; so is one with both `sub_modifier` and `remove_modifiers`.

		Modifier names are Ratatui's `Modifier` flags in lower case: bold, dim, italic,
		underlined, slow_blink, rapid_blink, reversed, hidden, crossed_out. They are read
		as color names are: any case, with spaces, "-" and "_" ignored ("Slow-Blink",
		"SLOW_BLINK" and "slowblink" are the same). A name may repeat in a list.
		"slow_blink" is `{STYLE_FLAGS}.Flag_blink` (SGR 5) and "rapid_blink"
		`Flag_rapid_blink` (SGR 6), as in Ratatui.
		Deviations from Ratatui:
		* A modifier in both lists is an error. Ratatui's serde would keep both sets, and
		  then the removal wins when rendering; a STYLE built with the builders never has
		  one modifier in both.
		* Names in `add_modifier` and `sub_modifier` are read in any case, as above;
		  Ratatui's `bitflags` wants them exactly in upper case.
		Every other key is an error, as is a value of the wrong type (a color must be a
		string, a modifier list an array), a bad color and an unknown modifier name.

		Errors are queries (`has_error`, `error_line`, `error_column`, `error_key`,
		`error_message`), never exceptions; the first error stops the read, and a failed
		read gives no style. `error_line` is known when the section came from
		TOML_SUBSET_READER (`{TOML_SUBSET_SECTION}.key_line`), and `error_column` only for
		an error of the format itself in `read`.

		Printing (`put_style`, `text`) is deterministic: the keys in the order above, unset
		colors and empty modifier lists left out, modifiers in the order of the names above.
		It reads back to an equal STYLE (`is_equal`, the patch sets included).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	STYLE_TEXT

create
	make

feature {NONE} -- Initialization

	make
			-- A reader that has read nothing yet.
		do
			create error_key.make_empty
			create error_message.make_empty
		ensure
			no_style: style = Void
			no_error: not has_error
		end

feature -- Reading

	read_section (a_section: TOML_SUBSET_SECTION)
			-- Read the keys of `a_section` as a style: make `style`, or set the error of the
			-- first key that is not a style key with a valid value, and leave `style` Void.
		local
			i: INTEGER
			l_style: STYLE
			l_add, l_sub: NATURAL_16
			l_add_index, l_sub_index: INTEGER
		do
			clear
			create l_style
			from
				i := 1
			until
				has_error or i > a_section.count
			loop
				if a_section.key (i).same_string (Fg_key) then
					if attached color_of (a_section, i) as l_color then
						l_style := l_style.with_foreground (l_color)
					end
				elseif a_section.key (i).same_string (Bg_key) then
					if attached color_of (a_section, i) as l_color then
						l_style := l_style.with_background (l_color)
					end
				elseif a_section.key (i).same_string (Underline_color_key) then
					if attached color_of (a_section, i) as l_color then
						l_style := l_style.with_underline_color (l_color)
					end
				elseif a_section.key (i).same_string (Modifiers_key) or a_section.key (i).same_string (Add_modifier_key) then
					if l_add_index > 0 then
						set_key_error (a_section, i, both_keys_message (a_section.key (l_add_index), a_section.key (i), "added"))
					else
						l_add := modifiers_of (a_section, i)
						l_add_index := i
					end
				elseif a_section.key (i).same_string (Remove_modifiers_key) or a_section.key (i).same_string (Sub_modifier_key) then
					if l_sub_index > 0 then
						set_key_error (a_section, i, both_keys_message (a_section.key (l_sub_index), a_section.key (i), "removed"))
					else
						l_sub := modifiers_of (a_section, i)
						l_sub_index := i
					end
				else
					set_key_error (a_section, i, {STRING_32} "unknown field '" + a_section.key (i) + "' (a style has fg, bg, underline_color, modifiers and remove_modifiers, or Ratatui's add_modifier and sub_modifier)")
				end
				i := i + 1
			end
			if not has_error and (l_add & l_sub) /= 0 then
				set_key_error (a_section, l_sub_index, {STRING_32} "modifier '" + modifier_text (l_add & l_sub) + "' is in both " + a_section.key (l_add_index) + " and " + a_section.key (l_sub_index))
			end
			if not has_error then
				l_style := with_modifiers (l_style, l_add, l_sub)
				style := l_style
			end
		ensure
			style_or_error: has_error = (style = Void)
		end

	read (a_text: READABLE_STRING_GENERAL)
			-- Read `a_text`, the key lines of one theme section without its `[name]` header
			-- (for example "fg = %"red%"%Nmodifiers = [%"bold%"]"), in the theme file format,
			-- through TOML_SUBSET_READER; lines count from 1 in `a_text`. A `[name]` header in
			-- `a_text` (a line whose first character after spaces and tabs is "[") is an error
			-- at its "[", whatever the name, unless a line before it has an error.
		local
			l_reader: TOML_SUBSET_READER
			l_text: STRING_32
			l_header_line, l_header_column, l_before_header: INTEGER
			i, l_line, l_column: INTEGER
			l_at_start: BOOLEAN
		do
			clear
				-- Find the first header line; only the lines before it are read
			from
				i := 1
				l_line := 1
				l_column := 1
				l_at_start := True
			until
				l_header_line > 0 or i > a_text.count
			loop
				inspect a_text.code (i)
				when 0x0A then
					l_line := l_line + 1
					l_column := 0
					l_at_start := True
				when 0x20, 0x09 then
				when 0x5B then
					if l_at_start then
						l_header_line := l_line
						l_header_column := l_column
						l_before_header := i - l_column
					end
					l_at_start := False
				else
					l_at_start := False
				end
				i := i + 1
				l_column := l_column + 1
			end
			create l_text.make (a_text.count + Wrapper_header.count)
			l_text.append (Wrapper_header)
			if l_header_line > 0 then
				l_text.append_string_general (a_text.substring (1, l_before_header))
			else
				l_text.append_string_general (a_text)
			end
			create l_reader.make
			l_reader.read (l_text)
			if attached l_reader.document as l_document then
				if l_header_line > 0 then
					set_error (l_header_line, l_header_column, "", "a style text has no [name] section headers")
				else
					read_section (l_document.section (1))
					if has_error and error_line > 0 then
						error_line := error_line - 1
					end
				end
			else
				set_error (l_reader.error_line - 1, l_reader.error_column, "", l_reader.error_message)
			end
		ensure
			style_or_error: has_error = (style = Void)
		end

	parsed_section (a_section: TOML_SUBSET_SECTION): detachable STYLE
			-- `read_section (a_section)`, then `style`
		do
			read_section (a_section)
			Result := style
		ensure
			style_or_error: has_error = (Result = Void)
			is_style: Result = style
		end

	parsed (a_text: READABLE_STRING_GENERAL): detachable STYLE
			-- `read (a_text)`, then `style`
		do
			read (a_text)
			Result := style
		ensure
			style_or_error: has_error = (Result = Void)
			is_style: Result = style
		end

feature -- Access

	style: detachable STYLE
			-- The style the last read made, or Void after an error or before any read

	error_line: INTEGER
			-- Line of the error (from 1), or 0 when it is not known (a section made in code)

	error_column: INTEGER
			-- Column of the error (from 1), or 0: known only for an error of the format in `read`

	error_key: STRING_32
			-- The key the error is about, or empty (no error, or an error of the format)

	error_message: STRING_32
			-- What the error is (empty when there is none)

	error_description: STRING_32
			-- "line N, column M, key 'k': message", each part only when known; empty when
			-- there is no error
		do
			create Result.make_empty
			if has_error then
				if error_line > 0 then
					Result.append ({STRING_32} "line ")
					Result.append_integer (error_line)
				end
				if error_column > 0 then
					Result.append ({STRING_32} ", column ")
					Result.append_integer (error_column)
				end
				if not error_key.is_empty then
					if not Result.is_empty then
						Result.append ({STRING_32} ", ")
					end
					Result.append ({STRING_32} "key '")
					Result.append (error_key)
					Result.append_character ('%'')
				end
				if not Result.is_empty then
					Result.append ({STRING_32} ": ")
				end
				Result.append (error_message)
			end
		end

feature -- Status report

	has_error: BOOLEAN
			-- Did the last read find something that is not a style?

	is_representable (a_style: STYLE): BOOLEAN
			-- Can `a_style` be printed so that it reads back equal? Its active flags are its
			-- added modifiers, and no modifier is both added and removed. Every STYLE built
			-- with the creation procedures, the `with_*` / `without_modifier` builders and
			-- `patch` is.
		do
			Result := a_style.flags.bits = a_style.add_modifier.bits and
				(a_style.add_modifier.bits & a_style.sub_modifier.bits) = 0
		ensure
			instance_free: class
		end

	is_modifier_name (a_text: READABLE_STRING_GENERAL): BOOLEAN
			-- Is `a_text` a modifier name (any case; spaces, "-" and "_" ignored)?
		do
			Result := modifier_flag (a_text) /= 0
		ensure
			instance_free: class
		end

feature -- Printing

	put_style (a_style: STYLE; a_section: TOML_SUBSET_SECTION)
			-- Add the keys of `a_style` to `a_section`, in the fixed order, leaving out unset
			-- colors and empty modifier lists.
		require
			representable: is_representable (a_style)
			no_style_keys: across Keys as l_key all not a_section.has_key (l_key) end
			no_serde_keys: not a_section.has_key (Add_modifier_key) and not a_section.has_key (Sub_modifier_key)
		do
			put_color (a_section, Fg_key, a_style.foreground)
			put_color (a_section, Bg_key, a_style.background)
			put_color (a_section, Underline_color_key, a_style.underline_color)
			put_modifiers (a_section, Modifiers_key, a_style.add_modifier.bits)
			put_modifiers (a_section, Remove_modifiers_key, a_style.sub_modifier.bits)
		ensure
			instance_free: class
			reads_back: old a_section.count = 0 implies
				(attached (create {STYLE_TEXT}.make).parsed_section (a_section) as l_style and then l_style.is_equal (a_style))
		end

	text (a_style: STYLE): STRING_32
			-- `a_style` as the key lines of a theme section, without a header: one
			-- `key = value` line per set key, LF line ends; the empty text for an empty style
		require
			representable: is_representable (a_style)
		local
			l_section: TOML_SUBSET_SECTION
			i: INTEGER
		do
			create l_section.make (Wrapper_name)
			put_style (a_style, l_section)
			create Result.make (64)
			from
				i := 1
			until
				i > l_section.count
			loop
				Result.append (l_section.key (i))
				Result.append ({STRING_32} " = ")
				Result.append ({TOML_SUBSET_WRITER}.value_text (l_section.value (i)))
				Result.append_character ('%N')
				i := i + 1
			end
		ensure
			instance_free: class
			reads_back: attached (create {STYLE_TEXT}.make).parsed (Result) as l_style and then l_style.is_equal (a_style)
		end

feature -- Constants

	Fg_key: STRING_32 = "fg"
	Bg_key: STRING_32 = "bg"
	Underline_color_key: STRING_32 = "underline_color"
	Modifiers_key: STRING_32 = "modifiers"
	Remove_modifiers_key: STRING_32 = "remove_modifiers"
			-- The keys of a style, in the order they are printed

	Add_modifier_key: STRING_32 = "add_modifier"
	Sub_modifier_key: STRING_32 = "sub_modifier"
			-- Ratatui's serde keys for the modifiers, read and never printed

	Keys: ARRAY [STRING_32]
			-- The five keys, in order
		once
			Result := <<Fg_key, Bg_key, Underline_color_key, Modifiers_key, Remove_modifiers_key>>
		ensure
			instance_free: class
		end

	Modifier_names: ARRAY [STRING_32]
			-- Ratatui's nine modifier names, in the order printed
		once
			Result := <<"bold", "dim", "italic", "underlined", "slow_blink", "rapid_blink", "reversed", "hidden", "crossed_out">>
		ensure
			instance_free: class
		end

	Modifier_flags: ARRAY [NATURAL_16]
			-- The STYLE_FLAGS flag of each of `Modifier_names`
		once
			Result := <<{STYLE_FLAGS}.Flag_bold, {STYLE_FLAGS}.Flag_dim, {STYLE_FLAGS}.Flag_italic,
				{STYLE_FLAGS}.Flag_underline, {STYLE_FLAGS}.Flag_blink, {STYLE_FLAGS}.Flag_rapid_blink,
				{STYLE_FLAGS}.Flag_reverse, {STYLE_FLAGS}.Flag_hidden, {STYLE_FLAGS}.Flag_strikethrough>>
		ensure
			instance_free: class
		end

feature {NONE} -- Reading

	clear
			-- Forget the last read.
		do
			style := Void
			has_error := False
			error_line := 0
			error_column := 0
			create error_key.make_empty
			create error_message.make_empty
		ensure
			no_style: style = Void
			no_error: not has_error
		end

	color_of (a_section: TOML_SUBSET_SECTION; i: INTEGER): detachable COLOR
			-- The color of the `i`-th key of `a_section`, or Void after setting the error.
		require
			valid_index: 1 <= i and i <= a_section.count
		local
			l_text: STRING_32
		do
			if a_section.value (i).is_array then
				set_key_error (a_section, i, {STRING_32} "'" + a_section.key (i) + "' must be a string (a color), not an array")
			else
				l_text := a_section.value (i).string_value
				if {COLOR}.is_valid_color_string (l_text) then
					create Result.make_from_string (l_text)
				else
					set_key_error (a_section, i, {STRING_32} "%"" + l_text + "%" is not a color (a name such as %"red%", an index 0 .. 255, %"#rrggbb%", %"reset%" or %"default%")")
				end
			end
		ensure
			color_or_error: has_error = (Result = Void)
		end

	modifiers_of (a_section: TOML_SUBSET_SECTION; i: INTEGER): NATURAL_16
			-- The flags named by the `i`-th key of `a_section` (an array of modifier names, or
			-- for Ratatui's serde keys a "BOLD | ITALIC" string), or 0 after setting the error.
		require
			valid_index: 1 <= i and i <= a_section.count
		local
			l_value: TOML_SUBSET_VALUE
			j: INTEGER
			l_flag: NATURAL_16
		do
			l_value := a_section.value (i)
			if a_section.key (i).same_string (Add_modifier_key) or a_section.key (i).same_string (Sub_modifier_key) then
				Result := flags_text_of (a_section, i)
			elseif l_value.is_string then
				set_key_error (a_section, i, {STRING_32} "'" + a_section.key (i) + "' must be an array of modifier names, such as [%"bold%"], not a string")
			else
				from
					j := 1
				until
					has_error or j > l_value.count
				loop
					l_flag := modifier_flag (l_value [j])
					if l_flag = 0 then
						set_key_error (a_section, i, {STRING_32} "unknown modifier %"" + l_value [j] + "%" (one of bold, dim, italic, underlined, slow_blink, rapid_blink, reversed, hidden, crossed_out)")
					else
						Result := Result | l_flag
					end
					j := j + 1
				end
				if has_error then
					Result := 0
				end
			end
		end

	flags_text_of (a_section: TOML_SUBSET_SECTION; i: INTEGER): NATURAL_16
			-- The flags named by the `i`-th key of `a_section`, a string in Ratatui's
			-- `bitflags` text form ("BOLD | ITALIC", "" for none), or 0 after setting the error.
		require
			valid_index: 1 <= i and i <= a_section.count
		local
			l_text, l_name: STRING_32
			l_flag: NATURAL_16
		do
			if a_section.value (i).is_array then
				set_key_error (a_section, i, {STRING_32} "'" + a_section.key (i) + "' must be a string of modifier names joined with %"|%", such as %"BOLD | ITALIC%" (Ratatui's form), not an array")
			else
				l_text := a_section.value (i).string_value
				l_text.adjust
				if not l_text.is_empty then
					across l_text.split ('|') as l_part until has_error loop
						l_name := l_part.twin
						l_name.adjust
						if l_name.is_empty then
							set_key_error (a_section, i, {STRING_32} "empty modifier name in %"" + a_section.value (i).string_value + "%"")
						elseif l_name.as_lower.starts_with ({STRING_32} "0x") then
							set_key_error (a_section, i, {STRING_32} "hexadecimal modifier bits %"" + l_name + "%" are not supported (use the names, such as %"BOLD | ITALIC%")")
						else
							l_flag := modifier_flag (l_name)
							if l_flag = 0 then
								set_key_error (a_section, i, {STRING_32} "unknown modifier %"" + l_name + "%" (one of BOLD, DIM, ITALIC, UNDERLINED, SLOW_BLINK, RAPID_BLINK, REVERSED, HIDDEN, CROSSED_OUT)")
							else
								Result := Result | l_flag
							end
						end
					end
				end
				if has_error then
					Result := 0
				end
			end
		end

	both_keys_message (a_first, a_second, a_what: READABLE_STRING_GENERAL): STRING_32
			-- "'a_first' and 'a_second' both give the a_what modifiers: use one of them"
		do
			Result := {STRING_32} "'" + a_first.as_string_32 + "' and '" + a_second.as_string_32 + "' both give the " + a_what.as_string_32 + " modifiers: use one of them"
		ensure
			instance_free: class
		end

	set_key_error (a_section: TOML_SUBSET_SECTION; i: INTEGER; a_message: READABLE_STRING_GENERAL)
			-- Set the error `a_message` about the `i`-th key of `a_section`.
		require
			valid_index: 1 <= i and i <= a_section.count
			no_error: not has_error
			has_message: not a_message.is_empty
		do
			set_error (a_section.key_line (i), 0, a_section.key (i), a_message)
		ensure
			has_error: has_error
		end

	set_error (a_line, a_column: INTEGER; a_key, a_message: READABLE_STRING_GENERAL)
			-- Set the error `a_message` at `a_line`, `a_column`, about `a_key`.
		require
			no_error: not has_error
			has_message: not a_message.is_empty
		do
			has_error := True
			style := Void
			error_line := a_line.max (0)
			error_column := a_column.max (0)
			create error_key.make_from_string_general (a_key)
			create error_message.make_from_string_general (a_message)
		ensure
			has_error: has_error
		end

	with_modifiers (a_style: STYLE; a_add, a_sub: NATURAL_16): STYLE
			-- `a_style` with the flags `a_add` added and `a_sub` removed, as Ratatui's
			-- `add_modifier` and `remove_modifier`
		require
			disjoint: (a_add & a_sub) = 0
		local
			i: INTEGER
			l_flag: NATURAL_16
		do
			Result := a_style
			from
				i := 0
			until
				i > 15
			loop
				l_flag := ({NATURAL_16} 1) |<< i
				if (a_add & l_flag) /= 0 then
					Result := with_flag (Result, l_flag)
				elseif (a_sub & l_flag) /= 0 then
					Result := Result.without_modifier (l_flag)
				end
				i := i + 1
			end
		ensure
			added: Result.add_modifier.bits = a_style.add_modifier.bits | a_add
			removed: (Result.sub_modifier.bits & a_sub) = a_sub
		end

	with_flag (a_style: STYLE; a_flag: NATURAL_16): STYLE
			-- `a_style` with the modifier `a_flag` added (through its `with_*` builder)
		do
			if a_flag = {STYLE_FLAGS}.Flag_bold then
				Result := a_style.with_bold
			elseif a_flag = {STYLE_FLAGS}.Flag_dim then
				Result := a_style.with_dim
			elseif a_flag = {STYLE_FLAGS}.Flag_italic then
				Result := a_style.with_italic
			elseif a_flag = {STYLE_FLAGS}.Flag_underline then
				Result := a_style.with_underline
			elseif a_flag = {STYLE_FLAGS}.Flag_blink then
				Result := a_style.with_blink
			elseif a_flag = {STYLE_FLAGS}.Flag_rapid_blink then
				Result := a_style.with_rapid_blink
			elseif a_flag = {STYLE_FLAGS}.Flag_reverse then
				Result := a_style.with_reverse
			elseif a_flag = {STYLE_FLAGS}.Flag_hidden then
				Result := a_style.with_hidden
			elseif a_flag = {STYLE_FLAGS}.Flag_strikethrough then
				Result := a_style.with_strikethrough
			else
				Result := a_style
			end
		end

	modifier_flag (a_text: READABLE_STRING_GENERAL): NATURAL_16
			-- The flag `a_text` names, or 0 when it names none
		local
			l_name: STRING_32
			i: INTEGER
		do
			l_name := normalized (a_text)
			from
				i := 1
			until
				Result /= 0 or i > Modifier_names.count
			loop
				if l_name.same_string (normalized (Modifier_names [i])) then
					Result := Modifier_flags [i]
				end
				i := i + 1
			end
		ensure
			instance_free: class
		end

	normalized (a_text: READABLE_STRING_GENERAL): STRING_32
			-- `a_text` in lower case without spaces, "-" and "_", as COLOR reads names
		local
			i: INTEGER
		do
			create Result.make (a_text.count)
			from
				i := 1
			until
				i > a_text.count
			loop
				inspect a_text.code (i)
				when 0x20, 0x2D, 0x5F then
						-- space, "-", "_": ignored
				else
					Result.append_code (a_text.code (i))
				end
				i := i + 1
			end
			Result.to_lower
		ensure
			instance_free: class
		end

	modifier_text (a_flags: NATURAL_16): STRING_32
			-- The printed name of the first flag in `a_flags`
		local
			i: INTEGER
		do
			create Result.make_empty
			from
				i := 1
			until
				not Result.is_empty or i > Modifier_names.count
			loop
				if (a_flags & Modifier_flags [i]) /= 0 then
					Result := Modifier_names [i].twin
				end
				i := i + 1
			end
		ensure
			instance_free: class
		end

feature {NONE} -- Printing

	put_color (a_section: TOML_SUBSET_SECTION; a_key: STRING_32; a_color: COLOR)
			-- Add `a_key` = `a_color` to `a_section`, unless `a_color` is the default (unset).
		require
			new_key: not a_section.has_key (a_key)
		do
			if not a_color.is_default then
				a_section.put_string (a_key, a_color.as_string)
			end
		ensure
			instance_free: class
		end

	put_modifiers (a_section: TOML_SUBSET_SECTION; a_key: STRING_32; a_flags: NATURAL_16)
			-- Add `a_key` = the names of `a_flags` to `a_section`, unless `a_flags` is empty.
		require
			new_key: not a_section.has_key (a_key)
		local
			l_names: ARRAYED_LIST [STRING_32]
			i: INTEGER
		do
			if a_flags /= 0 then
				create l_names.make (4)
				from
					i := 1
				until
					i > Modifier_names.count
				loop
					if (a_flags & Modifier_flags [i]) /= 0 then
						l_names.extend (Modifier_names [i])
					end
					i := i + 1
				end
				a_section.put_array (a_key, l_names)
			end
		ensure
			instance_free: class
		end

	Wrapper_name: STRING_32 = "style"
			-- Section name `read` and `text` use around the key lines

	Wrapper_header: STRING_32 = "[style]%N"
			-- Header `read` puts before the text (one line, taken off the line numbers)

invariant
	error_has_message: has_error implies not error_message.is_empty
	error_gives_no_style: has_error implies style = Void
	no_error_no_message: not has_error implies (error_message.is_empty and error_key.is_empty and error_line = 0 and error_column = 0)

end
