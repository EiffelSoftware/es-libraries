note
	description: "[
		Text layout engine providing wrapping (none, character, word) with span style
		preservation, leading whitespace trimming, and alignment calculation.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEXT_LAYOUT

feature -- Alignment calculation

	aligned_offset (a_line_width, a_area_width: NATURAL_16; a_alignment: NATURAL_8): NATURAL_16
			-- Starting column offset for a line of width `a_line_width` inside area of width `a_area_width`.
		require
			valid_align: {TEXT_ALIGNMENT}.is_valid (a_alignment)
		do
			if a_line_width >= a_area_width then
				Result := 0
			elseif a_alignment = {TEXT_ALIGNMENT}.center then
				Result := (a_area_width - a_line_width) // 2
			elseif a_alignment = {TEXT_ALIGNMENT}.right then
				Result := a_area_width - a_line_width
			else
				Result := 0
			end
		ensure
			instance_free: class
			within_bounds: Result + a_line_width <= a_area_width or a_line_width >= a_area_width
		end

feature -- Wrapping

	wrap_text (a_text: TEXT; a_max_width: NATURAL_16; a_mode: NATURAL_8; a_trim: BOOLEAN): ARRAYED_LIST [TEXT_LINE]
			-- Wrap all lines in `a_text` according to `a_mode` and `a_max_width`.
		require
			text_not_void: a_text /= Void
			valid_mode: {TEXT_WRAP_MODE}.is_valid (a_mode)
		local
			l_wrapped: ARRAYED_LIST [TEXT_LINE]
		do
			create Result.make (a_text.line_count.max (1))
			across
				a_text.lines as l
			loop
				l_wrapped := wrap_line (l, a_max_width, a_mode, a_trim)
				across
					l_wrapped as wl
				loop
					Result.extend (wl)
				end
			end
		ensure
			instance_free: class
			result_not_void: Result /= Void
		end

	wrap_line (a_line: TEXT_LINE; a_max_width: NATURAL_16; a_mode: NATURAL_8; a_trim: BOOLEAN): ARRAYED_LIST [TEXT_LINE]
			-- Wrap a single `a_line` according to `a_mode` within `a_max_width`.
			-- Spans are measured one by one; that matches the width of the joined output
			-- because no grapheme cluster straddles two spans ({TEXT_LINE}.no_split_cluster).
		require
			line_not_void: a_line /= Void
			valid_mode: {TEXT_WRAP_MODE}.is_valid (a_mode)
		do
			if a_mode = {TEXT_WRAP_MODE}.none or a_max_width = 0 or a_line.is_empty then
				create Result.make (1)
				Result.extend (a_line)
			elseif a_mode = {TEXT_WRAP_MODE}.character then
				Result := wrap_line_character (a_line, a_max_width, a_trim)
			else
				Result := wrap_line_word (a_line, a_max_width, a_trim)
			end
		ensure
			instance_free: class
			result_not_void: Result /= Void
		end

feature {NONE} -- Implementation: Character Wrapping

	wrap_line_character (a_line: TEXT_LINE; a_max_width: NATURAL_16; a_trim: BOOLEAN): ARRAYED_LIST [TEXT_LINE]
			-- Wrap `a_line` strictly by display width, one grapheme cluster at a time
			-- (see {UNICODE_WIDTH}.grapheme_end), the same way BUFFER places text.
			-- Lines break only between clusters, and no code point is dropped: zero-width
			-- clusters (combining marks, format characters, controls) stay with the line
			-- they follow. With `a_trim', a lone space or tab at the start of a line is skipped.
		local
			l_res: ARRAYED_LIST [TEXT_LINE]
			l_curr_line: TEXT_LINE
			l_curr_width: NATURAL_16
			l_span: TEXT_SPAN
			l_content: READABLE_STRING_32
			l_cw: NATURAL_16
			i, l_end, s_idx: INTEGER
			l_acc_str: STRING_32
		do
			create l_res.make (2)
			create l_curr_line.make_empty
			l_curr_line.set_alignment (a_line.alignment)
			l_curr_line.set_style (a_line.style)
			l_curr_width := 0

			from
				s_idx := 1
			until
				s_idx > a_line.spans.count
			loop
				l_span := a_line.spans.i_th (s_idx)
				l_content := l_span.content
				create l_acc_str.make (l_span.count)

				from
					i := 1
				until
					i > l_content.count
				loop
					l_end := {UNICODE_WIDTH}.grapheme_end (l_content, i)
					l_cw := cluster_width (l_content, i, l_end)

					if l_cw > 0 and l_curr_width + l_cw > a_max_width and l_curr_width > 0 then
						-- Flush accumulated clusters of the current span
						if not l_acc_str.is_empty then
							l_curr_line.append_text (l_acc_str, l_span.style)
							create l_acc_str.make (l_content.count - i + 1)
						end
						l_res.extend (l_curr_line)
						create l_curr_line.make_empty
						l_curr_line.set_alignment (a_line.alignment)
						l_curr_line.set_style (a_line.style)
						l_curr_width := 0
					end

					if l_curr_width = 0 and a_trim and is_blank_cluster (l_content, i, l_end) then
						-- Skip leading whitespace on the line
					else
						l_acc_str.append_substring (l_content, i, l_end)
						l_curr_width := l_curr_width + l_cw
					end
					i := l_end + 1
				end

				if not l_acc_str.is_empty then
					l_curr_line.append_text (l_acc_str, l_span.style)
				end

				s_idx := s_idx + 1
			end

			if not l_curr_line.is_empty or l_res.is_empty then
				l_res.extend (l_curr_line)
			end

			Result := l_res
		ensure
			instance_free: class
		end

feature {NONE} -- Implementation: Word Wrapping

	wrap_line_word (a_line: TEXT_LINE; a_max_width: NATURAL_16; a_trim: BOOLEAN): ARRAYED_LIST [TEXT_LINE]
			-- Wrap `a_line` at whitespace boundaries where possible.
			-- Words and runs of whitespace are made of whole grapheme clusters and measured
			-- cluster by cluster (see `cluster_width'), so they have the width BUFFER draws.
		local
			l_res: ARRAYED_LIST [TEXT_LINE]
			l_curr_line: TEXT_LINE
			l_curr_width: NATURAL_16
			l_span: TEXT_SPAN
			l_content: READABLE_STRING_32
			l_tok_width: NATURAL_16
			i, l_end, s_idx: INTEGER
			l_tok_str: STRING_32
			l_tok_is_space: BOOLEAN
			l_tok_done: BOOLEAN
		do
			create l_res.make (2)
			create l_curr_line.make_empty
			l_curr_line.set_alignment (a_line.alignment)
			l_curr_line.set_style (a_line.style)
			l_curr_width := 0

			from
				s_idx := 1
			until
				s_idx > a_line.spans.count
			loop
				l_span := a_line.spans.i_th (s_idx)
				l_content := l_span.content
				from
					i := 1
				until
					i > l_content.count
				loop
					-- Extract one token (consecutive whitespace or consecutive non-whitespace clusters)
					l_end := {UNICODE_WIDTH}.grapheme_end (l_content, i)
					l_tok_is_space := is_blank_cluster (l_content, i, l_end)
					create l_tok_str.make (8)
					l_tok_width := 0
					l_tok_done := False

					from
					until
						i > l_content.count or l_tok_done
					loop
						l_end := {UNICODE_WIDTH}.grapheme_end (l_content, i)
						if is_blank_cluster (l_content, i, l_end) /= l_tok_is_space then
							l_tok_done := True
						else
							l_tok_str.append_substring (l_content, i, l_end)
							l_tok_width := l_tok_width + cluster_width (l_content, i, l_end)
							i := l_end + 1
						end
					end

					-- Process token
					if l_tok_is_space then
						if l_curr_width = 0 and a_trim then
							-- Trim leading whitespace on new line
						elseif l_curr_width + l_tok_width <= a_max_width then
							l_curr_line.append_text (l_tok_str, l_span.style)
							l_curr_width := l_curr_width + l_tok_width
						else
							-- Space exceeds line; finish line
							finish_word_line (l_res, l_curr_line, a_trim)
							create l_curr_line.make_empty
							l_curr_line.set_alignment (a_line.alignment)
							l_curr_line.set_style (a_line.style)
							l_curr_width := 0
						end
					else
						-- Non-space token (word)
						if l_curr_width + l_tok_width <= a_max_width then
							l_curr_line.append_text (l_tok_str, l_span.style)
							l_curr_width := l_curr_width + l_tok_width
						else
							-- Word doesn't fit on current line
							if l_curr_width > 0 then
								finish_word_line (l_res, l_curr_line, a_trim)
								create l_curr_line.make_empty
								l_curr_line.set_alignment (a_line.alignment)
								l_curr_line.set_style (a_line.style)
								l_curr_width := 0
							end

							if l_tok_width <= a_max_width then
								-- Fits on a fresh line
								l_curr_line.append_text (l_tok_str, l_span.style)
								l_curr_width := l_tok_width
							else
								-- Word is larger than maximum line width: split by character
								l_curr_line := append_oversized_word (l_res, l_curr_line, l_tok_str, l_span.style, a_max_width, a_line.alignment, a_line.style)
								l_curr_width := l_curr_line.width
							end
						end
					end
				end

				s_idx := s_idx + 1
			end

			if not l_curr_line.is_empty or l_res.is_empty then
				finish_word_line (l_res, l_curr_line, a_trim)
			end

			Result := l_res
		ensure
			instance_free: class
		end

	finish_word_line (a_res: ARRAYED_LIST [TEXT_LINE]; a_line: TEXT_LINE; a_trim: BOOLEAN)
			-- Trim trailing whitespace if requested and add `a_line` to `a_res`.
		do
			if a_trim then
				a_line.right_adjust
			end
			a_res.extend (a_line)
		ensure
			instance_free: class
		end

	append_oversized_word (a_res: ARRAYED_LIST [TEXT_LINE]; a_curr_line: TEXT_LINE; a_word: STRING_32; a_style: STYLE; a_max_width: NATURAL_16; a_align: NATURAL_8; a_line_style: STYLE): TEXT_LINE
			-- Break oversized `a_word` across lines, between grapheme clusters only.
			-- No code point is dropped: zero-width clusters stay with the line they follow.
		local
			k, l_end: INTEGER
			l_cw: NATURAL_16
			l_acc: STRING_32
			l_cw_acc: NATURAL_16
			l_line: TEXT_LINE
		do
			l_line := a_curr_line
			create l_acc.make (a_word.count)
			l_cw_acc := l_line.width
			from
				k := 1
			until
				k > a_word.count
			loop
				l_end := {UNICODE_WIDTH}.grapheme_end (a_word, k)
				l_cw := cluster_width (a_word, k, l_end)
				if l_cw > 0 and l_cw_acc + l_cw > a_max_width and l_cw_acc > 0 then
					if not l_acc.is_empty then
						l_line.append_text (l_acc, a_style)
						create l_acc.make (a_word.count - k + 1)
					end
					a_res.extend (l_line)
					create l_line.make_empty
					l_line.set_alignment (a_align)
					l_line.set_style (a_line_style)
					l_cw_acc := 0
				end
				l_acc.append_substring (a_word, k, l_end)
				l_cw_acc := l_cw_acc + l_cw
				k := l_end + 1
			end
			if not l_acc.is_empty then
				l_line.append_text (l_acc, a_style)
			end
			Result := l_line
		ensure
			instance_free: class
		end

feature {NONE} -- Implementation: Grapheme clusters

	cluster_width (a_string: READABLE_STRING_32; a_start, a_end: INTEGER): NATURAL_16
			-- Display width of the grapheme cluster `a_string' [`a_start', `a_end'],
			-- measured as BUFFER measures it when drawing.
		require
			valid_range: a_start >= 1 and a_start <= a_end and a_end <= a_string.count
		do
			if a_end = a_start then
				Result := {UNICODE_WIDTH}.width (a_string.code (a_start)).to_natural_16
			else
				Result := {UNICODE_WIDTH}.grapheme_width (a_string.substring (a_start, a_end)).to_natural_16
			end
		ensure
			instance_free: class
		end

	is_blank_cluster (a_string: READABLE_STRING_32; a_start, a_end: INTEGER): BOOLEAN
			-- Is the grapheme cluster `a_string' [`a_start', `a_end'] a lone space or tab?
			-- (A space carrying a combining mark is not blank.)
		require
			valid_range: a_start >= 1 and a_start <= a_end and a_end <= a_string.count
		do
			Result := a_end = a_start and then (a_string [a_start] = ' ' or a_string [a_start] = '%T')
		ensure
			instance_free: class
		end

end
