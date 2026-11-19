note
	description: "[
		TUI_THEME_FILE (review/p2_terminal_widgets_plan.md, C3): theme load and save in the
		theme file format (Q1, through C2's STYLE_TEXT), the presets shipped as files under
		examples/themes/, and EXAMPLE_SETTINGS, which switches themes on real widgets.

		Files: the tests write their temporary files to the directory named by TEMP, TMP or
		TMPDIR (else the current directory) and delete them. The shipped presets are looked
		for under examples/themes/ in the current directory, its parents, and $SRC_DIR (the
		source directory in the Docker image, whose tests run from another directory).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_THEME_FILE

inherit
	BUFFER_TEST_HELPER

feature -- Writing and round trip

	test_dark_text
			-- `as_text` of the dark preset, exactly: the thirteen sections in TUI_THEME's order,
			-- each style as STYLE_TEXT prints it, one blank line between sections.
		do
			assert ("dark text", {TUI_THEME_FILE}.as_text ({TUI_THEME}.dark).same_string (Dark_text))
		end

	test_round_trip_presets
			-- `as_text` then `load_from_string` gives an equal theme, for each preset.
		local
			l_file: TUI_THEME_FILE
			i: INTEGER
		do
			create l_file.make
			from i := 1 until i > presets.count loop
				l_file.load_from_string ({TUI_THEME_FILE}.as_text (presets [i]))
				assert ("read back " + Preset_names [i], not l_file.has_error
					and then attached l_file.theme as l_theme and then l_theme.is_equal (presets [i]))
				i := i + 1
			end
		end

	test_round_trip_presets_through_files
			-- `save` to a real file then `load` gives an equal theme, for each preset; the
			-- file's bytes are `as_text` in UTF-8, with LF line ends and no BOM.
		local
			l_file: TUI_THEME_FILE
			l_path: STRING_32
			i: INTEGER
		do
			create l_file.make
			l_path := temp_path ("round_trip.toml")
			from i := 1 until i > presets.count loop
				l_file.save (presets [i], l_path)
				assert ("saved " + Preset_names [i], not l_file.has_error and l_file.theme = Void)
				assert ("bytes " + Preset_names [i], file_bytes (l_path).same_string (
					{UTF_CONVERTER}.string_32_to_utf_8_string_8 ({TUI_THEME_FILE}.as_text (presets [i]))))
				assert ("loaded " + Preset_names [i], attached l_file.loaded (l_path) as l_theme
					and then l_theme.is_equal (presets [i]))
				i := i + 1
			end
			delete (l_path)
		end

	test_round_trip_custom_theme
			-- A theme with every kind of style (all colour kinds, underline colour, added and
			-- removed modifiers, an empty style, non-default styles in every entry) saves and
			-- loads back equal.
		local
			l_theme: TUI_THEME
			l_file: TUI_THEME_FILE
			l_path: STRING_32
		do
			l_theme := {TUI_THEME}.nord
			l_theme.set_base (create {STYLE})
			l_theme.set_primary ((create {STYLE}.make_fg (create {COLOR}.make_indexed (208))).with_italic.with_underline_color ({COLOR}.rgb (1, 2, 3)))
			l_theme.set_muted ((create {STYLE}.make_fg ({COLOR}.Reset_color)).with_dim.without_modifier ({STYLE_FLAGS}.Flag_bold))
			l_theme.set_text ((create {STYLE}.make_with_colors ({COLOR}.Bright_white, {COLOR}.Dark_gray)).with_reverse.with_strikethrough)
			create l_file.make
			assert ("as text", attached l_file.parsed ({TUI_THEME_FILE}.as_text (l_theme)) as l_read and then l_read.is_equal (l_theme))
			l_path := temp_path ("custom.toml")
			l_file.save (l_theme, l_path)
			assert ("through a file", attached l_file.loaded (l_path) as l_read and then l_read.is_equal (l_theme))
			delete (l_path)
		end

	test_shipped_preset_files_match
			-- examples/themes/dark.toml, light.toml, nord.toml and dracula.toml are exactly what
			-- `save` writes for the presets (their bytes are the UTF-8 of `as_text`), and they
			-- load to the presets.
		local
			l_dir: detachable STRING_32
			l_path: STRING_32
			l_file: TUI_THEME_FILE
			i: INTEGER
		do
			l_dir := themes_directory
			assert ("examples/themes found (run from the repository)", l_dir /= Void)
			if attached l_dir then
				create l_file.make
				from i := 1 until i > presets.count loop
					l_path := l_dir + "/" + Preset_names [i] + ".toml"
					assert (Preset_names [i] + ".toml is as_text", file_bytes (l_path).same_string (
						{UTF_CONVERTER}.string_32_to_utf_8_string_8 ({TUI_THEME_FILE}.as_text (presets [i]))))
					assert (Preset_names [i] + ".toml loads", attached l_file.loaded (l_path) as l_theme and then l_theme.is_equal (presets [i]))
					i := i + 1
				end
			end
		end

feature -- Reading

	test_partial_file_keeps_other_sections
			-- A file with two sections changes those two entries; the other eleven keep the
			-- default (dark) theme's styles. An empty text is the dark theme.
		local
			l_file: TUI_THEME_FILE
			l_expected: TUI_THEME
		do
			create l_file.make
			l_expected := {TUI_THEME}.dark
			l_expected.set_primary ((create {STYLE}.make_fg ({COLOR}.rgb (0x88, 0xC0, 0xD0))).with_bold)
			l_expected.set_border (create {STYLE}.make_fg ({COLOR}.Red))
			assert ("two sections", attached l_file.parsed ("[primary]%Nfg = %"#88c0d0%"%Nmodifiers = [%"bold%"]%N%N[border]%Nfg = %"red%"%N") as l_theme
				and then l_theme.is_equal (l_expected))
			assert ("one section", attached l_file.parsed ("[error]%Nfg = %"LightRed%"%N") as l_theme
				and then l_theme.is_equal ({TUI_THEME}.dark.with_error (create {STYLE}.make_fg ({COLOR}.Bright_red))))
			assert ("empty text", attached l_file.parsed ("") as l_theme and then l_theme.is_equal ({TUI_THEME}.dark))
			assert ("defaults are dark", {TUI_THEME_FILE}.Defaults.is_equal ({TUI_THEME}.dark))
		end

	test_present_section_replaces_default
			-- Decision: a section replaces the default style, it is not patched over it. The dark
			-- title is light cyan and bold; `[title]` with only `fg = "red"` is red and not bold.
			-- An empty section is the empty style.
		local
			l_file: TUI_THEME_FILE
		do
			create l_file.make
			assert ("dark title is bold", {TUI_THEME}.dark.title.flags.has_flag ({STYLE_FLAGS}.Flag_bold))
			assert ("replaced", attached l_file.parsed ("[title]%Nfg = %"red%"") as l_theme
				and then l_theme.title.is_equal (create {STYLE}.make_fg ({COLOR}.Red))
				and then not l_theme.title.flags.has_flag ({STYLE_FLAGS}.Flag_bold))
			assert ("empty section", attached l_file.parsed ("[highlight]%N") as l_theme
				and then l_theme.highlight.is_equal (create {STYLE})
				and then l_theme.base.is_equal ({TUI_THEME}.dark.base))
			assert ("remove_modifiers kept for patching", attached l_file.parsed ("[selection]%Nremove_modifiers = [%"bold%"]") as l_theme
				and then l_theme.selection.is_equal ((create {STYLE}).without_modifier ({STYLE_FLAGS}.Flag_bold))
				and then not {TUI_THEME}.dark.selection.patch (l_theme.selection).flags.has_flag ({STYLE_FLAGS}.Flag_bold))
		end

	test_comments_and_blank_lines_skipped
			-- Comment lines, comments after headers and values, blank and indented lines, CR LF
			-- line ends and sections in any order read as the plain text does.
		local
			l_file: TUI_THEME_FILE
			l_expected: TUI_THEME
		do
			create l_file.make
			l_expected := {TUI_THEME}.light.with_primary (create {STYLE}.make_fg ({COLOR}.Magenta))
			assert ("commented", attached l_file.parsed (
				{STRING_32} "# A theme%R%N%R%N  # indented comment%R%N[primary] # the accent%R%N%Tfg = %"magenta%" # value comment%R%N%R%N"
				+ light_without_primary_reversed) as l_theme
				and then l_theme.is_equal (l_expected))
		end

feature -- Errors

	test_unknown_section_error
			-- An unknown section is an error at its header's line, naming the section; names
			-- are exact ("Primary" is not "primary").
		local
			l_file: TUI_THEME_FILE
		do
			create l_file.make
			l_file.load_from_string ("# theme%N[primary]%Nfg = %"red%"%N%N[backgound]%Nfg = %"blue%"%N")
			assert_error ("misspelt", l_file, 5, 0, "backgound", "", "unknown section [backgound]")
			assert ("lists the names", l_file.error_message.has_substring ("base, primary") and l_file.error_message.has_substring ("and text"))
			l_file.load_from_string ("[Primary]%N")
			assert_error ("case", l_file, 1, 0, "Primary", "", "unknown section [Primary]")
			assert ("description", l_file.error_description.same_string ({STRING_32} "line 1, section [Primary]: " + l_file.error_message))
		end

	test_format_error_line
			-- An error of the format (Q1) keeps its line and column.
		local
			l_file: TUI_THEME_FILE
		do
			create l_file.make
			l_file.load_from_string ("[base]%Nfg = %"red%"%N%N[primary]%Nfg = 'red'%N")
			assert_error ("literal string", l_file, 5, 6, "", "", "literal strings")
			assert ("description", l_file.error_description.starts_with ({STRING_32} "line 5, column 6: "))
			l_file.load_from_string ("[base]%N[base]%N")
			assert_error ("duplicate section", l_file, 2, -1, "", "", "")
			l_file.load_from_string ("fg = %"red%"%N")
			assert_error ("key before a section", l_file, 1, -1, "", "", "")
			l_file.load_from_string ("[base]%Nfg = %"red%"%Nfg = %"blue%"%N")
			assert_error ("duplicate key", l_file, 3, -1, "", "", "")
		end

	test_style_error_lines
			-- An error of a style (C2) has the line of its key, the section and the key.
		local
			l_file: TUI_THEME_FILE
		do
			create l_file.make
			l_file.load_from_string ("[base]%Nfg = %"red%"%N%N[primary]%N# comment%Ncolour = %"red%"%N")
			assert_error ("unknown field", l_file, 6, 0, "primary", "colour", "unknown field 'colour'")
			assert ("description", l_file.error_description.same_string ({STRING_32} "line 6, section [primary], key 'colour': " + l_file.error_message))
			l_file.load_from_string ("[muted]%Nbg = %"#12345%"%N")
			assert_error ("bad colour", l_file, 2, 0, "muted", "bg", "is not a color")
			l_file.load_from_string ("[title]%Nfg = %"red%"%Nmodifiers = [%"bold%", %"shiny%"]%N")
			assert_error ("unknown modifier", l_file, 3, 0, "title", "modifiers", "unknown modifier %"shiny%"")
			l_file.load_from_string ("[text]%Nfg = [%"red%"]%N")
			assert_error ("colour is an array", l_file, 2, 0, "text", "fg", "must be a string")
			l_file.load_from_string ("[text]%Nmodifiers = %"bold%"%N")
			assert_error ("modifiers is a string", l_file, 2, 0, "text", "modifiers", "must be an array")
			l_file.load_from_string ("[info]%Nmodifiers = [%"bold%"]%N%Nremove_modifiers = [%"bold%"]%N")
			assert_error ("modifier in both lists", l_file, 4, 0, "info", "remove_modifiers", "is in both")
		end

	test_failed_load_leaves_no_theme
			-- A failed load gives no theme, not even the sections before the error; a later
			-- good load clears the error.
		local
			l_file: TUI_THEME_FILE
		do
			create l_file.make
			assert ("good", attached l_file.parsed ("[base]%Nfg = %"red%"") and not l_file.has_error)
			assert ("bad gives nothing", l_file.parsed ("[base]%Nfg = %"red%"%N[primary]%Nfg = %"nope%"") = Void)
			assert ("no theme", l_file.has_error and l_file.theme = Void)
			assert ("good again", attached l_file.parsed ("[base]%Nfg = %"red%"") as l_theme
				and then l_theme.base.is_equal (create {STYLE}.make_fg ({COLOR}.Red)))
			assert ("error cleared", not l_file.has_error and l_file.error_line = 0 and l_file.error_message.is_empty
				and l_file.error_section.is_empty and l_file.error_key.is_empty)
		end

	test_missing_file
			-- A missing file and a directory are errors, not exceptions, with no line.
		local
			l_file: TUI_THEME_FILE
			l_path: STRING_32
		do
			create l_file.make
			l_path := temp_path ("does_not_exist.toml")
			delete (l_path)
			assert ("missing", l_file.loaded (l_path) = Void)
			assert_error ("missing file", l_file, 0, 0, "", "", "no such file")
			assert ("names the file", l_file.error_message.has_substring ("does_not_exist.toml"))
			l_file.load (temp_directory)
			assert_error ("directory", l_file, 0, 0, "", "", "not a plain file")
		end

	test_save_errors
			-- Saving to a directory, or into a directory that does not exist, is an error, not
			-- an exception.
		local
			l_file: TUI_THEME_FILE
		do
			create l_file.make
			l_file.save ({TUI_THEME}.dark, temp_directory)
			assert_error ("directory", l_file, 0, 0, "", "", "not a plain file")
			l_file.save ({TUI_THEME}.dark, temp_path ("no_such_directory_c3/theme.toml"))
			assert_error ("no directory", l_file, 0, 0, "", "", "cannot write")
			l_file.save ({TUI_THEME}.dark, temp_path ("saved_after_error.toml"))
			assert ("good save clears the error", not l_file.has_error)
			delete (temp_path ("saved_after_error.toml"))
		end

	test_save_keeps_old_file_on_failure
			-- `save` writes a ".tmp" file and renames it over the old one: an existing file is
			-- replaced (on Windows too) and no ".tmp" file is left; when the ".tmp" file cannot
			-- be written, the old file is left whole; a read-only file is not changed.
		local
			l_file: TUI_THEME_FILE
			l_path, l_temporary: STRING_32
			l_dir: DIRECTORY
			l_old: STRING_8
			l_raw: RAW_FILE
		do
			create l_file.make
			l_path := temp_path ("replaced.toml")
			l_temporary := {TUI_THEME_FILE}.temporary_path (l_path)
			assert ("temporary path", l_temporary.same_string (l_path + {STRING_32} ".tmp"))
			l_old := "[primary]%Nfg = %"red%"%N"
			put_bytes (l_path, l_old)
			l_file.save ({TUI_THEME}.nord, l_path)
			assert ("replaced: no error", not l_file.has_error)
			assert ("replaced: new text", file_bytes (l_path).same_string ({UTF_CONVERTER}.string_32_to_utf_8_string_8 ({TUI_THEME_FILE}.as_text ({TUI_THEME}.nord))))
			assert ("replaced: no .tmp left", not (create {RAW_FILE}.make_with_name (l_temporary)).exists)
				-- A directory where the ".tmp" file goes: the write fails before the old file is touched
			put_bytes (l_path, l_old)
			create l_dir.make (l_temporary)
			if not l_dir.exists then
				l_dir.create_dir
			end
			l_file.save ({TUI_THEME}.nord, l_path)
			assert_error ("tmp cannot be written", l_file, 0, 0, "", "", "cannot write")
			assert ("old file whole", file_bytes (l_path).same_string (l_old))
			assert ("tmp directory kept", l_dir.exists)
			l_dir.delete
				-- A read-only file (skipped where the user may write it anyway, as root on POSIX)
			create l_raw.make_with_name (l_path)
			l_raw.change_mode (0c444)
			if not l_raw.is_writable then
				l_file.save ({TUI_THEME}.nord, l_path)
				assert_error ("read-only", l_file, 0, 0, "", "", "permission denied")
				assert ("read-only file not changed", file_bytes (l_path).same_string (l_old))
				assert ("read-only: no .tmp", not (create {RAW_FILE}.make_with_name (l_temporary)).exists)
			end
			l_raw.change_mode (0c644)
			delete (l_path)
		end

	test_utf_8_files
			-- `load` decodes UTF-8: non-ASCII text reads; a BOM at the start is skipped; bytes
			-- that are not UTF-8 (a bad byte, an overlong form, an encoded surrogate, a cut
			-- sequence at the end) are an error at their line. CR LF reads as LF.
		local
			l_file: TUI_THEME_FILE
			l_path: STRING_32
		do
			create l_file.make
			l_path := temp_path ("utf8.toml")
			put_bytes (l_path, "# Th%/0xC3/%/0xA8/me %/0xE2/%/0x9C/%/0x93/%N[primary]%Nfg = %"red%"%N")
			assert ("non-ASCII comment", attached l_file.loaded (l_path) as l_theme
				and then l_theme.primary.is_equal (create {STYLE}.make_fg ({COLOR}.Red)))
			put_bytes (l_path, "%/0xEF/%/0xBB/%/0xBF/[primary]%R%Nfg = %"red%"%R%N")
			assert ("BOM skipped, CR LF", attached l_file.loaded (l_path) as l_theme
				and then l_theme.primary.is_equal (create {STYLE}.make_fg ({COLOR}.Red)))
			put_bytes (l_path, "[primary]%Nfg = %"red%"%N# bad %/0xFF/ byte%N")
			assert ("bad byte", l_file.loaded (l_path) = Void)
			assert_error ("bad byte", l_file, 3, 0, "", "", "not valid UTF-8")
			put_bytes (l_path, "[primary]%N# overlong %/0xC0/%/0xAF/%N")
			l_file.load (l_path)
			assert_error ("overlong", l_file, 2, 0, "", "", "not valid UTF-8")
			put_bytes (l_path, "%N%N# surrogate %/0xED/%/0xA0/%/0x80/%N")
			l_file.load (l_path)
			assert_error ("surrogate", l_file, 3, 0, "", "", "not valid UTF-8")
			put_bytes (l_path, "[primary]%N# cut %/0xE2/%/0x9C/")
			l_file.load (l_path)
			assert_error ("cut at the end", l_file, 2, 0, "", "", "not valid UTF-8")
			put_bytes (l_path, "")
			assert ("empty file is dark", attached l_file.loaded (l_path) as l_theme and then l_theme.is_equal ({TUI_THEME}.dark))
			delete (l_path)
		end

	test_bom_in_text_is_an_error
			-- `load_from_string` takes decoded text: a U+FEFF at its start is an error of the
			-- format at line 1, column 1 (only `load` skips a BOM, as bytes).
		local
			l_file: TUI_THEME_FILE
		do
			create l_file.make
			l_file.load_from_string ({STRING_32} "%/0xFEFF/[primary]%N")
			assert_error ("BOM in text", l_file, 1, -1, "", "", "")
		end

	test_section_names
			-- The sections are TUI_THEME's thirteen semantic styles, in its order.
		do
			assert ("thirteen", {TUI_THEME_FILE}.Section_names.count = 13)
			assert ("first base", {TUI_THEME_FILE}.Section_names [1].same_string ("base"))
			assert ("last text", {TUI_THEME_FILE}.Section_names [13].same_string ("text"))
			assert ("is a name", {TUI_THEME_FILE}.is_section_name ("highlight"))
			assert ("not a name", not {TUI_THEME_FILE}.is_section_name ("Highlight") and not {TUI_THEME_FILE}.is_section_name (""))
			assert ("presets representable", across presets as l_preset all {TUI_THEME_FILE}.is_representable (l_preset) end)
		end

feature -- Example

	test_settings_example
			-- EXAMPLE_SETTINGS on a 60 x 20 frame, row-exact: the dark theme first; t cycles to
			-- light, nord and dracula, and the panel's cells take the theme's styles; Space and
			-- the arrows change a checkbox and a slider; s saves the theme to the test's path (a
			-- success toast, then the saved file loads to the theme in use); F10 opens the menu
			-- bar; Theme > Dark picks the preset; a theme file from a path is added first; a
			-- missing one gives an error toast.
		local
			l_app: SETTINGS_SNAPSHOT_APP
			l_buf: BUFFER
			l_backend: ANSI_TERMINAL_BACKEND
			l_path: STRING_32
			l_file: TUI_THEME_FILE
		do
			create l_backend.make_with_driver_and_sink (create {FAKE_CONSOLE_DRIVER}, create {STRING_32}.make_empty)
			create l_app.make_on (create {TERMINAL [ANSI_TERMINAL_BACKEND]}.make_with_viewport (l_backend, create {VIEWPORT}.make_fullscreen))
			l_path := temp_path ("settings_saved.toml")
			l_app.set_save_path (l_path)
			l_buf := settings_frame (l_app)
			assert_buffer_lines ("start", l_buf, settings_start_rows)
			assert_cell_style ("dark panel", l_buf, 10, 3, {TUI_THEME}.dark.base.patch ({TUI_THEME}.dark.text))
			assert_cell_style ("dark title", l_buf, 1, 3, {TUI_THEME}.dark.base.patch ({TUI_THEME}.dark.title))

				-- Space toggles "Show line numbers" (focused first); Tab Tab Tab, Right moves the volume
			l_app.process_now (create {KEY_EVENT}.make_char (' '))
			l_app.process_now (create {KEY_EVENT}.make_special ({KEY_CODE}.Tab))
			l_app.process_now (create {KEY_EVENT}.make_special ({KEY_CODE}.Tab))
			l_app.process_now (create {KEY_EVENT}.make_special ({KEY_CODE}.Tab))
			l_app.process_now (create {KEY_EVENT}.make_special ({KEY_CODE}.Right))
			assert ("toggled", not l_app.options [1])
			assert ("volume up", l_app.volume.value = 70)

				-- t: light, nord, dracula; the panel follows
			l_app.process_now (create {KEY_EVENT}.make_char ('t'))
			l_app.process_now (create {KEY_EVENT}.make_char ('t'))
			assert ("nord", l_app.theme_name.same_string ("nord") and l_app.theme.is_equal ({TUI_THEME}.nord))
			l_buf := settings_frame (l_app)
			assert_buffer_lines ("nord", l_buf, settings_nord_rows)
			assert_cell_style ("nord panel", l_buf, 10, 3, {TUI_THEME}.nord.base.patch ({TUI_THEME}.nord.text))
			assert_cell_style ("nord border", l_buf, 1, 0, {TUI_THEME}.nord.base.patch ({TUI_THEME}.nord.border))

				-- s: save, a success toast; the file is the nord theme
			l_app.set_fake_now (1000)
			l_app.process_now (create {KEY_EVENT}.make_char ('s'))
			l_app.process_now (create {TICK_EVENT})
			l_buf := settings_frame (l_app)
			assert_buffer_lines ("saved", l_buf, settings_saved_rows)
			assert_cell_style ("success toast border", l_buf, 14, 30, {TUI_THEME}.nord.base.patch ({TUI_THEME}.nord.success))
			create l_file.make
			assert ("saved file is nord", attached l_file.loaded (l_path) as l_theme and then l_theme.is_equal ({TUI_THEME}.nord))
			l_app.set_fake_now (4000)
			l_app.process_now (create {TICK_EVENT})
			assert ("toast expired", l_app.toasts.is_empty)

				-- F10 opens File; Right moves to Theme; Down skips the separator to Dark
			l_app.process_now (create {KEY_EVENT}.make_special (create {KEY_CODE}.make_function (10)))
			l_app.process_now (create {KEY_EVENT}.make_special ({KEY_CODE}.Right))
			l_buf := settings_frame (l_app)
			assert_buffer_lines ("theme menu", l_buf, settings_menu_rows)
			assert_cell_style ("highlighted item", l_buf, 2, 7, {TUI_THEME}.nord.base.patch ({TUI_THEME}.nord.highlight))
			l_app.process_now (create {KEY_EVENT}.make_special ({KEY_CODE}.Down))
			l_app.process_now (create {KEY_EVENT}.make_special ({KEY_CODE}.Enter))
			assert ("dark picked", not l_app.menu.is_open and l_app.theme_name.same_string ("dark"))

				-- A theme file: added first and current; t after the last preset comes back to it
			l_app.load_theme_file (l_path)
			assert ("file first", l_app.themes.count = 5 and l_app.theme_index = 1
				and l_app.theme_name.same_string ("eiffeltui_c3_settings_saved.toml") and l_app.theme.is_equal ({TUI_THEME}.nord))
			l_app.process_now (create {KEY_EVENT}.make_char ('t'))
			assert ("then dark", l_app.theme_name.same_string ("dark"))
			delete (l_path)
			l_app.load_theme_file (l_path)
			assert ("missing file: error toast", l_app.themes.count = 5 and l_app.toasts.count = 1
				and l_app.toasts.item (1).level = {TOAST_LEVEL}.error)
			assert ("consistent", l_buf.is_consistent)
		end

feature {NONE} -- Snapshot rows

	settings_start_rows: ARRAY [READABLE_STRING_GENERAL]
			-- EXAMPLE_SETTINGS at the start, 60 x 20
		do
			Result := <<
				glyphs (" File  Theme  Help                                          "),
				glyphs ("{ Settings ------------------------------------------------}"),
				glyphs ("|- Editor -------------------------------------------------|"),
				glyphs ("| [x] Show line numbers                                    |"),
				glyphs ("| [ ] Wrap lines                                           |"),
				glyphs ("| [x] Autosave                                             |"),
				glyphs ("|- Levels -------------------------------------------------|"),
				glyphs ("| Volume  =======================*--------------- 60%%      |"),
				glyphs ("| Scroll  ========*------------------------------ 3 lines  |"),
				glyphs ("|- Theme --------------------------------------------------|"),
				glyphs ("| Theme: dark (1/4)                                        |"),
				glyphs ("| info  success  warning  error                            |"),
				glyphs ("|                                                          |"),
				glyphs ("|                                                          |"),
				glyphs ("|                                                          |"),
				glyphs ("|                                                          |"),
				glyphs ("|                                                          |"),
				glyphs ("|                                                          |"),
				glyphs ("| t: theme  s: save  Tab/Space/arrows  F10: menu  q: quit  |"),
				glyphs ("`----------------------------------------------------------^")>>
		end

	settings_nord_rows: ARRAY [READABLE_STRING_GENERAL]
			-- After Space, three Tabs, Right and two t
		do
			Result := <<
				glyphs (" File  Theme  Help                                          "),
				glyphs ("{ Settings ------------------------------------------------}"),
				glyphs ("|- Editor -------------------------------------------------|"),
				glyphs ("| [ ] Show line numbers                                    |"),
				glyphs ("| [ ] Wrap lines                                           |"),
				glyphs ("| [x] Autosave                                             |"),
				glyphs ("|- Levels -------------------------------------------------|"),
				glyphs ("| Volume  ===========================*----------- 70%%      |"),
				glyphs ("| Scroll  ========*------------------------------ 3 lines  |"),
				glyphs ("|- Theme --------------------------------------------------|"),
				glyphs ("| Theme: nord (3/4)                                        |"),
				glyphs ("| info  success  warning  error                            |"),
				glyphs ("|                                                          |"),
				glyphs ("|                                                          |"),
				glyphs ("|                                                          |"),
				glyphs ("|                                                          |"),
				glyphs ("|                                                          |"),
				glyphs ("|                                                          |"),
				glyphs ("| t: theme  s: save  Tab/Space/arrows  F10: menu  q: quit  |"),
				glyphs ("`----------------------------------------------------------^")>>
		end

	settings_saved_rows: ARRAY [READABLE_STRING_GENERAL]
			-- After s: the success toast
		do
			Result := <<
				glyphs (" File  Theme  Help                                          "),
				glyphs ("{ Settings ------------------------------------------------}"),
				glyphs ("|- Editor -------------------------------------------------|"),
				glyphs ("| [ ] Show line numbers                                    |"),
				glyphs ("| [ ] Wrap lines                                           |"),
				glyphs ("| [x] Autosave                                             |"),
				glyphs ("|- Levels -------------------------------------------------|"),
				glyphs ("| Volume  ===========================*----------- 70%%      |"),
				glyphs ("| Scroll  ========*------------------------------ 3 lines  |"),
				glyphs ("|- Theme --------------------------------------------------|"),
				glyphs ("| Theme: nord (3/4)                                        |"),
				glyphs ("| info  success  warning  error                            |"),
				glyphs ("|                                                          |"),
				glyphs ("|                                                          |"),
				glyphs ("|                        {--------------------------------}|"),
				glyphs ("|                        |Saved theme nord to             ||"),
				glyphs ("|                        |eiffeltui_c3_settings_saved.toml||"),
				glyphs ("|                        `--------------------------------^|"),
				glyphs ("| t: theme  s: save  Tab/Space/arrows  F10: menu  q: quit  |"),
				glyphs ("`----------------------------------------------------------^")>>
		end

	settings_menu_rows: ARRAY [READABLE_STRING_GENERAL]
			-- The Theme menu open
		do
			Result := <<
				glyphs (" File  Theme  Help                                          "),
				glyphs ("{ Sett<--------------->------------------------------------}"),
				glyphs ("|- Edi| Next theme  t |#-----------------------------------|"),
				glyphs ("| [ ] |---------------|#                                   |"),
				glyphs ("| [ ] | Dark          |#                                   |"),
				glyphs ("| [x] | Light         |#                                   |"),
				glyphs ("|- Lev| Nord          |#-----------------------------------|"),
				glyphs ("| Volu| Dracula       |#=============*----------- 70%%      |"),
				glyphs ("| Scro!---------------?#------------------------- 3 lines  |"),
				glyphs ("|- Them#################-----------------------------------|"),
				glyphs ("| Theme: nord (3/4)                                        |"),
				glyphs ("| info  success  warning  error                            |"),
				glyphs ("|                                                          |"),
				glyphs ("|                                                          |"),
				glyphs ("|                                                          |"),
				glyphs ("|                                                          |"),
				glyphs ("|                                                          |"),
				glyphs ("|                                                          |"),
				glyphs ("| t: theme  s: save  Tab/Space/arrows  F10: menu  q: quit  |"),
				glyphs ("`----------------------------------------------------------^")>>
		end

feature {NONE} -- Helpers

	glyphs (a_pattern: STRING_8): STRING_32
			-- `a_pattern` with '-' U+2500, '|' U+2502, '=' U+2501, '*' U+25CF (a slider's
			-- track, filled part and thumb), '{' U+256D, '}' U+256E, '`' U+2570, '^' U+256F
			-- (rounded corners), '<' U+250C, '>' U+2510, '!' U+2514, '?' U+2518 (a drop-down's
			-- corners) and '#' U+2591 (its shadow); other characters as they are.
		local
			i: INTEGER
		do
			create Result.make (a_pattern.count)
			from i := 1 until i > a_pattern.count loop
				inspect a_pattern [i]
				when '-' then Result.append_character ((0x2500).to_character_32)
				when '|' then Result.append_character ((0x2502).to_character_32)
				when '=' then Result.append_character ((0x2501).to_character_32)
				when '*' then Result.append_character ((0x25CF).to_character_32)
				when '{' then Result.append_character ((0x256D).to_character_32)
				when '}' then Result.append_character ((0x256E).to_character_32)
				when '`' then Result.append_character ((0x2570).to_character_32)
				when '^' then Result.append_character ((0x256F).to_character_32)
				when '<' then Result.append_character ((0x250C).to_character_32)
				when '>' then Result.append_character ((0x2510).to_character_32)
				when '!' then Result.append_character ((0x2514).to_character_32)
				when '?' then Result.append_character ((0x2518).to_character_32)
				when '#' then Result.append_character ((0x2591).to_character_32)
				else Result.append_character (a_pattern [i].to_character_32)
				end
				i := i + 1
			end
		end

	Preset_names: ARRAY [STRING]
			-- The presets' file names, in the order of `presets`
		once
			Result := <<"dark", "light", "nord", "dracula">>
		end

	presets: ARRAY [TUI_THEME]
			-- The four presets
		do
			Result := <<{TUI_THEME}.dark, {TUI_THEME}.light, {TUI_THEME}.nord, {TUI_THEME}.dracula>>
		end

	Dark_text: STRING_32 = "[
[base]
fg = "Gray"
bg = "Black"

[primary]
fg = "Cyan"

[secondary]
fg = "Blue"

[success]
fg = "Green"

[warning]
fg = "Yellow"

[error]
fg = "Red"

[info]
fg = "LightCyan"

[highlight]
fg = "Black"
bg = "Cyan"
modifiers = ["bold"]

[selection]
fg = "Gray"
bg = "Blue"
modifiers = ["bold"]

[muted]
fg = "DarkGray"

[border]
fg = "DarkGray"

[title]
fg = "LightCyan"
modifiers = ["bold"]

[text]
fg = "Gray"

]"
			-- `as_text` of the dark preset (the verbatim string's last, empty line gives the
			-- final line end)

	light_without_primary_reversed: STRING_32
			-- The light preset's sections other than `primary`, last section first
		local
			l_document: TOML_SUBSET_DOCUMENT
			i: INTEGER
		do
			create l_document
			from i := {TUI_THEME_FILE}.Section_names.count until i < 1 loop
				if i /= 2 then
					{STYLE_TEXT}.put_style ({TUI_THEME_FILE}.style ({TUI_THEME}.light, i), l_document.put_new ({TUI_THEME_FILE}.Section_names [i]))
				end
				i := i - 1
			end
			Result := {TOML_SUBSET_WRITER}.text (l_document)
		end

	settings_frame (a_app: SETTINGS_SNAPSHOT_APP): BUFFER
			-- A 60 x 20 frame drawn by `a_app`
		do
			create Result.make (60, 20)
			a_app.render_now (create {FRAME}.make (Result))
		end

	assert_error (a_tag: STRING; a_file: TUI_THEME_FILE; a_line, a_column: INTEGER; a_section, a_key, a_fragment: READABLE_STRING_GENERAL)
			-- `a_file` has an error at `a_line`, `a_column` (not checked when negative), in
			-- `a_section` about `a_key`, whose message has `a_fragment`, and no theme.
		do
			assert (a_tag + ": has error", a_file.has_error and a_file.theme = Void)
			assert (a_tag + ": line " + a_file.error_line.out, a_file.error_line = a_line)
			assert (a_tag + ": column " + a_file.error_column.out, a_column < 0 or else a_file.error_column = a_column)
			assert (a_tag + ": section", a_file.error_section.same_string_general (a_section))
			assert (a_tag + ": key", a_file.error_key.same_string_general (a_key))
			assert (a_tag + ": message " + printable (a_file.error_message), a_file.error_message.has_substring (a_fragment.as_string_32))
		end

	temp_directory: STRING_32
			-- TEMP, TMP or TMPDIR, else "."
		local
			l_env: EXECUTION_ENVIRONMENT
		do
			create l_env
			if attached l_env.item ("TEMP") as l_dir and then not l_dir.is_empty then
				Result := l_dir
			elseif attached l_env.item ("TMP") as l_dir and then not l_dir.is_empty then
				Result := l_dir
			elseif attached l_env.item ("TMPDIR") as l_dir and then not l_dir.is_empty then
				Result := l_dir
			else
				Result := "."
			end
		end

	temp_path (a_name: READABLE_STRING_GENERAL): STRING_32
			-- `a_name` in `temp_directory`, prefixed with "eiffeltui_c3_"
		do
			Result := temp_directory + {STRING_32} "/eiffeltui_c3_" + a_name.as_string_32
		end

	themes_directory: detachable STRING_32
			-- examples/themes in the current directory, a parent (up to four up), or $SRC_DIR
		local
			l_candidates: ARRAYED_LIST [STRING_32]
			l_prefix: STRING_32
			i: INTEGER
		do
			create l_candidates.make (6)
			create l_prefix.make_empty
			from i := 0 until i > 4 loop
				l_candidates.extend (l_prefix + "examples/themes")
				l_prefix.append ({STRING_32} "../")
				i := i + 1
			end
			if attached (create {EXECUTION_ENVIRONMENT}).item ("SRC_DIR") as l_src and then not l_src.is_empty then
				l_candidates.extend (l_src + "/examples/themes")
			end
			across l_candidates as l_dir until Result /= Void loop
				if (create {RAW_FILE}.make_with_name (l_dir + "/dark.toml")).exists then
					Result := l_dir
				end
			end
		end

	file_bytes (a_path: READABLE_STRING_GENERAL): STRING_8
			-- The bytes of the file at `a_path` (empty when it cannot be read)
		local
			l_file: RAW_FILE
		do
			create Result.make_empty
			create l_file.make_with_name (a_path)
			if l_file.exists and then l_file.is_readable then
				l_file.open_read
				if l_file.count > 0 then
					l_file.read_stream (l_file.count)
					Result := l_file.last_string.twin
				end
				l_file.close
			end
		end

	put_bytes (a_path: READABLE_STRING_GENERAL; a_bytes: STRING_8)
			-- Write `a_bytes` to the file at `a_path`, replacing it.
		local
			l_file: RAW_FILE
		do
			create l_file.make_with_name (a_path)
			l_file.open_write
			l_file.put_string (a_bytes)
			l_file.close
		end

	delete (a_path: READABLE_STRING_GENERAL)
			-- Delete the file at `a_path`, if there is one.
		local
			l_file: RAW_FILE
		do
			create l_file.make_with_name (a_path)
			if l_file.exists then
				l_file.delete
			end
		end

end
