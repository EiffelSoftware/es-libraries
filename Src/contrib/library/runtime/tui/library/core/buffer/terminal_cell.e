note
	description: "[
		Individual character cell on a terminal framebuffer.
		Holds a grapheme cluster, visual style, display width, and multi-column continuation status.

		Ownership rules (they let BUFFER update cells in place without allocating):
		  * `symbol` is an IMMUTABLE_STRING_32, so it cannot change once stored; it may be shared
		    between cells (blank cells and single code points come from `Symbol_pool`, and
		    `pooled_char` hands out those same immutable strings).
		  * `symbol` holds only Unicode scalar values (invariant `scalar_symbol`), so it always
		    has a UTF-8 form: the setters store a surrogate or a value above U+10FFFF as U+FFFD.
		  * `style` may be shared between cells of the same buffer. STYLE has no public
		    mutators (its setters and `copy` are exported to {STYLE} only), so it cannot be
		    changed in place. Clients change a cell's look through `set_style` (which stores a
		    private copy) or through BUFFER operations.

		Diff option (Ratatui `CellDiffOption`, see CELL_DIFF_OPTION): `diff_option` and
		`forced_width` tell DIFF_ENGINE how to treat the cell. They are set only through
		{BUFFER}.set_diff_option. Every change of the cell's content (`set_symbol`, `set_char`,
		`set_continuation`, `reset` and BUFFER's writes) clears them; a change of style alone
		(`set_style`, BUFFER's `set_style`) keeps them, and `copy_cell` copies them.
		`same_content` ignores them: it compares what the cell shows.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TERMINAL_CELL

inherit
	ANY
		redefine
			default_create,
			is_equal
		end

create
	default_create,
	make_with_char,
	make_continuation

feature {NONE} -- Initialization

	default_create
			-- Initialize as a blank single-width cell with default style.
		do
			symbol := Default_symbol
			style := Default_style
			width := 1
			is_continuation := False
			clear_diff_option
		ensure then
			symbol_space: symbol.same_string ({STRING_32} " ")
			width_one: width = 1
			not_continuation: not is_continuation
			no_diff_option: diff_option = {CELL_DIFF_OPTION}.None
		end

	make_with_char (a_char: CHARACTER_32; a_style: STYLE)
			-- Initialize with `a_char` and `a_style` (immutable, shared).
		do
			set_char (a_char)
			style := a_style
		ensure
			not_continuation: not is_continuation
			no_diff_option: diff_option = {CELL_DIFF_OPTION}.None
		end

	make_continuation
			-- Initialize as the trailing placeholder cell for a multi-column character.
		do
			symbol := Empty_symbol
			style := Default_style
			width := 0
			is_continuation := True
			clear_diff_option
		ensure
			empty_symbol: symbol.is_empty
			width_zero: width = 0
			is_continuation: is_continuation
			no_diff_option: diff_option = {CELL_DIFF_OPTION}.None
		end

feature -- Access

	symbol: IMMUTABLE_STRING_32
			-- Grapheme cluster displayed in this cell (immutable, possibly shared)

	style: STYLE
			-- Visual styling (foreground, background, modifiers); possibly shared, do not mutate

	width: NATURAL_8
			-- Display column width (0 = continuation/zero-width, 1 = narrow, 2 = wide)

	is_continuation: BOOLEAN
			-- Is this cell the right half of a wide 2-column character?

	diff_option: NATURAL_8
			-- How DIFF_ENGINE treats this cell (a CELL_DIFF_OPTION constant; default `None`)

	forced_width: NATURAL_8
			-- Columns this cell covers when `diff_option` is `Forced_width`; 0 otherwise

	covered_width: INTEGER
			-- Columns the diff and the serializer count for this cell: `forced_width` when the
			-- width is forced, else `width`
		do
			if diff_option = {CELL_DIFF_OPTION}.Forced_width then
				Result := forced_width.to_integer_32
			else
				Result := width.to_integer_32
			end
		ensure
			forced: diff_option = {CELL_DIFF_OPTION}.Forced_width implies Result = forced_width.to_integer_32
			natural: diff_option /= {CELL_DIFF_OPTION}.Forced_width implies Result = width.to_integer_32
		end

feature -- Status report

	same_content (a_other: TERMINAL_CELL): BOOLEAN
			-- Would `Current` and `a_other` look the same on screen?
			-- (Styles are compared by rendered attributes, see {STYLE}.same_rendering.)
		do
			Result := width = a_other.width and
				is_continuation = a_other.is_continuation and
				symbol.same_string (a_other.symbol) and
				(style = a_other.style or else style.same_rendering (a_other.style))
		end

	same_diff_option (a_other: TERMINAL_CELL): BOOLEAN
			-- Do `Current` and `a_other` have the same diff option (and forced width)?
		do
			Result := diff_option = a_other.diff_option and forced_width = a_other.forced_width
		end

feature -- Element change

	set_symbol (a_symbol: READABLE_STRING_GENERAL)
			-- Set grapheme cluster `a_symbol` and recalculate display width.
			-- A surrogate or a value above U+10FFFF is stored as U+FFFD (see UNICODE_SCALAR).
		do
			symbol := pooled_symbol ({UNICODE_SCALAR}.scalar_string (a_symbol))
			width := {UNICODE_WIDTH}.grapheme_width (symbol)
			is_continuation := False
			clear_diff_option
		ensure
			symbol_set: symbol.same_string_general ({UNICODE_SCALAR}.scalar_string (a_symbol))
			not_continuation: not is_continuation
			no_diff_option: diff_option = {CELL_DIFF_OPTION}.None
		end

	set_char (a_char: CHARACTER_32)
			-- Set character `a_char` and recalculate display width.
			-- A surrogate or a value above U+10FFFF is stored as U+FFFD (see UNICODE_SCALAR).
		local
			l_code: NATURAL_32
		do
			l_code := {UNICODE_SCALAR}.scalar_value (a_char.natural_32_code)
			symbol := pooled_char (l_code)
			width := {UNICODE_WIDTH}.width (l_code)
			is_continuation := False
			clear_diff_option
		ensure
			symbol_set: symbol.count = 1 and symbol.code (1) = {UNICODE_SCALAR}.scalar_value (a_char.natural_32_code)
			not_continuation: not is_continuation
			no_diff_option: diff_option = {CELL_DIFF_OPTION}.None
		end

	set_style (a_style: STYLE)
			-- Set visual styling to a private copy of `a_style`.
		do
			style := a_style.twin
		ensure
			style_set: style.is_equal (a_style)
			private: style /= a_style
		end

	set_width (a_width: NATURAL_8)
			-- Set display width directly.
		require
			valid_width: a_width <= 2
			not_continuation: not is_continuation or a_width = 0
		do
			width := a_width
		ensure
			width_set: width = a_width
		end

	set_continuation (a_val: BOOLEAN)
			-- Mark whether cell is a wide character continuation.
		do
			is_continuation := a_val
			if a_val then
				width := 0
				symbol := Empty_symbol
				style := Default_style
			elseif width = 0 then
				symbol := Default_symbol
				width := 1
			end
			clear_diff_option
		ensure
			continuation_set: is_continuation = a_val
			no_diff_option: diff_option = {CELL_DIFF_OPTION}.None
		end

	reset
			-- Reset cell to a single space with default style and no diff option.
		do
			symbol := Default_symbol
			style := Default_style
			width := 1
			is_continuation := False
			clear_diff_option
		ensure
			reset_space: symbol.same_string ({STRING_32} " ")
			width_one: width = 1
			not_continuation: not is_continuation
			no_diff_option: diff_option = {CELL_DIFF_OPTION}.None
		end

feature {BUFFER, TERMINAL_CELL} -- In-place update

	set_content (a_symbol: IMMUTABLE_STRING_32; a_width: NATURAL_8; a_style: STYLE)
			-- Store `a_symbol` (shared, not copied: it is immutable),
			-- `a_width` and `a_style` (shared, not copied).
		require
			valid_width: a_width = 1 or a_width = 2
			scalar_symbol: {UNICODE_SCALAR}.is_scalar_string (a_symbol)
		do
			symbol := a_symbol
			width := a_width
			style := a_style
			is_continuation := False
			clear_diff_option
		ensure
			symbol_set: symbol = a_symbol
			width_set: width = a_width
			style_set: style = a_style
			not_continuation: not is_continuation
			no_diff_option: diff_option = {CELL_DIFF_OPTION}.None
		end

	set_content_style (a_style: STYLE)
			-- Use `a_style` (shared, not copied).
		do
			style := a_style
		ensure
			style_set: style = a_style
		end

	set_blank (a_style: STYLE)
			-- Make `Current` a single-width space with `a_style` (shared, not copied).
		do
			symbol := Default_symbol
			width := 1
			style := a_style
			is_continuation := False
			clear_diff_option
		ensure
			blank: symbol.same_string ({STRING_32} " ") and width = 1 and not is_continuation
			style_set: style = a_style
			no_diff_option: diff_option = {CELL_DIFF_OPTION}.None
		end

	make_continuation_in_place
			-- Turn `Current` into the trailing half of a wide character.
		do
			symbol := Empty_symbol
			style := Default_style
			width := 0
			is_continuation := True
			clear_diff_option
		ensure
			is_continuation: is_continuation and width = 0
			no_diff_option: diff_option = {CELL_DIFF_OPTION}.None
		end

	copy_cell (a_other: TERMINAL_CELL)
			-- Take over the content and the diff option of `a_other`, sharing its symbol and style.
		do
			symbol := a_other.symbol
			style := a_other.style
			width := a_other.width
			is_continuation := a_other.is_continuation
			diff_option := a_other.diff_option
			forced_width := a_other.forced_width
		ensure
			same: same_content (a_other)
			same_option: same_diff_option (a_other)
		end

	set_diff_option_in_place (a_option, a_width: NATURAL_8)
			-- Use diff option `a_option`, with forced width `a_width` (0 unless `a_option` is
			-- `Forced_width`). The content is unchanged.
		require
			valid_option: {CELL_DIFF_OPTION}.is_valid (a_option)
			valid_width: {CELL_DIFF_OPTION}.is_valid_width (a_option, a_width)
			forced_not_continuation: a_option = {CELL_DIFF_OPTION}.Forced_width implies not is_continuation
		do
			diff_option := a_option
			forced_width := a_width
		ensure
			option_set: diff_option = a_option
			width_set: forced_width = a_width
			same_symbol: symbol = old symbol
			same_style: style = old style
			same_width: width = old width
		end

feature {NONE} -- Diff option

	clear_diff_option
			-- Back to no diff option.
		do
			diff_option := {CELL_DIFF_OPTION}.None
			forced_width := 0
		ensure
			cleared: diff_option = {CELL_DIFF_OPTION}.None and forced_width = 0
		end

feature -- Status report (symbols)

	is_one_column_symbol (a_symbol: READABLE_STRING_GENERAL): BOOLEAN
			-- Does `a_symbol` fill exactly one cell: one grapheme cluster, one column wide?
			-- The empty string also qualifies (it draws nothing). Widgets that repeat a symbol
			-- once per cell (scrollbar, line gauge) require this of their symbols.
		do
			Result := a_symbol.is_empty or else
				({UNICODE_WIDTH}.string_width (a_symbol) = 1 and
				{UNICODE_WIDTH}.grapheme_end (a_symbol, 1) = a_symbol.count)
		ensure
			instance_free: class
		end

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Is `Current` identical in content, styling and diff option to `a_other`?
			-- (Ratatui's `Cell` equality also compares the diff option.)
		do
			Result := width = a_other.width and
				is_continuation = a_other.is_continuation and
				symbol.same_string (a_other.symbol) and
				style.is_equal (a_other.style) and
				same_diff_option (a_other)
		end

feature -- Symbol pool

	pooled_char (a_code: NATURAL_32): IMMUTABLE_STRING_32
			-- Shared immutable one-code-point string for `a_code`.
			-- ASCII is preallocated; other code points are cached up to `Symbol_pool_capacity`.
		local
			l_pool: like Symbol_pool
			l_s: STRING_32
		do
			if a_code = 32 then
				Result := Default_symbol
			elseif a_code < 128 then
				Result := Ascii_symbols [a_code.to_integer_32]
			else
				l_pool := Symbol_pool
				if attached l_pool.item (a_code) as l_found then
					Result := l_found
				else
					create l_s.make (1)
					l_s.append_code (a_code)
					create Result.make_from_string_32 (l_s)
					if l_pool.count < Symbol_pool_capacity then
						l_pool.put (Result, a_code)
					end
				end
			end
		ensure
			instance_free: class
			one_code_point: Result.count = 1 and Result.code (1) = a_code
		end

	pooled_symbol (a_symbol: READABLE_STRING_GENERAL): IMMUTABLE_STRING_32
			-- Immutable string equal to `a_symbol`: pooled when it is one code point, a fresh copy otherwise.
		do
			if a_symbol.count = 1 then
				Result := pooled_char (a_symbol.code (1))
			elseif a_symbol.is_empty then
				Result := Empty_symbol
			else
				create Result.make_from_string_general (a_symbol)
			end
		ensure
			instance_free: class
			same: Result.same_string_general (a_symbol)
		end

feature {NONE} -- Constants

	Default_symbol: IMMUTABLE_STRING_32
			-- Shared blank symbol
		once
			Result := " "
		ensure
			instance_free: class
		end

	Empty_symbol: IMMUTABLE_STRING_32
			-- Shared symbol of continuation cells
		once
			create Result.make_empty
		ensure
			instance_free: class
		end

	Default_style: STYLE
		once
			create Result.default_create
		ensure
			instance_free: class
		end

	Ascii_symbols: SPECIAL [IMMUTABLE_STRING_32]
			-- Preallocated one-character strings for code points 0..127
		local
			i: INTEGER
			l_s: STRING_32
		once
			create Result.make_empty (128)
			from
				i := 0
			until
				i >= 128
			loop
				create l_s.make (1)
				l_s.append_code (i.to_natural_32)
				Result.extend (create {IMMUTABLE_STRING_32}.make_from_string_32 (l_s))
				i := i + 1
			end
		ensure
			instance_free: class
		end

	Symbol_pool: HASH_TABLE [IMMUTABLE_STRING_32, NATURAL_32]
			-- Cache of non-ASCII one-code-point symbols (per thread)
		once
			create Result.make (256)
		ensure
			instance_free: class
		end

	Symbol_pool_capacity: INTEGER = 4096
			-- Maximum number of cached non-ASCII symbols

invariant
	valid_width: width <= 2
	continuation_consistency: is_continuation implies width = 0
	scalar_symbol: {UNICODE_SCALAR}.is_scalar_string (symbol)
	valid_diff_option: {CELL_DIFF_OPTION}.is_valid (diff_option)
	forced_width_only_when_forced: {CELL_DIFF_OPTION}.is_valid_width (diff_option, forced_width)
	continuation_not_forced: is_continuation implies diff_option /= {CELL_DIFF_OPTION}.Forced_width

end
