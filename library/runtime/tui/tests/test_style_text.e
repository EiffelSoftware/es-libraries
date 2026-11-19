note
	description: "[
		P2 item C2: STYLE as text (review/p2_terminal_widgets_plan.md), read and printed by
		STYLE_TEXT in the theme file format (Q1). Ratatui reads a `Style` with serde
		(`fg`, `bg`, `underline_color`, `add_modifier`, `sub_modifier`); here the keys are
		`fg`, `bg`, `underline_color`, `modifiers` and `remove_modifiers`, and Ratatui's
		`add_modifier` and `sub_modifier` ("BOLD | ITALIC") are read too.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_STYLE_TEXT

inherit
	EQA_TEST_SET

feature -- Reading

	test_reads_theme_style
			-- The Q1 example section: an RGB foreground, a reset background, two modifiers.
		local
			l_style: STYLE
		do
			l_style := read_ok ("example", "fg = %"#88c0d0%"%Nbg = %"reset%"%Nmodifiers = [%"bold%", %"italic%"]%N")
			assert ("fg", l_style.foreground.is_equal ({COLOR}.rgb (0x88, 0xC0, 0xD0)))
			assert ("bg", l_style.background.is_reset)
			assert ("no underline color", l_style.underline_color.is_default)
			assert ("bold and italic", l_style.is_bold and l_style.is_italic and not l_style.is_dim)
			assert ("added", l_style.add_modifier.bits = ({STYLE_FLAGS}.Flag_bold | {STYLE_FLAGS}.Flag_italic))
			assert ("nothing removed", l_style.sub_modifier.is_empty)
			assert ("as built", l_style.is_equal ((create {STYLE}.make_with_colors ({COLOR}.rgb (0x88, 0xC0, 0xD0), create {COLOR}.make_reset)).with_bold.with_italic))
		end

	test_reads_section_from_document
			-- The path C3 takes: a section of a document read by TOML_SUBSET_READER.
		local
			l_reader: STYLE_TEXT
		do
			if attached (create {TOML_SUBSET_READER}.make).parsed ("[base]%Nfg = %"white%"%N%N[primary]%Nunderline_color = %"10%"%Nremove_modifiers = [%"dim%"]%N") as l_document and then attached l_document ["primary"] as l_section then
				create l_reader.make
				l_reader.read_section (l_section)
				assert ("read", not l_reader.has_error)
				if attached l_reader.style as l_style then
					assert ("underline color", l_style.underline_color.is_equal (create {COLOR}.make_indexed (10)))
					assert ("dim removed", l_style.sub_modifier.bits = {STYLE_FLAGS}.Flag_dim and l_style.add_modifier.is_empty)
				else
					assert ("style", False)
				end
			else
				assert ("document", False)
			end
		end

	test_modifier_names
			-- Ratatui's nine names, any case, spaces, "-" and "_" ignored; "slow_blink" and
			-- "rapid_blink" are two flags; a repeated name is allowed.
		local
			l_style: STYLE
		do
			l_style := read_ok ("all nine", "modifiers = [%"bold%", %"dim%", %"italic%", %"underlined%", %"slow_blink%", %"rapid_blink%", %"reversed%", %"hidden%", %"crossed_out%"]")
			assert ("all nine flags", l_style.flags.bits = 0x1FF and l_style.add_modifier.bits = 0x1FF)
			assert ("case and separators", read_ok ("case", "modifiers = [%"BOLD%", %"Crossed-Out%", %"slow blink%", %"crossedout%", %"Under_Lined%"]").add_modifier.bits =
				({STYLE_FLAGS}.Flag_bold | {STYLE_FLAGS}.Flag_strikethrough | {STYLE_FLAGS}.Flag_blink | {STYLE_FLAGS}.Flag_underline))
			assert ("rapid is its own flag", read_ok ("rapid", "modifiers = [%"rapid_blink%"]").add_modifier.bits = {STYLE_FLAGS}.Flag_rapid_blink)
			assert ("slow is blink", read_ok ("slow", "modifiers = [%"slow_blink%"]").add_modifier.bits = {STYLE_FLAGS}.Flag_blink)
			assert_same_text ("rapid prints rapid", {STYLE_TEXT}.text (read_ok ("rapid2", "modifiers = [%"rapid_blink%"]")), "modifiers = [%"rapid_blink%"]%N")
			assert_same_text ("both blinks", {STYLE_TEXT}.text ((create {STYLE}).with_rapid_blink.with_blink), "modifiers = [%"slow_blink%", %"rapid_blink%"]%N")
			assert ("repeated", read_ok ("repeat", "modifiers = [%"bold%", %"bold%"]").add_modifier.bits = {STYLE_FLAGS}.Flag_bold)
			assert ("empty lists", read_ok ("empty", "modifiers = []%Nremove_modifiers = []").is_equal (create {STYLE}))
			assert ("name", {STYLE_TEXT}.is_modifier_name ("Rapid-Blink"))
			assert ("eiffel name is not one", not {STYLE_TEXT}.is_modifier_name ("strikethrough"))
			assert ("empty is not one", not {STYLE_TEXT}.is_modifier_name (""))
		end

	test_remove_modifiers_patch
			-- `remove_modifiers` is Ratatui's `sub_modifier`: patched over a bold style, it
			-- takes the bold off; `modifiers` adds.
		local
			l_base, l_overlay, l_result: STYLE
		do
			l_base := (create {STYLE}).with_bold.with_italic
			l_overlay := read_ok ("overlay", "modifiers = [%"underlined%"]%Nremove_modifiers = [%"bold%"]")
			l_result := l_base.patch (l_overlay)
			assert ("bold removed", not l_result.is_bold)
			assert ("italic kept", l_result.is_italic)
			assert ("underlined added", l_result.is_underlined)
			assert ("same as builders", l_overlay.is_equal ((create {STYLE}).with_underline.without_modifier ({STYLE_FLAGS}.Flag_bold)))
		end

feature -- Printing and round trip

	test_printed_text
			-- Every key, in the fixed order, whatever the order read; unset keys left out.
		local
			l_style: STYLE
		do
			l_style := read_ok ("all keys", "remove_modifiers = [%"hidden%", %"dim%"]%Nmodifiers = [%"reversed%", %"bold%"]%Nunderline_color = %"#ff0000%"%Nbg = %"light blue%"%Nfg = %"200%"%N")
			assert_same_text ("order", {STYLE_TEXT}.text (l_style),
				"fg = %"200%"%Nbg = %"LightBlue%"%Nunderline_color = %"#FF0000%"%Nmodifiers = [%"bold%", %"reversed%"]%Nremove_modifiers = [%"dim%", %"hidden%"]%N")
			assert_same_text ("only bg", {STYLE_TEXT}.text ((create {STYLE}).with_bg ({COLOR}.Red)), "bg = %"Red%"%N")
			assert_same_text ("only removed", {STYLE_TEXT}.text ((create {STYLE}).without_modifier ({STYLE_FLAGS}.Flag_italic)), "remove_modifiers = [%"italic%"]%N")
		end

	test_round_trip_every_flag
			-- Each flag, added and removed, prints by its name and reads back equal.
		local
			i: INTEGER
			l_flag: NATURAL_16
			l_added, l_removed: STYLE
			l_name: STRING_8
		do
			from
				i := 0
			until
				i > 8
			loop
				l_flag := ({NATURAL_16} 1) |<< i
				l_name := flag_name (l_flag)
				l_added := added (l_flag)
				l_removed := (create {STYLE}).without_modifier (l_flag)
				assert_same_text ("added " + l_name, {STYLE_TEXT}.text (l_added), {STRING_32} "modifiers = [%"" + l_name + "%"]%N")
				assert_same_text ("removed " + l_name, {STYLE_TEXT}.text (l_removed), {STRING_32} "remove_modifiers = [%"" + l_name + "%"]%N")
				assert_round_trip ("added " + l_name, l_added)
				assert_round_trip ("removed " + l_name, l_removed)
				i := i + 1
			end
			assert_round_trip ("all added", (create {STYLE}).with_bold.with_dim.with_italic.with_underline.with_blink.with_rapid_blink.with_reverse.with_hidden.with_strikethrough)
			assert_round_trip ("mixed", (create {STYLE}).with_bold.with_hidden.without_modifier ({STYLE_FLAGS}.Flag_dim).without_modifier ({STYLE_FLAGS}.Flag_blink))
			assert_round_trip ("patched", (create {STYLE}).with_bold.with_italic.patch ((create {STYLE}).with_dim.without_modifier ({STYLE_FLAGS}.Flag_bold)))
		end

	test_round_trip_every_color_kind
			-- ANSI (all 16), indexed (0, 255), RGB, reset and default, as fg, bg and
			-- underline color; the default is unset, so it is not printed.
		local
			i: INTEGER
			l_colors: ARRAYED_LIST [COLOR]
		do
			create l_colors.make (24)
			from
				i := 0
			until
				i > 15
			loop
				l_colors.extend (create {COLOR}.make_ansi (i.to_natural_8))
				i := i + 1
			end
			l_colors.extend (create {COLOR}.make_indexed (0))
			l_colors.extend (create {COLOR}.make_indexed (255))
			l_colors.extend ({COLOR}.rgb (0x88, 0xC0, 0xD0))
			l_colors.extend ({COLOR}.rgb (0, 0, 0))
			l_colors.extend (create {COLOR}.make_reset)
			l_colors.extend (create {COLOR})
			across l_colors as l_color loop
				assert_round_trip ("fg " + l_color.out, (create {STYLE}).with_fg (l_color))
				assert_round_trip ("bg " + l_color.out, (create {STYLE}).with_bg (l_color))
				assert_round_trip ("ul " + l_color.out, (create {STYLE}).with_underline_color (l_color))
				assert_round_trip ("all " + l_color.out, (create {STYLE}).with_fg (l_color).with_bg (l_color).with_underline_color (l_color).with_bold)
			end
			assert_same_text ("reset printed", {STYLE_TEXT}.text ((create {STYLE}).with_fg (create {COLOR}.make_reset)), "fg = %"Reset%"%N")
			assert_same_text ("indexed printed", {STYLE_TEXT}.text ((create {STYLE}).with_fg (create {COLOR}.make_indexed (255))), "fg = %"255%"%N")
			assert_same_text ("default not printed", {STYLE_TEXT}.text ((create {STYLE}).with_fg (create {COLOR})), "")
			assert ("default read as unset", read_ok ("default", "fg = %"default%"%Nbg = %"Default%"").is_equal (create {STYLE}))
		end

	test_empty_style
			-- An empty style prints as nothing, and nothing reads as an empty style.
		local
			l_section: TOML_SUBSET_SECTION
		do
			assert_same_text ("empty text", {STYLE_TEXT}.text (create {STYLE}), "")
			assert ("empty reads", read_ok ("empty", "").is_equal (create {STYLE}))
			assert ("comments read", read_ok ("comments", "# nothing set%N%N").is_equal (create {STYLE}))
			create l_section.make ("base")
			{STYLE_TEXT}.put_style (create {STYLE}, l_section)
			assert ("no keys", l_section.count = 0)
			assert ("empty section reads", attached (create {STYLE_TEXT}.make).parsed_section (l_section) as l_style and then l_style.is_equal (create {STYLE}))
		end

	test_section_round_trip_through_file_format
			-- `put_style` into a document, the Q1 writer, the Q1 reader, `read_section`:
			-- equal styles (the path C3's save and load take).
		local
			l_document: TOML_SUBSET_DOCUMENT
			l_primary, l_muted: STYLE
		do
			l_primary := (create {STYLE}.make_with_colors ({COLOR}.rgb (0x88, 0xC0, 0xD0), create {COLOR}.make_reset)).with_bold.with_italic
			l_muted := (create {STYLE}.make_fg ({COLOR}.Dark_gray)).without_modifier ({STYLE_FLAGS}.Flag_bold)
			create l_document
			{STYLE_TEXT}.put_style (l_primary, l_document.put_new ("primary"))
			{STYLE_TEXT}.put_style (l_muted, l_document.put_new ("muted"))
			assert_same_text ("file", {TOML_SUBSET_WRITER}.text (l_document),
				"[primary]%Nfg = %"#88C0D0%"%Nbg = %"Reset%"%Nmodifiers = [%"bold%", %"italic%"]%N%N[muted]%Nfg = %"DarkGray%"%Nremove_modifiers = [%"bold%"]%N")
			if attached (create {TOML_SUBSET_READER}.make).parsed ({TOML_SUBSET_WRITER}.text (l_document)) as l_read then
				assert ("primary", attached l_read ["primary"] as l_section and then
					(attached (create {STYLE_TEXT}.make).parsed_section (l_section) as l_style and then l_style.is_equal (l_primary)))
				assert ("muted", attached l_read ["muted"] as l_section and then
					(attached (create {STYLE_TEXT}.make).parsed_section (l_section) as l_style and then l_style.is_equal (l_muted)))
			else
				assert ("reads", False)
			end
		end

feature -- Errors

	test_unknown_field_error
			-- A key that is not one of the five, with its line and key.
		do
			assert_error ("unknown", "fg = %"red%"%N%Nfgg = %"blue%"", 3, 0, "fgg", "unknown field 'fgg'")
			assert_error ("serde name misspelt", "add_modifiers = %"BOLD%"", 1, 0, "add_modifiers", "unknown field")
			assert_error ("case matters", "FG = %"red%"", 1, 0, "FG", "unknown field")
		end

	test_unknown_modifier_error
			-- A name that is not one of Ratatui's nine, in either list.
		do
			assert_error ("typo", "modifiers = [%"bold%", %"blod%"]", 1, 0, "modifiers", "unknown modifier %"blod%"")
			assert_error ("eiffel name", "# c%Nremove_modifiers = [%"strikethrough%"]", 2, 0, "remove_modifiers", "unknown modifier %"strikethrough%"")
			assert_error ("empty name", "modifiers = [%"%"]", 1, 0, "modifiers", "unknown modifier")
		end

	test_bad_color_error
			-- A string that `{COLOR}.make_from_string` does not read.
		do
			assert_error ("name", "fg = %"redd%"", 1, 0, "fg", "%"redd%" is not a color")
			assert_error ("index", "bg = %"256%"", 1, 0, "bg", "is not a color")
			assert_error ("short hex", "fg = %"red%"%Nunderline_color = %"#FFF%"", 2, 0, "underline_color", "%"#FFF%" is not a color")
			assert_error ("empty", "fg = %"%"", 1, 0, "fg", "is not a color")
		end

	test_wrong_value_type_error
			-- A color must be a string, a modifier list an array.
		do
			assert_error ("color array", "fg = [%"red%"]", 1, 0, "fg", "must be a string")
			assert_error ("modifiers string", "modifiers = %"bold%"", 1, 0, "modifiers", "must be an array")
			assert_error ("remove string", "bg = %"red%"%Nremove_modifiers = %"bold%"", 2, 0, "remove_modifiers", "must be an array")
		end

	test_modifier_in_both_lists_error
			-- One modifier added and removed is an error, reported on `remove_modifiers`.
		do
			assert_error ("both", "modifiers = [%"bold%", %"dim%"]%Nremove_modifiers = [%"dim%"]", 2, 0, "remove_modifiers", "'dim' is in both")
			assert_error ("removed first", "remove_modifiers = [%"italic%"]%Nmodifiers = [%"Italic%"]", 1, 0, "remove_modifiers", "'italic' is in both")
			assert_error ("blink names", "modifiers = [%"slow_blink%"]%Nremove_modifiers = [%"Slow-Blink%"]", 2, 0, "remove_modifiers", "'slow_blink' is in both")
			assert ("two blinks are two flags", read_ok ("blinks", "modifiers = [%"rapid_blink%"]%Nremove_modifiers = [%"slow_blink%"]").is_equal ((create {STYLE}).with_rapid_blink.without_modifier ({STYLE_FLAGS}.Flag_blink)))
		end

	test_ratatui_serde_keys
			-- Ratatui's `add_modifier` and `sub_modifier`, a "BOLD | ITALIC" string as
			-- `bitflags` writes it, are read (never printed). The first case is Ratatui's own
			-- `serialize_then_deserialize` test (ratatui-core/src/style.rs) as TOML.
		local
			l_style: STYLE
		do
			l_style := read_ok ("ratatui", "fg = %"#FF00FF%"%Nbg = %"White%"%Nunderline_color = %"3%"%Nadd_modifier = %"UNDERLINED%"%Nsub_modifier = %"CROSSED_OUT%"%N")
			assert ("ratatui style", l_style.is_equal ((create {STYLE}.make_with_colors ({COLOR}.rgb (255, 0, 255), {COLOR}.Bright_white)).with_underline_color (create {COLOR}.make_indexed (3)).with_underline.without_modifier ({STYLE_FLAGS}.Flag_strikethrough)))
			assert_same_text ("printed in the array form", {STYLE_TEXT}.text (l_style),
				"fg = %"#FF00FF%"%Nbg = %"White%"%Nunderline_color = %"3%"%Nmodifiers = [%"underlined%"]%Nremove_modifiers = [%"crossed_out%"]%N")
			assert ("joined", read_ok ("joined", "add_modifier = %"BOLD | ITALIC%"").add_modifier.bits = ({STYLE_FLAGS}.Flag_bold | {STYLE_FLAGS}.Flag_italic))
			assert ("spaces and case", read_ok ("spaces", "add_modifier = %"  bold|Italic  %"").add_modifier.bits = ({STYLE_FLAGS}.Flag_bold | {STYLE_FLAGS}.Flag_italic))
			assert ("blinks", read_ok ("blinks", "add_modifier = %"SLOW_BLINK | RAPID_BLINK%"").add_modifier.bits = ({STYLE_FLAGS}.Flag_blink | {STYLE_FLAGS}.Flag_rapid_blink))
			assert ("empty string", read_ok ("empty", "add_modifier = %"%"%Nsub_modifier = %" %"").is_equal (create {STYLE}))
			assert ("mixed with arrays", read_ok ("mixed", "modifiers = [%"bold%"]%Nsub_modifier = %"DIM%"").is_equal ((create {STYLE}).with_bold.without_modifier ({STYLE_FLAGS}.Flag_dim)))
			assert_error ("empty name", "add_modifier = %"BOLD |%"", 1, 0, "add_modifier", "empty modifier name")
			assert_error ("hex", "sub_modifier = %"0x1%"", 1, 0, "sub_modifier", "hexadecimal")
			assert_error ("unknown", "add_modifier = %"BOLD | BLOD%"", 1, 0, "add_modifier", "unknown modifier %"BLOD%"")
			assert_error ("array", "add_modifier = [%"BOLD%"]", 1, 0, "add_modifier", "must be a string")
			assert_error ("both added", "modifiers = [%"bold%"]%Nadd_modifier = %"ITALIC%"", 2, 0, "add_modifier", "'modifiers' and 'add_modifier' both give the added")
			assert_error ("both removed", "sub_modifier = %"DIM%"%Nremove_modifiers = [%"bold%"]", 2, 0, "remove_modifiers", "'sub_modifier' and 'remove_modifiers' both give the removed")
			assert_error ("in both", "add_modifier = %"BOLD%"%Nsub_modifier = %"BOLD%"", 2, 0, "sub_modifier", "'bold' is in both add_modifier and sub_modifier")
		end

	test_rapid_blink_sgr
			-- Slow blink is SGR 5 and rapid blink SGR 6, as crossterm writes `SlowBlink` and
			-- `RapidBlink` (ratatui-crossterm/src/lib.rs, `ModifierDiff`).
		do
			assert_same_text ("slow", (create {STYLE}).with_blink.flags.sgr_codes, "5")
			assert_same_text ("rapid", (create {STYLE}).with_rapid_blink.flags.sgr_codes, "6")
			assert_same_text ("both", (create {STYLE}).with_blink.with_rapid_blink.flags.sgr_codes, "5;6")
			assert ("rapid flag", (create {STYLE}).with_rapid_blink.flags.is_rapid_blink and not (create {STYLE}).with_rapid_blink.flags.is_blink)
		end

	test_format_error_position
			-- An error of the Q1 format keeps the reader's line and column (counted in the
			-- style text); a section header is not allowed in a style text.
		do
			assert_error ("number", "fg = %"red%"%Nbg = 3", 2, 6, "", "double-quoted string")
			assert_error ("duplicate", "fg = %"red%"%Nfg = %"blue%"", 2, 1, "", "duplicate key 'fg'")
			assert_error ("header", "fg = %"red%"%N[other]%Nbg = %"blue%"", 2, 1, "", "no [name] section headers")
				-- The header error names the header whatever its name (not "duplicate section"
				-- for the name `read` uses itself), and points at its "["
			assert_error ("own name", "[style]%Nfg = %"red%"", 1, 1, "", "no [name] section headers")
			assert_error ("indented", "fg = %"red%"%N%T [primary]", 2, 3, "", "no [name] section headers")
			assert_error ("not a header name", "[a.b]", 1, 1, "", "no [name] section headers")
			assert_error ("earlier error first", "bg = 3%N[other]", 1, 6, "", "double-quoted string")
			assert ("not headers", read_ok ("brackets", "# [comment]%Nfg = %"red%"%Nmodifiers = [%"bold%"]").is_equal ((create {STYLE}.make_fg ({COLOR}.Red)).with_bold))
		end

	test_section_error_without_lines
			-- A section made in code has no lines: the error names the key only.
		local
			l_section: TOML_SUBSET_SECTION
			l_reader: STYLE_TEXT
		do
			create l_section.make ("primary")
			l_section.put_string ("fg", "red")
			l_section.put_string ("colour", "red")
			create l_reader.make
			assert ("no style", l_reader.parsed_section (l_section) = Void)
			assert ("no line", l_reader.has_error and l_reader.error_line = 0 and l_reader.error_column = 0)
			assert ("key", l_reader.error_key.same_string ("colour"))
			assert_same_text ("description", l_reader.error_description, "key 'colour': unknown field 'colour' (a style has fg, bg, underline_color, modifiers and remove_modifiers, or Ratatui's add_modifier and sub_modifier)")
		end

	test_failed_read_has_no_style
			-- A failed read gives no style; the next good read clears the error.
		local
			l_reader: STYLE_TEXT
		do
			create l_reader.make
			assert ("good", attached l_reader.parsed ("fg = %"red%"") and not l_reader.has_error)
			assert ("bad", l_reader.parsed ("fg = %"red%"%Nmodifiers = [%"nope%"]") = Void)
			assert ("error", l_reader.has_error and l_reader.style = Void)
			assert_same_text ("description", l_reader.error_description, "line 2, key 'modifiers': unknown modifier %"nope%" (one of bold, dim, italic, underlined, slow_blink, rapid_blink, reversed, hidden, crossed_out)")
			assert ("good again", attached l_reader.parsed ("bg = %"blue%"") and not l_reader.has_error)
			assert ("cleared", l_reader.error_line = 0 and l_reader.error_message.is_empty and l_reader.error_key.is_empty and l_reader.error_description.is_empty)
		end

	test_preconditions
			-- `put_style` refuses a section that already has a style key.
		local
			l_section: TOML_SUBSET_SECTION
		do
			create l_section.make ("a")
			l_section.put_string ("bg", "red")
			assert ("style key", precondition_raised (agent put_style_into ((create {STYLE}).with_bold, l_section), "no_style_keys"))
			assert ("unchanged", l_section.count = 1)
			assert ("builders representable", {STYLE_TEXT}.is_representable ((create {STYLE}).with_bold.without_modifier ({STYLE_FLAGS}.Flag_dim)))
		end

feature {NONE} -- Helpers

	read_ok (a_tag: STRING; a_text: READABLE_STRING_GENERAL): STYLE
			-- The style `a_text` reads to; fails the test when it has an error.
		local
			l_reader: STYLE_TEXT
		do
			create l_reader.make
			if attached l_reader.parsed (a_text) as l_style then
				Result := l_style
			else
				assert (a_tag + " reads: " + utf_8 (l_reader.error_description), False)
				create Result
			end
		end

	assert_error (a_tag: STRING; a_text: READABLE_STRING_GENERAL; a_line, a_column: INTEGER; a_key, a_fragment: READABLE_STRING_GENERAL)
			-- Check that `a_text` is refused at `a_line`, `a_column`, about `a_key`, with a
			-- message that holds `a_fragment`, and gives no style.
		local
			l_reader: STYLE_TEXT
		do
			create l_reader.make
			l_reader.read (a_text)
			assert (a_tag + " has error", l_reader.has_error)
			assert (a_tag + " no style", l_reader.style = Void)
			assert (a_tag + " at " + a_line.out + ":" + a_column.out + ", got " + utf_8 (l_reader.error_description),
				l_reader.error_line = a_line and l_reader.error_column = a_column)
			assert (a_tag + " key, got " + utf_8 (l_reader.error_key), l_reader.error_key.same_string_general (a_key))
			assert (a_tag + " message: " + utf_8 (l_reader.error_message), l_reader.error_message.has_substring (a_fragment))
		end

	assert_round_trip (a_tag: STRING; a_style: STYLE)
			-- Check that the printed `a_style` reads back equal, and prints the same again.
		local
			l_text: STRING_32
		do
			l_text := {STYLE_TEXT}.text (a_style)
			if attached (create {STYLE_TEXT}.make).parsed (l_text) as l_read then
				assert (a_tag + " reads back: " + utf_8 (l_text), l_read.is_equal (a_style))
				assert_same_text (a_tag + " prints again", {STYLE_TEXT}.text (l_read), l_text)
			else
				assert (a_tag + " reads: " + utf_8 (l_text), False)
			end
		end

	assert_same_text (a_tag: STRING; a_actual, a_expected: READABLE_STRING_GENERAL)
			-- Check that `a_actual` is `a_expected`.
		do
			assert (a_tag + ": " + utf_8 (a_actual), a_actual.same_string (a_expected))
		end

	added (a_flag: NATURAL_16): STYLE
			-- An empty style with `a_flag` added through its builder
		do
			if a_flag = {STYLE_FLAGS}.Flag_bold then
				Result := (create {STYLE}).with_bold
			elseif a_flag = {STYLE_FLAGS}.Flag_dim then
				Result := (create {STYLE}).with_dim
			elseif a_flag = {STYLE_FLAGS}.Flag_italic then
				Result := (create {STYLE}).with_italic
			elseif a_flag = {STYLE_FLAGS}.Flag_underline then
				Result := (create {STYLE}).with_underline
			elseif a_flag = {STYLE_FLAGS}.Flag_blink then
				Result := (create {STYLE}).with_blink
			elseif a_flag = {STYLE_FLAGS}.Flag_rapid_blink then
				Result := (create {STYLE}).with_rapid_blink
			elseif a_flag = {STYLE_FLAGS}.Flag_reverse then
				Result := (create {STYLE}).with_reverse
			elseif a_flag = {STYLE_FLAGS}.Flag_hidden then
				Result := (create {STYLE}).with_hidden
			else
				Result := (create {STYLE}).with_strikethrough
			end
		end

	flag_name (a_flag: NATURAL_16): STRING_8
			-- The printed name of `a_flag`, written out here (not taken from STYLE_TEXT)
		do
			if a_flag = {STYLE_FLAGS}.Flag_bold then
				Result := "bold"
			elseif a_flag = {STYLE_FLAGS}.Flag_dim then
				Result := "dim"
			elseif a_flag = {STYLE_FLAGS}.Flag_italic then
				Result := "italic"
			elseif a_flag = {STYLE_FLAGS}.Flag_underline then
				Result := "underlined"
			elseif a_flag = {STYLE_FLAGS}.Flag_blink then
				Result := "slow_blink"
			elseif a_flag = {STYLE_FLAGS}.Flag_rapid_blink then
				Result := "rapid_blink"
			elseif a_flag = {STYLE_FLAGS}.Flag_reverse then
				Result := "reversed"
			elseif a_flag = {STYLE_FLAGS}.Flag_hidden then
				Result := "hidden"
			else
				Result := "crossed_out"
			end
		end

	utf_8 (a_text: READABLE_STRING_GENERAL): STRING_8
			-- `a_text` in UTF-8, for messages
		do
			Result := {UTF_CONVERTER}.utf_32_string_to_utf_8_string_8 (a_text.to_string_32)
		end

	put_style_into (a_style: STYLE; a_section: TOML_SUBSET_SECTION)
			-- `{STYLE_TEXT}.put_style (a_style, a_section)` (for `precondition_raised`)
		do
			{STYLE_TEXT}.put_style (a_style, a_section)
		end

	precondition_raised (a_action: ROUTINE; a_tag: STRING): BOOLEAN
			-- Does `a_action` raise a precondition violation tagged `a_tag`?
		local
			l_retried: BOOLEAN
		do
			if not l_retried then
				a_action.call
			end
		rescue
			if not l_retried then
				l_retried := True
				Result := attached (create {EXCEPTION_MANAGER}).last_exception as e and then
					(attached {PRECONDITION_VIOLATION} e.original as v and then
					(attached v.description as d and then d.same_string (a_tag)))
				retry
			end
		end

end
