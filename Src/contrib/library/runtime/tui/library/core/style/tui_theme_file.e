note
	description: "[
		Loads and saves a TUI_THEME as a theme file (review/p2_terminal_widgets_plan.md, C3), in
		the theme file format (Q1, TOML_SUBSET_READER / TOML_SUBSET_WRITER), as Ratatui apps
		read a theme with `serde` and `toml`.

		A theme file has one section per semantic style of TUI_THEME, named as its query:
		`base`, `primary`, `secondary`, `success`, `warning`, `error`, `info`, `highlight`,
		`selection`, `muted`, `border`, `title`, `text` (`Section_names`). The keys of a section
		are a style as STYLE_TEXT (C2) reads and prints it: `fg`, `bg`, `underline_color`,
		`modifiers`, `remove_modifiers`. For example:

			# My theme: only two entries differ from the dark preset
			[primary]
			fg = "#88c0d0"
			modifiers = ["bold"]

			[border]
			fg = "DarkGray"

		Reading (`load`, `load_from_string`, `loaded`, `parsed`):
		* Missing sections keep the style of `Defaults`, the dark preset
		  (`{TUI_THEME}.dark`, also `create {TUI_THEME}`), so a file can change two entries.
		* Decision: a present section **replaces** the default style; it is not patched over
		  it. `[title]` with only `fg = "red"` gives a title that is red and not bold, although
		  the dark title is bold. So a section means the same in every file, whatever the
		  defaults, and `as_text` -> `parsed` gives back an equal theme (`is_equal`, the patch
		  sets included). An empty section (`[title]` and no keys) is the empty style.
		  To change only one key of an entry, write the entry's other keys too, as the
		  presets under examples/themes/ do.
		* Comments and blank lines are skipped, as Q1 reads them; sections may come in any
		  order.
		* Errors, as queries (`has_error`, `error_line`, `error_column`, `error_section`,
		  `error_key`, `error_message`, `error_description`), never exceptions:
		  - an error of the format (Q1): its line and column;
		  - an unknown section name: the line of its `[name]` header (section names are
		    compared exactly, as TOML compares keys);
		  - an error of a style (C2: an unknown field, a bad color, an unknown modifier, a
		    value of the wrong type, a modifier in both lists): the line of its key, and the
		    section and key;
		  - for `load` only: a missing file, a directory, a file that cannot be read, and
		    text that is not UTF-8 (the line of the first bad byte sequence).
		  The first error stops the read. A failed read gives no theme, not a partly filled
		  one: the theme is built only after the whole document is read without an error.

		Files (`load`, `save`): opened as RAW_FILE, so the bytes are exactly the text's UTF-8,
		with LF line ends on every platform (a PLAIN_TEXT_FILE would write CR LF on Windows);
		CR LF in a file is read too (Q1). A missing or unreadable file, or a failed write, is
		an error, not an exception: the status is checked first, and an I/O exception while
		reading or writing is rescued and reported.
		* Safe save: `save` writes the text to `temporary_path` (the path with ".tmp" added)
		  and then renames it over the file, so a failed write leaves the old file whole,
		  never cut short; the temporary file is deleted after a failure. On POSIX the rename
		  is atomic. On Windows the runtime's rename replaces an existing file but is not
		  promised to be atomic.
		* UTF-8: `load` decodes the file's bytes as UTF-8 (RFC 3629) and refuses anything
		  else: a bad or cut byte sequence, an overlong form, a surrogate, a code above
		  U+10FFFF. The error names the line of the first bad sequence.
		* Byte-order mark (decided): `load` skips one UTF-8 BOM (EF BB BF) at the start of
		  the file, since some Windows editors write one; `save` never writes one (TOML files
		  have none). `load_from_string` takes decoded text, so a U+FEFF at its start is an
		  error of the format, as Q1 reads it.

		Writing (`as_text`, `save`): the thirteen sections in the order of `Section_names`,
		each through `{STYLE_TEXT}.put_style`, written by `{TOML_SUBSET_WRITER}.text`: no
		comments, one blank line between sections, LF line ends. The presets are shipped
		as files written this way under examples/themes/ (dark, light, nord, dracula).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_THEME_FILE

create
	make

feature {NONE} -- Initialization

	make
			-- A theme file reader and writer that has done nothing yet.
		do
			create error_section.make_empty
			create error_key.make_empty
			create error_message.make_empty
		ensure
			no_theme: theme = Void
			no_error: not has_error
		end

feature -- Reading

	load_from_string (a_text: READABLE_STRING_GENERAL)
			-- Read `a_text`, a theme file's text: make `theme`, or set the error of the first
			-- thing that is not a theme and leave `theme` Void.
		local
			l_reader: TOML_SUBSET_READER
			l_style_text: STYLE_TEXT
			l_styles: ARRAY [detachable STYLE]
			l_section: TOML_SUBSET_SECTION
			l_index, i: INTEGER
			l_theme: TUI_THEME
		do
			clear
			create l_reader.make
			l_reader.read (a_text)
			if attached l_reader.document as l_document then
				create l_styles.make_filled (Void, 1, Section_names.count)
				create l_style_text.make
				from
					i := 1
				until
					has_error or i > l_document.count
				loop
					l_section := l_document.section (i)
					l_index := section_index (l_section.name)
					if l_index = 0 then
						set_error (l_section.line, 0, l_section.name, "",
							{STRING_32} "unknown section [" + l_section.name + "] (a theme has " + names_text + ")")
					elseif attached l_style_text.parsed_section (l_section) as l_style then
						l_styles [l_index] := l_style
					else
						set_error (l_style_text.error_line, 0, l_section.name, l_style_text.error_key, l_style_text.error_message)
					end
					i := i + 1
				end
				if not has_error then
						-- Only now, from the whole document: a failed read leaves no theme
					l_theme := Defaults
					from
						i := 1
					until
						i > Section_names.count
					loop
						if attached l_styles [i] as l_style then
							set_style (l_theme, i, l_style)
						end
						i := i + 1
					end
					theme := l_theme
				end
			else
				set_error (l_reader.error_line, l_reader.error_column, "", "", l_reader.error_message)
			end
		ensure
			theme_or_error: has_error = (theme = Void)
		end

	load (a_path: READABLE_STRING_GENERAL)
			-- Read the theme file at `a_path` (UTF-8, an optional BOM skipped): make `theme`, or
			-- set the error (a missing or unreadable file, text that is not UTF-8, or an error of
			-- `load_from_string`) and leave `theme` Void.
		require
			path_not_empty: not a_path.is_empty
		local
			l_bytes: detachable STRING_8
		do
			clear
			l_bytes := file_bytes (a_path)
			if attached l_bytes then
				if l_bytes.count >= 3 and then l_bytes.code (1) = 0xEF and then l_bytes.code (2) = 0xBB and then l_bytes.code (3) = 0xBF then
					l_bytes.remove_head (3)
				end
				if attached decoded (l_bytes) as l_text then
					load_from_string (l_text)
				end
			end
		ensure
			theme_or_error: has_error = (theme = Void)
		end

	parsed (a_text: READABLE_STRING_GENERAL): detachable TUI_THEME
			-- `load_from_string (a_text)`, then `theme`
		do
			load_from_string (a_text)
			Result := theme
		ensure
			theme_or_error: has_error = (Result = Void)
			is_theme: Result = theme
		end

	loaded (a_path: READABLE_STRING_GENERAL): detachable TUI_THEME
			-- `load (a_path)`, then `theme`
		require
			path_not_empty: not a_path.is_empty
		do
			load (a_path)
			Result := theme
		ensure
			theme_or_error: has_error = (Result = Void)
			is_theme: Result = theme
		end

feature -- Writing

	as_text (a_theme: TUI_THEME): STRING_32
			-- `a_theme` as a theme file: its thirteen sections in the order of `Section_names`
		require
			representable: is_representable (a_theme)
		local
			l_document: TOML_SUBSET_DOCUMENT
			i: INTEGER
		do
			create l_document
			from
				i := 1
			until
				i > Section_names.count
			loop
				{STYLE_TEXT}.put_style (style (a_theme, i), l_document.put_new (Section_names [i]))
				i := i + 1
			end
			Result := {TOML_SUBSET_WRITER}.text (l_document)
		ensure
			instance_free: class
			reads_back: attached (create {TUI_THEME_FILE}.make).parsed (Result) as l_theme and then l_theme.is_equal (a_theme)
		end

	save (a_theme: TUI_THEME; a_path: READABLE_STRING_GENERAL)
			-- Write `as_text (a_theme)` to the file at `a_path`, in UTF-8 without a BOM,
			-- replacing the file; set the error when it cannot be written. `theme` is Void
			-- afterwards (it is the result of a read).
			-- The text is written to `temporary_path (a_path)` first and then renamed over
			-- `a_path`, so a failed write leaves the file at `a_path` as it was, never cut short.
		require
			representable: is_representable (a_theme)
			path_not_empty: not a_path.is_empty
		local
			l_file, l_temporary: detachable RAW_FILE
			l_failed: BOOLEAN
		do
			if not l_failed then
				clear
				create l_file.make_with_name (a_path)
				if l_file.exists and then not l_file.is_plain then
					set_error (0, 0, "", "", {STRING_32} "cannot write '" + a_path.as_string_32 + "': it is not a plain file")
				elseif l_file.exists and then not l_file.is_writable then
					set_error (0, 0, "", "", {STRING_32} "cannot write '" + a_path.as_string_32 + "': permission denied")
				else
					create l_temporary.make_with_name (temporary_path (a_path))
					l_temporary.open_write
					l_temporary.put_string ({UTF_CONVERTER}.string_32_to_utf_8_string_8 (as_text (a_theme)))
					l_temporary.close
						-- The runtime's rename replaces an existing `a_path`, on Windows too
					l_temporary.rename_file (a_path)
				end
			end
		ensure
			no_theme: theme = Void
		rescue
			if not l_failed then
				l_failed := True
				if attached l_temporary then
					if not l_temporary.is_closed then
						safe_close (l_temporary)
					end
					safe_delete (l_temporary)
				end
				if not has_error then
					set_error (0, 0, "", "", {STRING_32} "cannot write '" + a_path.as_string_32 + "'")
				end
				retry
			end
		end

	temporary_path (a_path: READABLE_STRING_GENERAL): STRING_32
			-- The file `save` writes before renaming it to `a_path`: `a_path` with ".tmp" added,
			-- in the same directory, so the rename does not move the file to another disk.
			-- A file already there with that name is replaced.
		require
			path_not_empty: not a_path.is_empty
		do
			Result := a_path.as_string_32 + {STRING_32} ".tmp"
		ensure
			instance_free: class
		end

feature -- Access

	theme: detachable TUI_THEME
			-- The theme the last read made, or Void after an error, a `save`, or before any read

	error_line: INTEGER
			-- Line of the error (from 1), or 0 when it is not about a line (a file error)

	error_column: INTEGER
			-- Column of the error (from 1), or 0: known only for an error of the format (Q1)

	error_section: STRING_32
			-- The section the error is in, or empty

	error_key: STRING_32
			-- The key the error is about, or empty

	error_message: STRING_32
			-- What the error is (empty when there is none)

	error_description: STRING_32
			-- "line N, column M, section [s], key 'k': message", each part only when known;
			-- empty when there is no error
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
				if not error_section.is_empty then
					if not Result.is_empty then
						Result.append ({STRING_32} ", ")
					end
					Result.append ({STRING_32} "section [")
					Result.append (error_section)
					Result.append_character (']')
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
			-- Did the last read or `save` fail?

	is_representable (a_theme: TUI_THEME): BOOLEAN
			-- Can each style of `a_theme` be printed so that it reads back equal
			-- (`{STYLE_TEXT}.is_representable`)? True for every theme whose styles are built
			-- with STYLE's creation procedures, builders and `patch`, the presets included.
		local
			i: INTEGER
		do
			from
				Result := True
				i := 1
			until
				not Result or i > Section_names.count
			loop
				Result := {STYLE_TEXT}.is_representable (style (a_theme, i))
				i := i + 1
			end
		ensure
			instance_free: class
		end

	is_section_name (a_name: READABLE_STRING_GENERAL): BOOLEAN
			-- Is `a_name` one of `Section_names` (compared exactly)?
		do
			Result := section_index (a_name) > 0
		ensure
			instance_free: class
		end

feature -- Constants

	Section_names: ARRAY [STRING_32]
			-- The sections of a theme file, in the order written: TUI_THEME's semantic styles
		once
			Result := <<{STRING_32} "base", {STRING_32} "primary", {STRING_32} "secondary", {STRING_32} "success",
				{STRING_32} "warning", {STRING_32} "error", {STRING_32} "info", {STRING_32} "highlight",
				{STRING_32} "selection", {STRING_32} "muted", {STRING_32} "border", {STRING_32} "title", {STRING_32} "text">>
		ensure
			instance_free: class
		end

	Defaults: TUI_THEME
			-- The theme whose styles a file's missing sections keep: the dark preset, a new
			-- theme on each call
		do
			Result := {TUI_THEME}.dark
		ensure
			instance_free: class
			is_dark: Result.is_equal ({TUI_THEME}.dark)
		end

feature -- Access: styles by section

	style (a_theme: TUI_THEME; i: INTEGER): STYLE
			-- The style of `a_theme` for section `Section_names [i]`
		require
			valid_index: Section_names.valid_index (i)
		do
			inspect i
			when 1 then Result := a_theme.base
			when 2 then Result := a_theme.primary
			when 3 then Result := a_theme.secondary
			when 4 then Result := a_theme.success
			when 5 then Result := a_theme.warning
			when 6 then Result := a_theme.error
			when 7 then Result := a_theme.info
			when 8 then Result := a_theme.highlight
			when 9 then Result := a_theme.selection
			when 10 then Result := a_theme.muted
			when 11 then Result := a_theme.border
			when 12 then Result := a_theme.title
			else
				Result := a_theme.text
			end
		ensure
			instance_free: class
		end

feature {NONE} -- Implementation

	clear
			-- Forget the last read or save.
		do
			theme := Void
			has_error := False
			error_line := 0
			error_column := 0
			create error_section.make_empty
			create error_key.make_empty
			create error_message.make_empty
		ensure
			no_theme: theme = Void
			no_error: not has_error
		end

	set_error (a_line, a_column: INTEGER; a_section, a_key, a_message: READABLE_STRING_GENERAL)
			-- Set the error `a_message` at `a_line`, `a_column`, in `a_section`, about `a_key`.
		require
			no_error: not has_error
			has_message: not a_message.is_empty
		do
			has_error := True
			theme := Void
			error_line := a_line.max (0)
			error_column := a_column.max (0)
			create error_section.make_from_string_general (a_section)
			create error_key.make_from_string_general (a_key)
			create error_message.make_from_string_general (a_message)
		ensure
			has_error: has_error
			no_theme: theme = Void
		end

	set_style (a_theme: TUI_THEME; i: INTEGER; a_style: STYLE)
			-- Set the style of `a_theme` for section `Section_names [i]` to `a_style`.
		require
			valid_index: Section_names.valid_index (i)
		do
			inspect i
			when 1 then a_theme.set_base (a_style)
			when 2 then a_theme.set_primary (a_style)
			when 3 then a_theme.set_secondary (a_style)
			when 4 then a_theme.set_success (a_style)
			when 5 then a_theme.set_warning (a_style)
			when 6 then a_theme.set_error (a_style)
			when 7 then a_theme.set_info (a_style)
			when 8 then a_theme.set_highlight (a_style)
			when 9 then a_theme.set_selection (a_style)
			when 10 then a_theme.set_muted (a_style)
			when 11 then a_theme.set_border (a_style)
			when 12 then a_theme.set_title (a_style)
			else
				a_theme.set_text (a_style)
			end
		ensure
			set: style (a_theme, i) = a_style
		end

	section_index (a_name: READABLE_STRING_GENERAL): INTEGER
			-- Index of `a_name` in `Section_names`, or 0
		local
			i: INTEGER
		do
			from
				i := 1
			until
				Result > 0 or i > Section_names.count
			loop
				if Section_names [i].same_string_general (a_name) then
					Result := i
				end
				i := i + 1
			end
		ensure
			instance_free: class
			valid: Result = 0 or else Section_names.valid_index (Result)
		end

	names_text: STRING_32
			-- "base, primary, ... and text"
		local
			i: INTEGER
		do
			create Result.make (120)
			from
				i := 1
			until
				i > Section_names.count
			loop
				if i = Section_names.count then
					Result.append ({STRING_32} " and ")
				elseif i > 1 then
					Result.append ({STRING_32} ", ")
				end
				Result.append (Section_names [i])
				i := i + 1
			end
		end

	file_bytes (a_path: READABLE_STRING_GENERAL): detachable STRING_8
			-- The bytes of the file at `a_path`, or Void after setting the error
		require
			no_error: not has_error
		local
			l_file: detachable RAW_FILE
			l_failed: BOOLEAN
		do
			if not l_failed then
				create l_file.make_with_name (a_path)
				if not l_file.exists then
					set_error (0, 0, "", "", {STRING_32} "cannot read '" + a_path.as_string_32 + "': no such file")
				elseif not l_file.is_plain then
					set_error (0, 0, "", "", {STRING_32} "cannot read '" + a_path.as_string_32 + "': it is not a plain file")
				elseif not l_file.is_readable then
					set_error (0, 0, "", "", {STRING_32} "cannot read '" + a_path.as_string_32 + "': permission denied")
				else
					l_file.open_read
					if l_file.count > 0 then
						l_file.read_stream (l_file.count)
						Result := l_file.last_string.twin
					else
						create Result.make_empty
					end
					l_file.close
				end
			else
				Result := Void
			end
		ensure
			bytes_or_error: has_error = (Result = Void)
		rescue
			if not l_failed then
				l_failed := True
				if attached l_file and then not l_file.is_closed then
					safe_close (l_file)
				end
				if not has_error then
					set_error (0, 0, "", "", {STRING_32} "cannot read '" + a_path.as_string_32 + "'")
				end
				retry
			end
		end

	decoded (a_bytes: STRING_8): detachable STRING_32
			-- `a_bytes` decoded as UTF-8, or Void after setting the error with the number of the
			-- first line that is not UTF-8
		require
			no_error: not has_error
		local
			l_start, l_end, l_line: INTEGER
		do
			if is_utf_8 (a_bytes, 1, a_bytes.count) then
				Result := {UTF_CONVERTER}.utf_8_string_8_to_string_32 (a_bytes)
			else
				from
					l_start := 1
					l_line := 1
				until
					has_error
				loop
					l_end := a_bytes.index_of ('%N', l_start)
					if l_end = 0 then
						l_end := a_bytes.count + 1
					end
					if not is_utf_8 (a_bytes, l_start, l_end - 1) or l_end > a_bytes.count then
							-- The bad line (the last line is bad when no earlier one is)
						set_error (l_line, 0, "", "", "the text is not valid UTF-8")
					end
					l_start := l_end + 1
					l_line := l_line + 1
				end
			end
		ensure
			text_or_error: has_error = (Result = Void)
		end

	is_utf_8 (a_bytes: READABLE_STRING_8; a_start, a_end: INTEGER): BOOLEAN
			-- Are the bytes `a_start` .. `a_end` of `a_bytes` UTF-8 as RFC 3629 defines it: no
			-- overlong form, no surrogate, nothing above U+10FFFF, no cut sequence?
			-- (base's `{UTF_CONVERTER}.is_valid_utf_8_string_8` accepts all three.)
		require
			valid_start: a_start >= 1
			valid_end: a_end <= a_bytes.count and a_end >= a_start - 1
		local
			i, l_more: INTEGER
			c, l_code, l_min: NATURAL_32
		do
			from
				Result := True
				i := a_start
			until
				not Result or i > a_end
			loop
				c := a_bytes.code (i)
				if c <= 0x7F then
					l_more := 0
					l_code := c
					l_min := 0
				elseif (c & 0xE0) = 0xC0 then
					l_more := 1
					l_code := c & 0x1F
					l_min := 0x80
				elseif (c & 0xF0) = 0xE0 then
					l_more := 2
					l_code := c & 0x0F
					l_min := 0x800
				elseif (c & 0xF8) = 0xF0 then
					l_more := 3
					l_code := c & 0x07
					l_min := 0x10000
				else
					Result := False
				end
				if Result then
					if i + l_more > a_end then
						Result := False
					else
						from
						until
							not Result or l_more = 0
						loop
							i := i + 1
							c := a_bytes.code (i)
							Result := (c & 0xC0) = 0x80
							l_code := (l_code |<< 6) | (c & 0x3F)
							l_more := l_more - 1
						end
						Result := Result and l_code >= l_min and l_code <= 0x10FFFF
							and not (0xD800 <= l_code and l_code <= 0xDFFF)
					end
				end
				i := i + 1
			end
		ensure
			instance_free: class
		end

	safe_close (a_file: FILE)
			-- Close `a_file`, ignoring a failure to close it.
		local
			l_tried: BOOLEAN
		do
			if not l_tried and then not a_file.is_closed then
				a_file.close
			end
		rescue
			l_tried := True
			retry
		end

	safe_delete (a_file: FILE)
			-- Delete `a_file` when it is a plain file, ignoring a failure to delete it.
		require
			closed: a_file.is_closed
		local
			l_tried: BOOLEAN
		do
			if not l_tried and then a_file.exists and then a_file.is_plain then
				a_file.delete
			end
		rescue
			l_tried := True
			retry
		end

invariant
	error_has_message: has_error = not error_message.is_empty
	error_has_no_theme: has_error implies theme = Void
	no_error_no_details: not has_error implies (error_line = 0 and error_column = 0 and error_section.is_empty and error_key.is_empty)
	line_not_negative: error_line >= 0
	column_not_negative: error_column >= 0

end
