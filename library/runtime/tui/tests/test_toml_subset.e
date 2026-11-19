note
	description: "[
		P2 item Q1: the theme file format (review/p2_terminal_widgets_plan.md), a line-based
		subset of TOML 1.0 read by TOML_SUBSET_READER and printed by TOML_SUBSET_WRITER.

		Every text these tests read without an error is a valid TOML 1.0 document with the
		same meaning. The comment of each test names the TOML 1.0 rules (spec sections at
		toml.io/en/v1.0.0) that the accepted texts follow. The valid texts were also read by
		Python's `tomllib` (TOML 1.0) to the same tables, outside the suite. The error cases
		are either invalid TOML too, or valid TOML the subset leaves out on purpose (root
		keys, literal strings, numbers, booleans, inline tables, nested and multi-line
		arrays, quoted and dotted keys, nested tables); each comment says which.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_TOML_SUBSET

inherit
	EQA_TEST_SET

feature -- Reading

	test_reads_theme_sections
			-- The Q1 example: sections with string and array values, in order.
			-- TOML: "Table" (`[name]`), "Key/Value Pair", "String" (basic), "Array".
		local
			l_document: TOML_SUBSET_DOCUMENT
		do
			l_document := read_ok ("theme", "[primary]%Nfg = %"#88c0d0%"%Nbg = %"reset%"%Nmodifiers = [%"bold%", %"italic%"]%N%N[muted]%Nfg = %"darkgray%"%N")
			assert ("two sections", l_document.count = 2)
			assert ("first primary", l_document.section (1).name.same_string ("primary"))
			assert ("second muted", l_document.section (2).name.same_string ("muted"))
			if attached l_document ["primary"] as l_primary then
				assert ("three keys", l_primary.count = 3)
				assert ("key order", l_primary.key (1).same_string ("fg") and l_primary.key (2).same_string ("bg") and l_primary.key (3).same_string ("modifiers"))
				assert_string_value ("fg", l_primary ["fg"], "#88c0d0")
				assert_string_value ("bg", l_primary ["bg"], "reset")
				if attached l_primary ["modifiers"] as l_modifiers then
					assert ("array", l_modifiers.is_array and l_modifiers.count = 2)
					assert ("bold", l_modifiers [1].same_string ("bold"))
					assert ("italic", l_modifiers [2].same_string ("italic"))
				else
					assert ("modifiers", False)
				end
				assert ("no underline", not l_primary.has_key ("underline_color") and l_primary ["underline_color"] = Void)
			else
				assert ("primary", False)
			end
			assert ("no base", not l_document.has_section ("base") and l_document ["base"] = Void)
		end

	test_comments_blank_lines_and_whitespace
			-- Full-line and trailing comments, blank lines, spaces and tabs around every
			-- token, an indented header with spaces inside its brackets, CR LF line ends, a
			-- last line without a line end, an empty section, an empty array and a trailing
			-- comma. TOML: "Comment", "Spec" (whitespace is tab or space; newline is LF or
			-- CRLF), "Table" (whitespace around the name is ignored; indentation is allowed;
			-- an empty table is valid), "Array" (empty arrays; a terminating comma is
			-- permitted).
		local
			l_document: TOML_SUBSET_DOCUMENT
		do
			l_document := read_ok ("layout", "# A theme%N%N   # indented comment%N[primary]   # the main colour%Nfg = %"#88c0d0%"   # frost%N%T%Tbg%T=%T%"reset%"%T%N%N  [ muted ]%T# spaced header%R%Nmodifiers=[]%R%Nremove = [ %"dim%" , %"bold%",  ]%R%N[empty-section_1]%N# last line without a line end")
			assert ("three sections", l_document.count = 3)
			if attached l_document ["primary"] as l_primary then
				assert_string_value ("fg", l_primary ["fg"], "#88c0d0")
				assert_string_value ("bg", l_primary ["bg"], "reset")
			else
				assert ("primary", False)
			end
			if attached l_document ["muted"] as l_muted then
				assert ("empty array", attached l_muted ["modifiers"] as l_value and then (l_value.is_array and l_value.count = 0))
				assert ("trailing comma", attached l_muted ["remove"] as l_value and then (l_value.is_array and l_value.count = 2 and l_value [2].same_string ("bold")))
			else
				assert ("muted", False)
			end
			assert ("empty section", attached l_document ["empty-section_1"] as l_empty and then l_empty.count = 0)
			assert ("empty text", read_ok ("empty", "").count = 0)
			assert ("only comments", read_ok ("comments", "# one%N%N# two%N").count = 0)
			assert ("only blank lines", read_ok ("blank", "%N  %N%T%N").count = 0)
		end

	test_reads_strings_and_escapes
			-- Every TOML 1.0 basic string escape, a raw tab, raw non-ASCII text, and "#", "]",
			-- "," and "=" inside strings (not comments or separators). TOML: "String" (basic
			-- strings: `\b \t \n \f \r \" \\ \uXXXX \UXXXXXXXX`; tab need not be escaped).
		local
			l_document: TOML_SUBSET_DOCUMENT
			l_expected: STRING_32
		do
			l_document := read_ok ("escapes", "[s]%Na = %"q\%"b\\t\tn\nf\fr\rB\b%"%Nb = %"\u00e9\u00C9\U0001F600%"%Nc = %"tab%There%"%Nd = %"# not a comment, ] = %" # a comment%Ne = [%"]%", %",%", %"#%"]%Nf = %"%"%Ng = %"%/233/t%/233/%"%N")
			if attached l_document ["s"] as l_section then
				assert_string_value ("simple escapes", l_section ["a"], {STRING_32} "q%"b\t%Tn%Nf%/12/r%RB%/8/")
				create l_expected.make_empty
				l_expected.append_code (0xE9)
				l_expected.append_code (0xC9)
				l_expected.append_code (0x1F600)
				assert_string_value ("unicode escapes", l_section ["b"], l_expected)
				assert_string_value ("raw tab", l_section ["c"], "tab%There")
				assert_string_value ("hash in string", l_section ["d"], "# not a comment, ] = ")
				assert ("separators in array strings", attached l_section ["e"] as l_value and then
					(l_value.count = 3 and l_value [1].same_string ("]") and l_value [2].same_string (",") and l_value [3].same_string ("#")))
				assert_string_value ("empty string", l_section ["f"], "")
				assert_string_value ("raw non-ascii", l_section ["g"], {STRING_32} "%/233/t%/233/")
			else
				assert ("section s", False)
			end
		end

	test_keys_are_bare_and_exact
			-- Bare keys of letters, digits, "_" and "-", including all-digit ones, compared
			-- exactly (case matters). TOML: "Keys" (bare keys `A-Za-z0-9_-`; a bare key of
			-- digits only is allowed and is a string; keys are case-sensitive).
		local
			l_document: TOML_SUBSET_DOCUMENT
		do
			l_document := read_ok ("keys", "[Theme-2_b]%NFG = %"a%"%Nfg = %"b%"%N1234 = %"c%"%N_-_ = %"d%"%N")
			assert ("name", l_document.has_section ("Theme-2_b") and not l_document.has_section ("theme-2_b"))
			if attached l_document ["Theme-2_b"] as l_section then
				assert ("four keys", l_section.count = 4)
				assert_string_value ("FG", l_section ["FG"], "a")
				assert_string_value ("fg", l_section ["fg"], "b")
				assert_string_value ("digits", l_section ["1234"], "c")
				assert_string_value ("marks", l_section ["_-_"], "d")
			end
			assert ("valid key", {TOML_SUBSET_SECTION}.is_valid_key ("a-B_9"))
			assert ("empty key", not {TOML_SUBSET_SECTION}.is_valid_key (""))
			assert ("dotted key", not {TOML_SUBSET_SECTION}.is_valid_key ("a.b"))
			assert ("space key", not {TOML_SUBSET_SECTION}.is_valid_key ("a b"))
			assert ("non-ascii key", not {TOML_SUBSET_SECTION}.is_valid_key ({STRING_32} "%/233/"))
		end

feature -- Errors

	test_structure_errors
			-- Lines that are not a header, a key/value pair, a comment or blank, each with its
			-- line and column. Invalid TOML too: `[]`, `[a`, `[a b]`, text after a header or
			-- value, a key without "=" or value, a line that is only "=". Valid TOML left out
			-- of the subset: a key before any section (root table), `[a.b]` (nested table),
			-- `[[a]]` (array of tables), quoted and dotted keys.
		do
			assert_error ("root key", "# theme%Nfg = %"red%"%N", 2, 1, "outside a section")
			assert_error ("empty header", "[]", 1, 2, "expected a section name")
			assert_error ("unclosed header", "[a", 1, 3, "expected ']'")
			assert_error ("two names", "[a b]", 1, 4, "expected ']'")
			assert_error ("nested table", "[a.b]", 1, 3, "nested tables")
			assert_error ("array of tables", "[a]%N[[b]]", 2, 1, "arrays of tables")
			assert_error ("quoted section", "[%"a%"]", 1, 2, "quoted keys")
			assert_error ("quoted key", "[a]%N%"fg%" = %"red%"", 2, 1, "quoted keys")
			assert_error ("literal quoted key", "[a]%N'fg' = %"red%"", 2, 1, "quoted keys")
			assert_error ("dotted key", "[a]%Nfg.x = %"red%"", 2, 3, "dotted keys")
			assert_error ("no equals", "[a]%Nfg %"red%"", 2, 4, "expected '='")
			assert_error ("no value", "[a]%Nfg =", 2, 5, "missing value")
			assert_error ("comment for value", "[a]%Nfg = # red", 2, 6, "missing value")
			assert_error ("only equals", "[a]%N= %"red%"", 2, 1, "expected a key")
			assert_error ("text after header", "[a] x", 1, 5, "after the section header")
			assert_error ("text after value", "[a]%Nfg = %"red%" x", 2, 12, "after the value")
			assert_error ("two values", "[a]%Nm = [%"a%"] [%"b%"]", 2, 11, "after the value")
		end

	test_value_errors
			-- Values that are not a basic string or a one-line array of basic strings. Valid
			-- TOML that the subset leaves out: numbers, booleans, dates, literal and
			-- multi-line strings, inline tables, nested and mixed arrays, an array over
			-- several lines. Invalid TOML too: a bare word, an empty or leading item, items
			-- without ",", an array not closed on its line.
		do
			assert_error ("integer", "[a]%Nsize = 3", 2, 8, "double-quoted string or an array")
			assert_error ("boolean", "[a]%Nbold = true", 2, 8, "double-quoted string or an array")
			assert_error ("date", "[a]%Nwhen = 2026-10-27", 2, 8, "double-quoted string or an array")
			assert_error ("bare word", "[a]%Nfg = red", 2, 6, "double-quoted string or an array")
			assert_error ("literal string", "[a]%Nfg = 'red'", 2, 6, "literal strings")
			assert_error ("multi-line string", "[a]%Nfg = %"%"%"red%"%"%"", 2, 6, "multi-line strings")
			assert_error ("inline table", "[a]%Nfg = { r = %"1%" }", 2, 6, "inline tables")
			assert_error ("nested array", "[a]%Nm = [[%"a%"]]", 2, 6, "nested arrays")
			assert_error ("number in array", "[a]%Nm = [%"a%", 1]", 2, 11, "array item must be a double-quoted string")
			assert_error ("literal in array", "[a]%Nm = ['a']", 2, 6, "literal strings")
			assert_error ("empty item", "[a]%Nm = [%"a%", , %"b%"]", 2, 11, "array item must be a double-quoted string")
			assert_error ("leading comma", "[a]%Nm = [,]", 2, 6, "array item must be a double-quoted string")
			assert_error ("no comma", "[a]%Nm = [%"a%" %"b%"]", 2, 10, "expected ',' or ']'")
			assert_error ("multi-line array", "[a]%Nm = [%N  %"bold%"%N]", 2, 5, "unterminated array")
			assert_error ("unterminated array", "[a]%Nm = [%"a%",", 2, 5, "unterminated array")
			assert_error ("comment in array", "[a]%Nm = [%"a%" # c", 2, 5, "unterminated array")
		end

	test_string_errors
			-- Bad basic strings. Invalid TOML too: an unterminated string, a line ending in
			-- "\", an unknown escape, a `\u` with too few hex digits, a `\u` / `\U` that is
			-- a surrogate or above U+10FFFF, a raw control character ("String", "Comment").
		do
			assert_error ("unterminated", "[a]%Nfg = %"red%N", 2, 6, "unterminated string")
			assert_error ("unterminated in array", "[a]%Nm = [%"bold]", 2, 6, "unterminated string")
			assert_error ("line ends with backslash", "[a]%Nfg = %"ab\", 2, 9, "unterminated string")
			assert_error ("bad escape", "[a]%Nfg = %"r\qd%"", 2, 8, "invalid escape \q")
			assert_error ("escape e", "[a]%Nfg = %"\e%"", 2, 7, "invalid escape \e")
			assert_error ("escape x", "[a]%Nfg = %"\x41%"", 2, 7, "invalid escape \x")
			assert_error ("short u", "[a]%Nfg = %"\u12%"", 2, 7, "needs 4 hex digits")
			assert_error ("short U", "[a]%Nfg = %"\U0001F60%"", 2, 7, "needs 8 hex digits")
			assert_error ("not hex", "[a]%Nfg = %"\u12G4%"", 2, 7, "needs 4 hex digits")
			assert_error ("surrogate", "[a]%Nfg = %"\uD800%"", 2, 7, "not a Unicode scalar value")
			assert_error ("too high", "[a]%Nfg = %"\U00110000%"", 2, 7, "not a Unicode scalar value")
			assert_error ("all ones", "[a]%Nfg = %"\UFFFFFFFF%"", 2, 7, "not a Unicode scalar value")
			assert_error ("control in string", "[a]%Nfg = %"r%/1/d%"", 2, 8, "U+0001")
			assert_error ("DEL in comment", "[a] # a%/127/", 1, 8, "U+007F")
			assert_error ("lone CR", "[a]%Rfg = %"red%"", 1, 4, "U+000D")
			assert_error ("CR at the end", "[a]%Nfg = %"red%"%R", 2, 11, "U+000D")
			assert_error ("VT in comment", "[a]%N# x%/11/", 2, 4, "U+000B")
		end

	test_duplicate_errors
			-- A section or a key defined twice. Invalid TOML too ("Table": defining a table
			-- more than once; "Keys": defining a key multiple times). Keys are per section,
			-- so the same key in two sections is fine.
		do
			assert_error ("duplicate section", "[a]%N[b]%N%N[a]%N", 4, 2, "duplicate section [a]")
			assert_error ("duplicate key", "[a]%Nfg = %"red%"%N  fg = %"blue%"%N", 3, 3, "duplicate key 'fg' in section [a]")
			assert_error ("duplicate array key", "[a]%Nm = []%Nm = [%"bold%"]", 3, 1, "duplicate key 'm'")
			assert ("same key in two sections", read_ok ("two", "[a]%Nfg = %"red%"%N[b]%Nfg = %"red%"%N").count = 2)
		end

	test_error_line_numbers
			-- Line numbers count every line: blank, comment, CR LF ended, and the lines
			-- before the error that were read; the first error stops the read.
		do
			assert_error ("after blanks", "%N%N# c%N[a]%N%Nfg = 1%N", 6, 6, "double-quoted string")
			assert_error ("crlf lines", "[a]%R%N%R%N# c%R%Nfg = 1%R%N", 4, 6, "double-quoted string")
			assert_error ("first error wins", "[a]%Nfg = 1%Nbg = 2%N[a]%N", 2, 6, "double-quoted string")
		end

	test_failed_read_has_no_document
			-- A failed read leaves no document, not even the sections before the error, and
			-- a later good read clears the error.
		local
			l_reader: TOML_SUBSET_READER
		do
			create l_reader.make
			assert ("fresh", not l_reader.has_error and l_reader.document = Void and l_reader.error_line = 0)
			l_reader.read ("[a]%Nfg = %"red%"%N")
			assert ("good", not l_reader.has_error and attached l_reader.document)
			l_reader.read ("[a]%Nfg = %"red%"%N[b]%Nbg = 1%N")
			assert ("bad", l_reader.has_error and l_reader.document = Void)
			assert ("position", l_reader.error_line = 4 and l_reader.error_column = 6)
			assert ("description", l_reader.error_description.starts_with ({STRING_32} "line 4, column 6: "))
			assert ("parsed void", l_reader.parsed ("[a]%N[a]") = Void and l_reader.has_error)
			l_reader.read ("[b]")
			assert ("good again", not l_reader.has_error and l_reader.error_line = 0 and l_reader.error_column = 0)
			assert ("message cleared", l_reader.error_message.is_empty and l_reader.error_description.is_empty)
			assert ("document", attached l_reader.document as l_document and then l_document.has_section ("b"))
		end

feature -- Writing

	test_writer_output
			-- The writer's exact text: sections in order, one blank line between them, keys
			-- in order, `key = "text"`, `key = ["a", "b"]`, `key = []`, LF line ends and a
			-- final LF; an empty document is the empty text.
		local
			l_document: TOML_SUBSET_DOCUMENT
			l_section: TOML_SUBSET_SECTION
		do
			create l_document
			assert ("empty document", {TOML_SUBSET_WRITER}.text (l_document).is_empty)
			l_section := l_document.put_new ("primary")
			l_section.put_string ("fg", "#88c0d0")
			l_section.put_array ("modifiers", <<"bold", "italic">>)
			l_section := l_document.put_new ("muted")
			l_section.put_array ("remove", create {ARRAYED_LIST [STRING]}.make (0))
			l_document.put (create {TOML_SUBSET_SECTION}.make ("empty"))
			assert_same_text ("document", {TOML_SUBSET_WRITER}.text (l_document),
				"[primary]%Nfg = %"#88c0d0%"%Nmodifiers = [%"bold%", %"italic%"]%N%N[muted]%Nremove = []%N%N[empty]%N")
			assert ("reads back", attached (create {TOML_SUBSET_READER}.make).parsed ({TOML_SUBSET_WRITER}.text (l_document)) as l_read and then l_read.is_equal (l_document))
		end

	test_writer_escapes
			-- `quoted`: `"` and `\` escaped, the five short escapes, other control characters
			-- as `\u00XX` (upper-case hex), everything else as it is.
		do
			assert_same_text ("plain", {TOML_SUBSET_WRITER}.quoted ("red"), "%"red%"")
			assert_same_text ("empty", {TOML_SUBSET_WRITER}.quoted (""), "%"%"")
			assert_same_text ("quote and backslash", {TOML_SUBSET_WRITER}.quoted ("a%"b\c"), "%"a\%"b\\c%"")
			assert_same_text ("short escapes", {TOML_SUBSET_WRITER}.quoted ("%/8/%T%N%/12/%R"), "%"\b\t\n\f\r%"")
			assert_same_text ("other controls", {TOML_SUBSET_WRITER}.quoted ("%/0/%/1/%/11/%/27/%/31/%/127/"), "%"\u0000\u0001\u000B\u001B\u001F\u007F%"")
			assert_same_text ("non-ascii raw", {TOML_SUBSET_WRITER}.quoted ({STRING_32} "%/233/%/128512/"), {STRING_32} "%"%/233/%/128512/%"")
			assert_same_text ("hash raw", {TOML_SUBSET_WRITER}.quoted ("# ] , ="), "%"# ] , =%"")
		end

	test_escaping_round_trip
			-- Every code U+0000 .. U+00FF and some high scalar values (U+D7FF, U+E000,
			-- U+FFFF, U+1F600, U+10FFFF), as a string and as array items, read back equal.
		local
			l_document: TOML_SUBSET_DOCUMENT
			l_section: TOML_SUBSET_SECTION
			l_all: STRING_32
			l_items: ARRAYED_LIST [STRING_32]
			i: NATURAL_32
		do
			create l_all.make (300)
			create l_items.make (300)
			from
				i := 0
			until
				i > 0xFF
			loop
				l_all.append_code (i)
				l_items.extend (create {STRING_32}.make_filled (i.to_character_32, 1))
				i := i + 1
			end
			across <<0xD7FF, 0xE000, 0xFFFF, 0x1F600, 0x10FFFF>> as l_code loop
				l_all.append_code (l_code.to_natural_32)
			end
			create l_document
			l_section := l_document.put_new ("all")
			l_section.put_string ("text", l_all)
			l_section.put_array ("items", l_items)
			l_section.put_string ("empty", "")
			assert_round_trip ("all codes", l_document)
		end

	test_read_write_read
			-- A text with comments, odd spacing and a trailing comma is written in the
			-- canonical form; that form reads back to the same document and writes again to
			-- the same text.
		local
			l_text: STRING_32
		do
			if attached (create {TOML_SUBSET_READER}.make).parsed ("# c%N  [ b ]  # c%N%Tm=[ %"x%" ,]%Nfg  =  %"\u0041\t%" # c%N[a]%N") as l_document then
				l_text := {TOML_SUBSET_WRITER}.text (l_document)
				assert_same_text ("canonical", l_text, "[b]%Nm = [%"x%"]%Nfg = %"A\t%"%N%N[a]%N")
				assert_round_trip ("document", l_document)
				if attached (create {TOML_SUBSET_READER}.make).parsed (l_text) as l_again then
					assert_same_text ("stable", {TOML_SUBSET_WRITER}.text (l_again), l_text)
				else
					assert ("reads", False)
				end
			else
				assert ("parsed", False)
			end
		end

feature -- Document

	test_document_equality_is_ordered
			-- Equal documents have the same sections and keys in the same order with equal
			-- values; a string is not a one-item array.
		local
			l_a, l_b: TOML_SUBSET_DOCUMENT
		do
			l_a := read_ok ("a", "[x]%Nfg = %"red%"%Nbg = %"blue%"%N[y]%N")
			l_b := read_ok ("b", "[x]%Nfg = %"red%"   # same%Nbg = %"blue%"%N%N[y]%N")
			assert ("equal", l_a.is_equal (l_b))
			assert ("key order", not l_a.is_equal (read_ok ("c", "[x]%Nbg = %"blue%"%Nfg = %"red%"%N[y]%N")))
			assert ("section order", not l_a.is_equal (read_ok ("d", "[y]%N[x]%Nfg = %"red%"%Nbg = %"blue%"%N")))
			assert ("value", not l_a.is_equal (read_ok ("e", "[x]%Nfg = %"red%"%Nbg = %"Blue%"%N[y]%N")))
			assert ("string vs array", not (create {TOML_SUBSET_VALUE}.make_string ("a")).is_equal (create {TOML_SUBSET_VALUE}.make_array (<<"a">>)))
			assert ("array order", not (create {TOML_SUBSET_VALUE}.make_array (<<"a", "b">>)).is_equal (create {TOML_SUBSET_VALUE}.make_array (<<"b", "a">>)))
			assert ("value out", (create {TOML_SUBSET_VALUE}.make_array (<<"a", "b">>)).out.same_string ("[%"a%", %"b%"]"))
		end

	test_values_are_immutable
			-- `string_value`, `item` and `array_value` give new strings, so changing them does
			-- not change the value.
		local
			l_value: TOML_SUBSET_VALUE
			l_list: ARRAYED_LIST [STRING_32]
		do
			create l_value.make_string ("red")
			l_value.string_value.append ({STRING_32} "x")
			assert ("string kept", l_value.string_value.same_string ("red"))
			create l_value.make_array (<<"a", "b">>)
			l_value [1].append ({STRING_32} "x")
			l_list := l_value.array_value
			l_list.first.append ({STRING_32} "y")
			l_list.wipe_out
			assert ("array kept", l_value.count = 2 and l_value [1].same_string ("a"))
		end

	test_preconditions
			-- Building a document refuses what the format cannot hold: a key that is not a
			-- bare key, a duplicate key or section, and text with a surrogate code.
		local
			l_document: TOML_SUBSET_DOCUMENT
			l_section: TOML_SUBSET_SECTION
			l_surrogate: STRING_32
		do
			create l_document
			l_section := l_document.put_new ("a")
			l_section.put_string ("fg", "red")
			create l_surrogate.make_empty
			l_surrogate.append_code (0xD800)
			assert ("surrogate invalid", not {TOML_SUBSET_VALUE}.is_valid_text (l_surrogate))
			assert ("bad name", precondition_raised (agent make_section ("a b"), "valid_name"))
			assert ("duplicate section", precondition_raised (agent l_document.put_new ("a"), "new_name"))
			assert ("duplicate put", precondition_raised (agent l_document.put (create {TOML_SUBSET_SECTION}.make ("a")), "new_name"))
			assert ("bad key", precondition_raised (agent l_section.put_string ("f.g", "red"), "valid_key"))
			assert ("duplicate key", precondition_raised (agent l_section.put_string ("fg", "blue"), "new_key"))
			assert ("surrogate text", precondition_raised (agent l_section.put_string ("bg", l_surrogate), "valid_text"))
			assert ("surrogate item", precondition_raised (agent l_section.put_array ("m", <<l_surrogate>>), "valid_items"))
			assert ("unchanged", l_section.count = 1 and l_document.count = 1)
		end

	test_lines_are_recorded
			-- A read section knows the line of its header and of each key (blank, comment
			-- and CR LF lines counted), for errors found later (C2, C3). Equality ignores the
			-- lines, and a section made in code has line 0.
		local
			l_document: TOML_SUBSET_DOCUMENT
			l_made: TOML_SUBSET_SECTION
		do
			l_document := read_ok ("lines", "# theme%N%N[primary]%Nfg = %"red%"%R%N# c%N%Nbg = %"blue%"%N[muted]%N")
			if attached l_document ["primary"] as l_primary and attached l_document ["muted"] as l_muted then
				assert ("header line", l_primary.line = 3 and l_muted.line = 8)
				assert ("key lines", l_primary.key_line (1) = 4 and l_primary.key_line (2) = 7)
				create l_made.make ("primary")
				l_made.put_string ("fg", "red")
				l_made.put_string ("bg", "blue")
				assert ("made in code", l_made.line = 0 and l_made.key_line (1) = 0)
				assert ("equality ignores lines", l_made.is_equal (l_primary))
			else
				assert ("sections", False)
			end
		end

feature {NONE} -- Helpers

	read_ok (a_tag: STRING; a_text: READABLE_STRING_GENERAL): TOML_SUBSET_DOCUMENT
			-- The document `a_text` reads to; fails the test when it has an error.
		local
			l_reader: TOML_SUBSET_READER
		do
			create l_reader.make
			l_reader.read (a_text)
			if attached l_reader.document as l_document then
				Result := l_document
			else
				assert (a_tag + " reads: " + utf_8 (l_reader.error_description), False)
				create Result
			end
		end

	assert_error (a_tag: STRING; a_text: READABLE_STRING_GENERAL; a_line, a_column: INTEGER; a_fragment: READABLE_STRING_GENERAL)
			-- Check that `a_text` is refused at `a_line`, `a_column`, with a message that
			-- holds `a_fragment`, and gives no document.
		local
			l_reader: TOML_SUBSET_READER
		do
			create l_reader.make
			l_reader.read (a_text)
			assert (a_tag + " has error", l_reader.has_error)
			assert (a_tag + " no document", l_reader.document = Void)
			assert (a_tag + " at " + a_line.out + ":" + a_column.out + ", got " + utf_8 (l_reader.error_description),
				l_reader.error_line = a_line and l_reader.error_column = a_column)
			assert (a_tag + " message: " + utf_8 (l_reader.error_message), l_reader.error_message.has_substring (a_fragment))
		end

	assert_string_value (a_tag: STRING; a_value: detachable TOML_SUBSET_VALUE; a_expected: READABLE_STRING_GENERAL)
			-- Check that `a_value` is the string `a_expected`.
		do
			assert (a_tag, attached a_value as l_value and then (l_value.is_string and then l_value.string_value.same_string_general (a_expected)))
		end

	assert_same_text (a_tag: STRING; a_actual, a_expected: READABLE_STRING_GENERAL)
			-- Check that `a_actual` is `a_expected`.
		do
			assert (a_tag + ": " + utf_8 (a_actual), a_actual.same_string (a_expected))
		end

	assert_round_trip (a_tag: STRING; a_document: TOML_SUBSET_DOCUMENT)
			-- Check that the written `a_document` reads back equal.
		do
			assert (a_tag + " reads back", attached (create {TOML_SUBSET_READER}.make).parsed ({TOML_SUBSET_WRITER}.text (a_document)) as l_read and then l_read.is_equal (a_document))
		end

	utf_8 (a_text: READABLE_STRING_GENERAL): STRING_8
			-- `a_text` in UTF-8, for messages
		do
			Result := {UTF_CONVERTER}.utf_32_string_to_utf_8_string_8 (a_text.to_string_32)
		end

	make_section (a_name: READABLE_STRING_GENERAL)
			-- Create a section named `a_name` (for `precondition_raised`).
		local
			l_section: TOML_SUBSET_SECTION
		do
			create l_section.make (a_name)
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
