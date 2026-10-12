note
	description: "[
		Terminal viewport specification supporting Fullscreen (alternate screen buffer),
		Inline (N-lines in current scrollback), and Fixed (arbitrary static RECT).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	VIEWPORT

create
	make_fullscreen,
	make_inline,
	make_inline_at,
	make_fixed

feature {NONE} -- Initialization

	make_fullscreen
			-- Fullscreen viewport using alternate screen buffer.
		do
			mode := Mode_fullscreen
			inline_height := 0
			fixed_area := Void
			origin_row := 0
			origin_column := 0
		ensure
			is_fullscreen: is_fullscreen
		end

	make_inline (a_height: NATURAL_16)
			-- Inline viewport occupying `a_height` lines in standard terminal scrollback.
		require
			positive_height: a_height > 0
		do
			mode := Mode_inline
			inline_height := a_height
			fixed_area := Void
			origin_row := 0
			origin_column := 0
		ensure
			is_inline: is_inline
			inline_height_set: inline_height = a_height
		end

	make_inline_at (a_height: NATURAL_16; a_origin_row: INTEGER)
			-- Inline viewport occupying `a_height` lines starting at terminal row `a_origin_row`.
		require
			positive_height: a_height > 0
			non_negative_row: a_origin_row >= 0
		do
			make_inline (a_height)
			origin_row := a_origin_row
		ensure
			is_inline: is_inline
			inline_height_set: inline_height = a_height
			origin_row_set: origin_row = a_origin_row
		end

	make_fixed (a_area: RECT)
			-- Fixed area viewport constrained to `a_area`.
		require
			area_not_void: a_area /= Void
		do
			mode := Mode_fixed
			inline_height := 0
			fixed_area := a_area
			origin_row := a_area.y.to_integer_32
			origin_column := a_area.x.to_integer_32
		ensure
			is_fixed: is_fixed
			fixed_area_set: fixed_area = a_area
		end

feature -- Commands

	set_origin (a_row, a_col: INTEGER)
			-- Set screen coordinate origin for inline or fixed viewports.
		require
			non_negative_row: a_row >= 0
			non_negative_col: a_col >= 0
		do
			origin_row := a_row
			origin_column := a_col
		ensure
			origin_row_set: origin_row = a_row
			origin_col_set: origin_column = a_col
		end

	set_fixed_area (a_area: RECT)
			-- Move/resize a fixed viewport to `a_area`.
		require
			fixed: is_fixed
			area_not_void: a_area /= Void
		do
			fixed_area := a_area
			origin_row := a_area.y.to_integer_32
			origin_column := a_area.x.to_integer_32
		ensure
			fixed_area_set: fixed_area = a_area
		end

feature -- Queries

	is_fullscreen: BOOLEAN
			-- Is this a fullscreen viewport?
		do
			Result := mode = Mode_fullscreen
		end

	is_inline: BOOLEAN
			-- Is this an inline N-line viewport?
		do
			Result := mode = Mode_inline
		end

	is_fixed: BOOLEAN
			-- Is this a fixed area viewport?
		do
			Result := mode = Mode_fixed
		end

	inline_height: NATURAL_16
			-- Line count for inline viewport mode.

	fixed_area: detachable RECT
			-- Bounding rectangle for fixed viewport mode.

	origin_row: INTEGER
			-- 0-based top row offset on screen.

	origin_column: INTEGER
			-- 0-based left column offset on screen.

feature {NONE} -- Internal Constants

	mode: INTEGER

	Mode_fullscreen: INTEGER = 1
	Mode_inline: INTEGER = 2
	Mode_fixed: INTEGER = 3

end
