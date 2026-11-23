note
	description: "[
		P2 item C1: COLOR from and to text (review/p2_terminal_widgets_plan.md).
		The `test_ratatui_*` cases are the `FromStr` and `Display` tests of Ratatui
		ratatui-core/src/style/color.rs. Ratatui's named colors are EiffelTUI's ANSI colors
		0 .. 15 and `Indexed (n)` is the indexed kind, so the names map as `ansi`: Ratatui's
		`Gray` is ANSI 7, `DarkGray` ANSI 8 and `White` ANSI 15.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_COLOR_FROM_STRING

inherit
	EQA_TEST_SET

feature -- Ratatui color.rs

	test_ratatui_from_rgb_color
			-- Ratatui `from_rgb_color`: "#FF0000" is Rgb (255, 0, 0).
		do
			assert_color ("#FF0000", "#FF0000", {COLOR}.rgb (255, 0, 0))
		end

	test_ratatui_from_indexed_color
			-- Ratatui `from_indexed_color`: "10" is Indexed (10), not the ANSI color 10.
		do
			assert_color ("10", "10", create {COLOR}.make_indexed (10))
			assert ("not ansi", not (create {COLOR}.make_from_string ("10")).is_ansi)
		end

	test_ratatui_from_ansi_color
			-- Ratatui `from_ansi_color`: the 17 names, then the aliases (bright = light,
			-- grey = silver = gray, light black = dark gray, light white = light gray = white),
			-- with spaces, dashes and underscores ignored.
		do
			assert ("reset", (create {COLOR}.make_from_string ("reset")).is_reset)
			assert_color ("black", "black", ansi (0))
			assert_color ("red", "red", ansi (1))
			assert_color ("green", "green", ansi (2))
			assert_color ("yellow", "yellow", ansi (3))
			assert_color ("blue", "blue", ansi (4))
			assert_color ("magenta", "magenta", ansi (5))
			assert_color ("cyan", "cyan", ansi (6))
			assert_color ("gray", "gray", ansi (7))
			assert_color ("darkgray", "darkgray", ansi (8))
			assert_color ("lightred", "lightred", ansi (9))
			assert_color ("lightgreen", "lightgreen", ansi (10))
			assert_color ("lightyellow", "lightyellow", ansi (11))
			assert_color ("lightblue", "lightblue", ansi (12))
			assert_color ("lightmagenta", "lightmagenta", ansi (13))
			assert_color ("lightcyan", "lightcyan", ansi (14))
			assert_color ("white", "white", ansi (15))

				-- aliases
			assert_color ("lightblack", "lightblack", ansi (8))
			assert_color ("lightwhite", "lightwhite", ansi (15))
			assert_color ("lightgray", "lightgray", ansi (15))
				-- silver = grey = gray
			assert_color ("grey", "grey", ansi (7))
			assert_color ("silver", "silver", ansi (7))
				-- spaces are ignored
			assert_color ("light black", "light black", ansi (8))
			assert_color ("light white", "light white", ansi (15))
			assert_color ("light gray", "light gray", ansi (15))
				-- dashes are ignored
			assert_color ("light-black", "light-black", ansi (8))
			assert_color ("light-white", "light-white", ansi (15))
			assert_color ("light-gray", "light-gray", ansi (15))
				-- underscores are ignored
			assert_color ("light_black", "light_black", ansi (8))
			assert_color ("light_white", "light_white", ansi (15))
			assert_color ("light_gray", "light_gray", ansi (15))
				-- bright = light
			assert_color ("bright-black", "bright-black", ansi (8))
			assert_color ("bright-white", "bright-white", ansi (15))
			assert_color ("brightblack", "brightblack", ansi (8))
			assert_color ("brightwhite", "brightwhite", ansi (15))
		end

	test_ratatui_from_invalid_colors
			-- Ratatui `from_invalid_colors`: not a color, seven characters without "#", a
			-- leading space, too many hex digits, a crab between the digits (seven bytes in
			-- UTF-8, four characters here), and two typos.
		do
			assert_invalid ("invalid_color")
			assert_invalid ("abcdef0")
			assert_invalid (" bcdefa")
			assert_invalid ("#abcdef00")
			assert_invalid ({STRING_32} "#1%/0x1F980/2")
			assert_invalid ("resets")
			assert_invalid ("lightblackk")
		end

	test_ratatui_display
			-- Ratatui `display`: the names in CamelCase, the index as a number, "#RRGGBB" in
			-- upper case, and "Reset".
		do
			assert_string ("black", ansi (0), "Black")
			assert_string ("red", ansi (1), "Red")
			assert_string ("green", ansi (2), "Green")
			assert_string ("yellow", ansi (3), "Yellow")
			assert_string ("blue", ansi (4), "Blue")
			assert_string ("magenta", ansi (5), "Magenta")
			assert_string ("cyan", ansi (6), "Cyan")
			assert_string ("gray", ansi (7), "Gray")
			assert_string ("dark gray", ansi (8), "DarkGray")
			assert_string ("light red", ansi (9), "LightRed")
			assert_string ("light green", ansi (10), "LightGreen")
			assert_string ("light yellow", ansi (11), "LightYellow")
			assert_string ("light blue", ansi (12), "LightBlue")
			assert_string ("light magenta", ansi (13), "LightMagenta")
			assert_string ("light cyan", ansi (14), "LightCyan")
			assert_string ("white", ansi (15), "White")
			assert_string ("indexed", create {COLOR}.make_indexed (10), "10")
			assert_string ("rgb", {COLOR}.rgb (255, 0, 0), "#FF0000")
			assert_string ("reset", {COLOR}.Reset_color, "Reset")
		end

	test_ratatui_deserialize
			-- Ratatui `deserialize` and `deserialize_error` (serde reads through `from_str`):
			-- "Black", "magenta", "LightGreen", "bright-white", "42", "#00ff00"; "invalid" and
			-- "#00000000" are errors.
		do
			assert_color ("Black", "Black", ansi (0))
			assert_color ("magenta", "magenta", ansi (5))
			assert_color ("LightGreen", "LightGreen", ansi (10))
			assert_color ("bright-white", "bright-white", ansi (15))
			assert_color ("42", "42", create {COLOR}.make_indexed (42))
			assert_color ("#00ff00", "#00ff00", {COLOR}.rgb (0, 255, 0))
			assert_invalid ("invalid")
			assert_invalid ("#00000000")
		end

	test_ratatui_serialize_then_deserialize
			-- Ratatui `serialize_then_deserialize` (serde writes through `Display`): Rgb (255, 0,
			-- 255) is "#FF00FF", White is "White", Indexed (10) is "10", and each reads back.
		do
			assert_string ("rgb", {COLOR}.rgb (255, 0, 255), "#FF00FF")
			assert_color ("rgb back", "#FF00FF", {COLOR}.rgb (255, 0, 255))
			assert_string ("white", ansi (15), "White")
			assert_string ("indexed", create {COLOR}.make_indexed (10), "10")
			assert_color ("indexed back", "10", create {COLOR}.make_indexed (10))
		end

feature -- EiffelTUI

	test_color_name_trap
			-- Ratatui's names, not EiffelTUI's constant names: "white" is ANSI 15
			-- (`Bright_white`), "gray" is ANSI 7 (`White` and `Gray` here), "darkgray" is
			-- ANSI 8 (`Bright_black`, `Dark_gray`); `{COLOR}.White` prints as "Gray".
		do
			assert_color ("white", "white", {COLOR}.Bright_white)
			assert_color ("gray", "gray", {COLOR}.White)
			assert_color ("gray constant", "gray", {COLOR}.Gray)
			assert_color ("dark gray", "darkgray", {COLOR}.Dark_gray)
			assert_color ("light cyan", "lightcyan", {COLOR}.Light_cyan)
			assert_string ("White constant", {COLOR}.White, "Gray")
			assert_string ("Bright_white constant", {COLOR}.Bright_white, "White")
		end

	test_color_string_edges
			-- Index and hex forms as Rust reads them, from the text itself (not the normalized
			-- name); names with any case and separators; "default" (EiffelTUI only).
		do
				-- indices
			assert_color ("zero", "0", create {COLOR}.make_indexed (0))
			assert_color ("max", "255", create {COLOR}.make_indexed (255))
			assert_color ("leading zeros", "0010", create {COLOR}.make_indexed (10))
			assert_color ("plus sign", "+10", create {COLOR}.make_indexed (10))
			assert_invalid ("256")
			assert_invalid ("99999999999999999999")
			assert_invalid ("-1")
			assert_invalid ("+")
			assert_invalid ("++1")
			assert_invalid (" 10")
			assert_invalid ("10 ")
			assert_invalid ("1_0")
			assert_invalid ("")
				-- hex
			assert_color ("lower case", "#ff8800", {COLOR}.rgb (255, 136, 0))
			assert_color ("mixed case", "#Ff88aB", {COLOR}.rgb (255, 136, 171))
			assert_color ("plus in a pair", "#+F+F+F", {COLOR}.rgb (15, 15, 15))
			assert_invalid ("#FFF")
			assert_invalid ("#GG0000")
			assert_invalid ("# FF000")
			assert_invalid ("#F+0000")
			assert_invalid ("#-F0000")
			assert_invalid ("FF0000")
				-- names
			assert_color ("upper case", "LIGHT RED", ansi (9))
			assert_color ("separators", "Bright_Blue", ansi (12))
			assert_color ("bright grey", "bright grey", ansi (15))
			assert_color ("light silver", "light silver", ansi (15))
			assert_color ("dark grey", "dark-grey", ansi (8))
			assert_invalid ("light%Tred")
			assert_invalid ("light.red")
			assert ("reset any case", (create {COLOR}.make_from_string ("RE-SET")).is_reset)
			assert ("default", (create {COLOR}.make_from_string ("default")).is_default)
			assert ("Default", (create {COLOR}.make_from_string ("Default")).is_default)
			assert_string ("default printed", create {COLOR}, "Default")
				-- the text kinds
			assert_color ("string_32", {STRING_32} "red", ansi (1))
			assert_color ("immutable", create {IMMUTABLE_STRING_32}.make_from_string ("#010203"), {COLOR}.rgb (1, 2, 3))
		end

	test_color_string_round_trip
			-- `as_string` reads back as the same color for every kind: the 16 ANSI colors, all
			-- 256 indices, RGB corners, reset and default.
		local
			i: INTEGER
		do
			from i := 0 until i > 15 loop
				assert_round_trip ("ansi " + i.out, ansi (i))
				i := i + 1
			end
			from i := 0 until i > 255 loop
				assert_round_trip ("indexed " + i.out, create {COLOR}.make_indexed (i.to_natural_8))
				i := i + 1
			end
			assert_round_trip ("black rgb", {COLOR}.rgb (0, 0, 0))
			assert_round_trip ("white rgb", {COLOR}.rgb (255, 255, 255))
			assert_round_trip ("mixed rgb", {COLOR}.rgb (1, 128, 254))
			assert_round_trip ("reset", {COLOR}.Reset_color)
			assert_round_trip ("default", create {COLOR})
		end

	test_make_from_string_precondition
			-- `make_from_string` refuses a text that is not a color (`valid_text`), and
			-- `is_valid_color_string` says so first.
		do
			assert ("not valid", not {COLOR}.is_valid_color_string ("nope"))
			assert ("nord not valid", not {COLOR}.is_valid_color_string ("nord"))
			assert ("hex valid", {COLOR}.is_valid_color_string ("#123456"))
			assert ("raised", precondition_raised (agent make_color ("nope"), "valid_text"))
			assert ("empty raised", precondition_raised (agent make_color (""), "valid_text"))
		end

feature {NONE} -- Helpers

	ansi (a_code: INTEGER): COLOR
			-- New ANSI color `a_code`
		require
			valid_code: a_code >= 0 and a_code <= 15
		do
			create Result.make_ansi (a_code.to_natural_8)
		end

	assert_color (a_tag: STRING; a_text: READABLE_STRING_GENERAL; a_expected: COLOR)
			-- Check that `a_text` is a valid color string that reads as `a_expected`.
		do
			assert (a_tag + " valid", {COLOR}.is_valid_color_string (a_text))
			assert (a_tag + " is " + a_expected.out, (create {COLOR}.make_from_string (a_text)).is_equal (a_expected))
		end

	assert_invalid (a_text: READABLE_STRING_GENERAL)
			-- Check that `a_text` is not a color string.
		do
			assert ("invalid: " + {UTF_CONVERTER}.utf_32_string_to_utf_8_string_8 (a_text.to_string_32), not {COLOR}.is_valid_color_string (a_text))
		end

	assert_string (a_tag: STRING; a_color: COLOR; a_expected: STRING)
			-- Check that `a_color` prints as `a_expected`.
		do
			assert (a_tag + ": " + a_color.as_string, a_color.as_string.same_string (a_expected))
		end

	assert_round_trip (a_tag: STRING; a_color: COLOR)
			-- Check that `a_color.as_string` reads back as `a_color`.
		do
			assert (a_tag, (create {COLOR}.make_from_string (a_color.as_string)).is_equal (a_color))
		end

	make_color (a_text: READABLE_STRING_GENERAL)
			-- Create a color from `a_text` (for `precondition_raised`).
		local
			l_color: COLOR
		do
			create l_color.make_from_string (a_text)
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
