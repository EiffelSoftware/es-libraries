note
	description: "[
		Scrollbar widget rendering visual scroll feedback along container boundaries
		with customizable track, thumb, arrows, and styles.
		Each symbol fills exactly one cell, so it must be one column wide (`is_valid_symbol`):
		a wider one would spill into the next widget, or blank its neighbour in the bar.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_SCROLLBAR

inherit
	STATEFUL_WIDGET [SCROLLBAR_STATE]
		redefine
			default_create
		end

create
	default_create,
	make

feature {NONE} -- Initialization

	default_create
			-- Initialize as a vertical right scrollbar.
		local
			l_tr: STRING_32
		do
			orientation := {SCROLLBAR_ORIENTATION}.vertical_right
			create thumb_symbol.make (1)
			thumb_symbol.append_character ((9608).to_character_32)
			create l_tr.make (1)
			l_tr.append_character ((9474).to_character_32)
			track_symbol := l_tr
			create thumb_style.default_create
			create track_style.default_create
			create begin_style.default_create
			create end_style.default_create
		ensure then
			default_orientation: orientation = {SCROLLBAR_ORIENTATION}.vertical_right
		end

	make (a_orientation: NATURAL_8)
			-- Initialize with `a_orientation`.
		require
			valid_orientation: {SCROLLBAR_ORIENTATION}.is_valid (a_orientation)
		local
			l_tr: STRING_32
		do
			default_create
			orientation := a_orientation
			if {SCROLLBAR_ORIENTATION}.is_horizontal (a_orientation) then
				create l_tr.make (1)
				l_tr.append_character ((9472).to_character_32)
				track_symbol := l_tr
			end
		ensure
			orientation_set: orientation = a_orientation
		end

feature -- Access

	orientation: NATURAL_8
			-- Edge orientation (vertical right/left, horizontal top/bottom)

	thumb_symbol: STRING_32
			-- Glyph representing the scroll thumb (e.g. "█")

	track_symbol: detachable STRING_32
			-- Optional glyph representing empty track spaces (e.g. "│" or "─")

	begin_symbol: detachable STRING_32
			-- Optional arrow symbol at the start (e.g. "▲" or "◄")

	end_symbol: detachable STRING_32
			-- Optional arrow symbol at the end (e.g. "▼" or "►")

	thumb_style: STYLE
			-- Style applied to the scroll thumb

	track_style: STYLE
			-- Style applied to the track

	begin_style: STYLE
			-- Style applied to the begin arrow

	end_style: STYLE
			-- Style applied to the end arrow

feature -- Status report

	is_valid_symbol (a_symbol: READABLE_STRING_GENERAL): BOOLEAN
			-- Can `a_symbol` be a scrollbar symbol: one grapheme cluster, one column wide?
			-- (The empty string is allowed too: it draws nothing.)
		do
			Result := {TERMINAL_CELL}.is_one_column_symbol (a_symbol)
		ensure
			instance_free: class
		end

feature -- Element change

	set_orientation (a_orientation: NATURAL_8)
			-- Set edge orientation.
		require
			valid_orientation: {SCROLLBAR_ORIENTATION}.is_valid (a_orientation)
		do
			orientation := a_orientation
		ensure
			orientation_set: orientation = a_orientation
		end

	set_thumb_symbol (a_symbol: READABLE_STRING_GENERAL)
			-- Set thumb character glyph.
		require
			symbol_not_void: a_symbol /= Void
			one_column: is_valid_symbol (a_symbol)
		do
			create thumb_symbol.make_from_string_general (a_symbol)
		ensure
			symbol_set: thumb_symbol.same_string_general (a_symbol)
		end

	set_track_symbol (a_symbol: detachable READABLE_STRING_GENERAL)
			-- Set or clear track character glyph.
		require
			one_column: attached a_symbol as s implies is_valid_symbol (s)
		do
			if attached a_symbol as s then
				create track_symbol.make_from_string_general (s)
			else
				track_symbol := Void
			end
		ensure
			symbol_set: attached a_symbol implies attached track_symbol
		end

	set_begin_symbol (a_symbol: detachable READABLE_STRING_GENERAL)
			-- Set or clear start arrow symbol.
		require
			one_column: attached a_symbol as s implies is_valid_symbol (s)
		do
			if attached a_symbol as s then
				create begin_symbol.make_from_string_general (s)
			else
				begin_symbol := Void
			end
		ensure
			symbol_set: attached a_symbol implies attached begin_symbol
		end

	set_end_symbol (a_symbol: detachable READABLE_STRING_GENERAL)
			-- Set or clear end arrow symbol.
		require
			one_column: attached a_symbol as s implies is_valid_symbol (s)
		do
			if attached a_symbol as s then
				create end_symbol.make_from_string_general (s)
			else
				end_symbol := Void
			end
		ensure
			symbol_set: attached a_symbol implies attached end_symbol
		end

	set_thumb_style (a_style: STYLE)
			-- Set style for thumb.
		require
			style_not_void: a_style /= Void
		do
			thumb_style := a_style
		ensure
			style_set: thumb_style = a_style
		end

	set_track_style (a_style: STYLE)
			-- Set style for track.
		require
			style_not_void: a_style /= Void
		do
			track_style := a_style
		ensure
			style_set: track_style = a_style
		end

	set_begin_style (a_style: STYLE)
			-- Set style for begin arrow.
		require
			style_not_void: a_style /= Void
		do
			begin_style := a_style
		ensure
			style_set: begin_style = a_style
		end

	set_end_style (a_style: STYLE)
			-- Set style for end arrow.
		require
			style_not_void: a_style /= Void
		do
			end_style := a_style
		ensure
			style_set: end_style = a_style
		end

	set_style (a_style: STYLE)
			-- Set uniform style across all scrollbar elements.
		require
			style_not_void: a_style /= Void
		do
			thumb_style := a_style
			track_style := a_style
			begin_style := a_style
			end_style := a_style
		ensure
			thumb_style_set: thumb_style = a_style
			track_style_set: track_style = a_style
			begin_style_set: begin_style = a_style
			end_style_set: end_style = a_style
		end

feature -- Fluent Builders

	with_orientation (a_orientation: NATURAL_8): like Current
			-- Return a copy of Current with `a_orientation`.
		require
			valid_orientation: {SCROLLBAR_ORIENTATION}.is_valid (a_orientation)
		do
			Result := twin
			Result.set_orientation (a_orientation)
		ensure
			orientation_set: Result.orientation = a_orientation
			result_not_void: Result /= Void
		end

	with_thumb_symbol (a_symbol: READABLE_STRING_GENERAL): like Current
			-- Return a copy of Current with `a_symbol` thumb.
		require
			symbol_not_void: a_symbol /= Void
			one_column: is_valid_symbol (a_symbol)
		do
			Result := twin
			Result.set_thumb_symbol (a_symbol)
		ensure
			result_not_void: Result /= Void
		end

	with_track_symbol (a_symbol: detachable READABLE_STRING_GENERAL): like Current
			-- Return a copy of Current with `a_symbol` track.
		require
			one_column: attached a_symbol as s implies is_valid_symbol (s)
		do
			Result := twin
			Result.set_track_symbol (a_symbol)
		ensure
			result_not_void: Result /= Void
		end

	with_begin_symbol (a_symbol: detachable READABLE_STRING_GENERAL): like Current
			-- Return a copy of Current with `a_symbol` start arrow.
		require
			one_column: attached a_symbol as s implies is_valid_symbol (s)
		do
			Result := twin
			Result.set_begin_symbol (a_symbol)
		ensure
			result_not_void: Result /= Void
		end

	with_end_symbol (a_symbol: detachable READABLE_STRING_GENERAL): like Current
			-- Return a copy of Current with `a_symbol` end arrow.
		require
			one_column: attached a_symbol as s implies is_valid_symbol (s)
		do
			Result := twin
			Result.set_end_symbol (a_symbol)
		ensure
			result_not_void: Result /= Void
		end

	with_thumb_style (a_style: STYLE): like Current
			-- Return a copy of Current with `a_style` thumb style.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_thumb_style (a_style)
		ensure
			result_not_void: Result /= Void
		end

	with_track_style (a_style: STYLE): like Current
			-- Return a copy of Current with `a_style` track style.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_track_style (a_style)
		ensure
			result_not_void: Result /= Void
		end

	with_style (a_style: STYLE): like Current
			-- Return a copy of Current with uniform `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_style (a_style)
		ensure
			result_not_void: Result /= Void
		end

feature -- Rendering

	render (a_area: RECT; a_buffer: BUFFER)
			-- Stateless rendering using a default empty SCROLLBAR_STATE.
		local
			l_state: SCROLLBAR_STATE
		do
			create l_state.default_create
			render_stateful (a_area, a_buffer, l_state)
		end

	render_scrollbar (a_area: RECT; a_buffer: BUFFER; a_state: SCROLLBAR_STATE)
			-- Synonym for `render_stateful`.
		require
			area_not_void: a_area /= Void
			buffer_not_void: a_buffer /= Void
			state_not_void: a_state /= Void
		do
			render_stateful (a_area, a_buffer, a_state)
		end

	render_stateful (a_area: RECT; a_buffer: BUFFER; a_state: SCROLLBAR_STATE)
			-- Render scrollbar along area boundary according to `a_state`.
		local
			l_is_vert: BOOLEAN
			l_start_x, l_start_y: INTEGER
			l_strip_len: INTEGER
			l_has_begin, l_has_end: BOOLEAN
			l_arrows_len, l_track_len: INTEGER
			l_viewport_len, l_max_pos, l_start_pos, l_max_viewport_pos: INTEGER
			l_thumb_len, l_thumb_start: INTEGER
			k, k_track: INTEGER
			cell_row, cell_col: INTEGER
			l_sym: detachable STRING_32
			l_sym_style: STYLE
		do
			if not a_area.is_empty and a_state.content_length > 0 then
				l_is_vert := {SCROLLBAR_ORIENTATION}.is_vertical (orientation)

				-- Determine scrollbar strip coordinates and length
				inspect orientation
				when {SCROLLBAR_ORIENTATION}.vertical_right then
					l_start_x := a_area.x.to_integer_32 + a_area.width.to_integer_32 - 1
					l_start_y := a_area.y.to_integer_32
					l_strip_len := a_area.height.to_integer_32
				when {SCROLLBAR_ORIENTATION}.vertical_left then
					l_start_x := a_area.x.to_integer_32
					l_start_y := a_area.y.to_integer_32
					l_strip_len := a_area.height.to_integer_32
				when {SCROLLBAR_ORIENTATION}.horizontal_top then
					l_start_x := a_area.x.to_integer_32
					l_start_y := a_area.y.to_integer_32
					l_strip_len := a_area.width.to_integer_32
				else -- horizontal_bottom
					l_start_x := a_area.x.to_integer_32
					l_start_y := a_area.y.to_integer_32 + a_area.height.to_integer_32 - 1
					l_strip_len := a_area.width.to_integer_32
				end

				if l_strip_len > 0 then
					l_has_begin := attached begin_symbol as b and then not b.is_empty
					l_has_end := attached end_symbol as e and then not e.is_empty
					l_arrows_len := (if l_has_begin then 1 else 0 end) + (if l_has_end then 1 else 0 end)

					if l_strip_len >= l_arrows_len then
						l_track_len := l_strip_len - l_arrows_len

						if l_track_len > 0 then
							if a_state.viewport_content_length > 0 then
								l_viewport_len := a_state.viewport_content_length
							else
								l_viewport_len := l_strip_len
							end

							l_max_pos := (a_state.content_length - 1).max (0)
							l_start_pos := a_state.position.min (l_max_pos).max (0)
							l_max_viewport_pos := l_max_pos + l_viewport_len

							if l_max_viewport_pos = 0 then
								l_thumb_len := l_track_len
								l_thumb_start := 0
							else
								l_thumb_len := (((l_viewport_len * l_track_len) + (l_max_viewport_pos // 2)) // l_max_viewport_pos).min (l_track_len).max (1)
								l_thumb_start := (((l_start_pos * l_track_len) + (l_max_viewport_pos // 2)) // l_max_viewport_pos).min (l_track_len - l_thumb_len).max (0)
							end

							from
								k := 0
							until
								k >= l_strip_len
							loop
								if l_is_vert then
									cell_row := l_start_y + k
									cell_col := l_start_x
								else
									cell_row := l_start_y
									cell_col := l_start_x + k
								end

								l_sym := Void
								l_sym_style := track_style

								if l_has_begin and k = 0 then
									l_sym := begin_symbol
									l_sym_style := begin_style
								elseif l_has_end and k = l_strip_len - 1 then
									l_sym := end_symbol
									l_sym_style := end_style
								else
									k_track := k - (if l_has_begin then 1 else 0 end)
									if k_track >= l_thumb_start and k_track < l_thumb_start + l_thumb_len then
										l_sym := thumb_symbol
										l_sym_style := thumb_style
									else
										l_sym := track_symbol
										l_sym_style := track_style
									end
								end

								if attached l_sym as s and then not s.is_empty then
									if cell_row >= 0 and cell_row < a_buffer.height and cell_col >= 0 and cell_col < a_buffer.width then
										-- Clipped to this one cell, whatever the symbol
										a_buffer.set_string_clipped (cell_row, cell_col, s, cell_col, cell_col + 1, l_sym_style)
									end
								end

								k := k + 1
							end
						end
					end
				end
			end
		end

invariant
	valid_orientation: {SCROLLBAR_ORIENTATION}.is_valid (orientation)
	thumb_symbol_not_void: thumb_symbol /= Void
	one_column_thumb: is_valid_symbol (thumb_symbol)
	one_column_track: attached track_symbol as t implies is_valid_symbol (t)
	one_column_begin: attached begin_symbol as b implies is_valid_symbol (b)
	one_column_end: attached end_symbol as e implies is_valid_symbol (e)
	thumb_style_not_void: thumb_style /= Void
	track_style_not_void: track_style /= Void
	begin_style_not_void: begin_style /= Void
	end_style_not_void: end_style /= Void

end
