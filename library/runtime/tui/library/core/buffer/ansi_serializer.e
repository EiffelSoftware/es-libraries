note
	description: "[
		Serializes dirty spans into ANSI escape sequences and writes them
		through a TERMINAL_BACKEND, minimizing style transitions and cursor moves.
		Accumulates each frame in one STRING_8, wraps in synchronized output (?2026),
		and emits minimal SGR deltas.
		The frame is built in one buffer (`frame`) kept from frame to frame, and handed to the
		backend with the cursor position it ends at ({TERMINAL_BACKEND}.put_frame), so the
		backend does not decode and scan it again.
		Each span starts with an absolute cursor move, and so does every cell that follows a
		cell whose width terminals may see differently (`is_width_disputed`): the columns on
		screen then match the buffer, whatever width the terminal gave that cell.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	ANSI_SERIALIZER

feature -- Basic operations

	render_spans (a_spans: LIST [DIFF_SPAN]; a_backend: TERMINAL_BACKEND)
			-- Output all `a_spans` to `a_backend` with optimal style state changes.
		require
			spans_not_void: a_spans /= Void
			backend_not_void: a_backend /= Void
		do
			render_spans_with_offset (a_spans, a_backend, 0, 0)
		end

	render_spans_with_offset (a_spans: LIST [DIFF_SPAN]; a_backend: TERMINAL_BACKEND; a_offset_col, a_offset_row: INTEGER)
			-- Output all `a_spans` with (`a_offset_col`, `a_offset_row`) screen offset to `a_backend`.
		require
			spans_not_void: a_spans /= Void
			backend_not_void: a_backend /= Void
			non_negative_col: a_offset_col >= 0
			non_negative_row: a_offset_row >= 0
		local
			l_active_style: STYLE
			l_cell: TERMINAL_CELL
			i: INTEGER
			l_frame: STRING_8
			l_span: DIFF_SPAN
			l_reanchor: BOOLEAN
			l_end: detachable TUPLE [row, column: INTEGER]
			l_col, l_end_row, l_end_col: INTEGER
			l_wrote: BOOLEAN
		do
			l_frame := frame
			l_frame.wipe_out
			-- Start of synchronized update
			l_frame.append (Sync_start)
			-- Reset SGR explicitly at frame start
			l_frame.append (Reset_sgr)
			l_active_style := Default_style

			from
				a_spans.start
			until
				a_spans.after
			loop
				l_span := a_spans.item
				if l_span.count > 0 then
					append_cursor_move (l_frame, l_span.row + a_offset_row, l_span.start_col + a_offset_col)

					from
						i := 1
						l_reanchor := False
					until
						i > l_span.cells.count
					loop
						l_cell := l_span.cells.i_th (i)
						if not l_cell.is_continuation then
							l_col := l_span.start_col + i - 1 + a_offset_col
							if l_reanchor then
								-- The terminal may have given the previous cell another width
								-- than ours: put the cursor where this cell belongs
								append_cursor_move (l_frame, l_span.row + a_offset_row, l_col)
							end
							if l_cell.style /= l_active_style and then not l_cell.style.same_rendering (l_active_style) then
								emit_style_transition (l_frame, l_active_style, l_cell.style)
								l_active_style := l_cell.style
							end
							{UTF_CONVERTER}.string_32_into_utf_8_string_8 (l_cell.symbol, l_frame)
							l_reanchor := is_width_disputed (l_cell)
							-- The cursor is now after this cell (in the buffer's columns, which
							-- the re-anchoring moves keep the terminal to)
							l_end_row := l_span.row + a_offset_row
							l_end_col := l_col + l_cell.width.to_integer_32
							l_wrote := True
						end
						i := i + 1
					end
				end
				a_spans.forth
			end

			-- Reset terminal style if any styling was applied
			if not l_active_style.renders_as_default then
				l_frame.append (Reset_sgr)
			end
			-- End of synchronized update
			l_frame.append (Sync_end)

			if l_wrote then
				l_end := [l_end_row, l_end_col]
			end
			a_backend.put_frame (l_frame, l_end)
			a_backend.flush
		end

feature -- Access

	frame: STRING_8
			-- Output of the last `render_spans_with_offset`, reused (emptied, capacity kept)
			-- by the next one
		attribute
			create Result.make (1024)
		end

feature -- Status report

	is_width_disputed (a_cell: TERMINAL_CELL): BOOLEAN
			-- May a terminal draw `a_cell` in another number of columns than `a_cell.width`?
			-- True for wide cells and for clusters of more than one code point: terminals
			-- disagree on ZWJ sequences, VS16, flags, skin tones, combining and Indic marks,
			-- and on emoji their Unicode tables are too old to know. The serializer moves the
			-- cursor to the next cell's column after such a cell, so a disagreement cannot
			-- shift the rest of the span, and the diff cannot keep it on screen.
		do
			Result := a_cell.width = 2 or a_cell.symbol.count > 1
		ensure
			instance_free: class
		end

feature {NONE} -- Helpers

	append_cursor_move (a_target: STRING_8; a_row, a_col: INTEGER)
			-- Append ANSI 1-based cursor movement sequence to `a_target`.
		do
			a_target.append ("%/27/[")
			a_target.append_integer (a_row + 1)
			a_target.append_character (';')
			a_target.append_integer (a_col + 1)
			a_target.append_character ('H')
		end

	emit_style_transition (a_target: STRING_8; a_current, a_target_style: STYLE)
			-- Emit minimal SGR delta from `a_current` to `a_target_style`.
		local
			l_codes: STRING_8
			l_needs_reset: BOOLEAN
			l_new_flags_bits: NATURAL_16
			l_new_flags: STYLE_FLAGS
		do
			if a_target_style.renders_as_default then
				a_target.append (Reset_sgr)
			else
				-- Check if any flag was removed, or if foreground/background/underline was reset to default
				if (a_current.flags.bits & (a_target_style.flags.bits.bit_not)) /= 0 then
					l_needs_reset := True
				elseif not a_current.foreground.renders_as_default and a_target_style.foreground.renders_as_default then
					l_needs_reset := True
				elseif not a_current.background.renders_as_default and a_target_style.background.renders_as_default then
					l_needs_reset := True
				elseif not a_current.underline_color.renders_as_default and a_target_style.underline_color.renders_as_default then
					l_needs_reset := True
				end

				if l_needs_reset then
					-- Full transition with reset
					a_target.append (a_target_style.sgr_sequence)
				else
					-- Minimal delta: emit only what changed
					create l_codes.make (32)
					if not a_target_style.foreground.same_rendering (a_current.foreground) then
						append_code (l_codes, a_target_style.foreground.sgr_fg)
					end
					if not a_target_style.background.same_rendering (a_current.background) then
						append_code (l_codes, a_target_style.background.sgr_bg)
					end
					if not a_target_style.underline_color.same_rendering (a_current.underline_color) then
						append_code (l_codes, a_target_style.underline_color.sgr_ul)
					end
					l_new_flags_bits := a_target_style.flags.bits & (a_current.flags.bits.bit_not)
					if l_new_flags_bits /= 0 then
						create l_new_flags.make_with_bits (l_new_flags_bits)
						append_code (l_codes, l_new_flags.sgr_codes)
					end

					if not l_codes.is_empty then
						a_target.append ("%/27/[")
						a_target.append (l_codes)
						a_target.append_character ('m')
					end
				end
			end
		end

	append_code (a_target: STRING_8; a_code: STRING_8)
			-- Append `a_code` to `a_target`, adding a semicolon if not empty.
		do
			if not a_target.is_empty then
				a_target.append_character (';')
			end
			a_target.append (a_code)
		end

feature {NONE} -- Constants

	Reset_sgr: STRING_8 = "%/27/[0m"
			-- SGR reset code

	Sync_start: STRING_8 = "%/27/[?2026h"
			-- Synchronized output begin mode 2026

	Sync_end: STRING_8 = "%/27/[?2026l"
			-- Synchronized output end mode 2026

	Default_style: STYLE
			-- Baseline default style
		once
			create Result.default_create
		ensure
			instance_free: class
		end

end
