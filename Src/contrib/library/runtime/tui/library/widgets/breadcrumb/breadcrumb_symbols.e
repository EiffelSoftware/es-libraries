note
	description: "[
		Separator presets for TUI_BREADCRUMB, and the symbol that stands for collapsed crumbs.
		Each call returns a new IMMUTABLE_STRING_32, so a preset cannot be changed by the code
		that uses it (see B1 in review/p2_terminal_widgets_plan.md for what shared mutable
		presets do).
		  * `chevron` (the default): " " U+203A SINGLE RIGHT-POINTING ANGLE QUOTATION MARK " ".
		  * `arrow`: " > ", ASCII.
		  * `slash`: " / ", ASCII, as a file path.
		  * `ellipsis`: U+2026 HORIZONTAL ELLIPSIS, one column, drawn in place of the hidden
		    middle crumbs.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	BREADCRUMB_SYMBOLS

feature -- Separators

	chevron: IMMUTABLE_STRING_32
			-- " " U+203A " ", the default separator
		do
			create Result.make_from_string_general ({STRING_32} " %/0x203A/ ")
		ensure
			instance_free: class
			three_columns: {UNICODE_WIDTH}.string_width (Result) = 3
		end

	arrow: IMMUTABLE_STRING_32
			-- " > "
		do
			create Result.make_from_string_general (" > ")
		ensure
			instance_free: class
			three_columns: {UNICODE_WIDTH}.string_width (Result) = 3
		end

	slash: IMMUTABLE_STRING_32
			-- " / "
		do
			create Result.make_from_string_general (" / ")
		ensure
			instance_free: class
			three_columns: {UNICODE_WIDTH}.string_width (Result) = 3
		end

feature -- Collapse

	ellipsis: IMMUTABLE_STRING_32
			-- U+2026, drawn in place of the hidden middle crumbs
		do
			create Result.make_from_string_general ({STRING_32} "%/0x2026/")
		ensure
			instance_free: class
			one_column: {UNICODE_WIDTH}.string_width (Result) = 1
		end

end
