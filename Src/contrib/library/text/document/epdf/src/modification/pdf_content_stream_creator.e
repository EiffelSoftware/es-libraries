note
	description: "[
		Creates PDF content streams for page content.
		Generates proper PDF graphics operators per ISO 32000-1:2008 §A.2.
		Handles text positioning, font selection, and text rendering.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_CONTENT_STREAM_CREATOR

create
	make

feature -- Initialization

	make
			-- Create content stream creator.
		do
			create buffer.make (1024)
		ensure
			buffer_created: buffer /= Void
		end

feature {NONE} -- Implementation

	buffer: STRING_8
			-- Internal buffer for building content stream.

feature -- Content Generation

	create_footer_stream (a_text: STRING_8; a_font_name: STRING_8; a_font_size: REAL_64; a_x: REAL_64; a_y: REAL_64): PDF_STREAM
			-- Create content stream for footer text.
			-- Per ISO 32000-1:2008 §9.4, text is shown using text operators.
		require
			text_valid: a_text /= Void and then not a_text.is_empty
			font_name_valid: a_font_name /= Void and then not a_font_name.is_empty
			font_size_positive: a_font_size > 0.0
		local
			content: STRING_8
			stream: PDF_STREAM
			escaped_text: STRING_8
		do
				-- Clear buffer
			buffer.wipe_out

				-- Save graphics state to isolate from prior transformations
				-- Per ISO 32000-1:2008 §8.4.2, q/Q operators save/restore graphics state
			buffer.append ("q%N")

				-- Begin text object (BT operator)
			buffer.append ("BT%N")

				-- Set font and size (Tf operator)
				-- Format: /FontName size Tf
			buffer.append ("/")
			buffer.append (a_font_name)
			buffer.append (" ")
			buffer.append (format_real (a_font_size))
			buffer.append (" Tf%N")

				-- Set text position (Td operator)
				-- Format: x y Td
			buffer.append (format_real (a_x))
			buffer.append (" ")
			buffer.append (format_real (a_y))
			buffer.append (" Td%N")

				-- Show text (Tj operator)
				-- Format: (text) Tj
			escaped_text := escape_text (a_text)
			buffer.append ("(")
			buffer.append (escaped_text)
			buffer.append (") Tj%N")

				-- End text object (ET operator)
			buffer.append ("ET%N")

				-- Restore graphics state
			buffer.append ("Q%N")

				-- Create stream object
			create content.make_from_string (buffer)
			create stream.make (content)

			Result := stream
		ensure
			result_attached: Result /= Void
		end

	create_multiline_footer_stream (a_lines: ARRAYED_LIST [STRING_8]; a_font_name: STRING_8; a_font_size: REAL_64; a_x_positions: ARRAYED_LIST [REAL_64]; a_y_positions: ARRAYED_LIST [REAL_64]): PDF_STREAM
			-- Create content stream for multi-line footer text.
			-- Per ISO 32000-1:2008 §9.4, text is shown using text operators.
		require
			lines_attached: a_lines /= Void
			lines_not_empty: not a_lines.is_empty
			font_name_valid: a_font_name /= Void and then not a_font_name.is_empty
			font_size_positive: a_font_size > 0.0
			x_positions_attached: a_x_positions /= Void
			x_positions_count_match: a_x_positions.count = a_lines.count
			y_positions_attached: a_y_positions /= Void
			y_positions_count_match: a_y_positions.count = a_lines.count
		local
			content: STRING_8
			stream: PDF_STREAM
			i: INTEGER
		do
				-- Clear buffer
			buffer.wipe_out

				-- Save graphics state to isolate from prior transformations
			buffer.append ("q%N")

			from
				i := 1
			until
				i > a_lines.count
			loop
					-- Begin text object (BT operator)
				buffer.append ("BT%N")

					-- Set font and size (Tf operator)
				buffer.append ("/")
				buffer.append (a_font_name)
				buffer.append (" ")
				buffer.append (format_real (a_font_size))
				buffer.append (" Tf%N")

					-- Set text position (Td operator)
				buffer.append (format_real (a_x_positions [i]))
				buffer.append (" ")
				buffer.append (format_real (a_y_positions [i]))
				buffer.append (" Td%N")

					-- Show text (Tj operator)
				buffer.append ("(")
				buffer.append (escape_text (a_lines [i]))
				buffer.append (") Tj%N")

					-- End text object (ET operator)
				buffer.append ("ET%N")
				
				i := i + 1
			end

				-- Restore graphics state
			buffer.append ("Q%N")

				-- Create stream object
			create content.make_from_string (buffer)
			create stream.make (content)

			Result := stream
		ensure
			result_attached: Result /= Void
		end

	create_text_stream (a_text: STRING_8; a_font_name: STRING_8; a_font_size: REAL_64; a_x: REAL_64; a_y: REAL_64; a_red: REAL_64; a_green: REAL_64; a_blue: REAL_64): PDF_STREAM
			-- Create content stream for text with color.
			-- Per ISO 32000-1:2008 §8.6.8, colors are set using rg operator for RGB.
		require
			text_valid: a_text /= Void and then not a_text.is_empty
			font_name_valid: a_font_name /= Void and then not a_font_name.is_empty
			font_size_positive: a_font_size > 0.0
			red_valid: a_red >= 0.0 and a_red <= 1.0
			green_valid: a_green >= 0.0 and a_green <= 1.0
			blue_valid: a_blue >= 0.0 and a_blue <= 1.0
		local
			content: STRING_8
			stream: PDF_STREAM
			escaped_text: STRING_8
		do
				-- Clear buffer
			buffer.wipe_out

				-- Set fill color (rg operator for RGB)
				-- Format: r g b rg
			buffer.append (format_real (a_red))
			buffer.append (" ")
			buffer.append (format_real (a_green))
			buffer.append (" ")
			buffer.append (format_real (a_blue))
			buffer.append (" rg%N")

				-- Begin text object (BT operator)
			buffer.append ("BT%N")

				-- Set font and size (Tf operator)
			buffer.append ("/")
			buffer.append (a_font_name)
			buffer.append (" ")
			buffer.append (format_real (a_font_size))
			buffer.append (" Tf%N")

				-- Set text position (Td operator)
			buffer.append (format_real (a_x))
			buffer.append (" ")
			buffer.append (format_real (a_y))
			buffer.append (" Td%N")

				-- Show text (Tj operator)
			escaped_text := escape_text (a_text)
			buffer.append ("(")
			buffer.append (escaped_text)
			buffer.append (") Tj%N")

				-- End text object (ET operator)
			buffer.append ("ET%N")

				-- Create stream object
			create content.make_from_string (buffer)
			create stream.make (content)

			Result := stream
		ensure
			result_attached: Result /= Void
		end

	create_multiline_text_stream (a_lines: ITERABLE [STRING_8]; a_font_name: STRING_8; a_font_size: REAL_64; a_x: REAL_64; a_y: REAL_64; a_line_spacing: REAL_64; a_red: REAL_64; a_green: REAL_64; a_blue: REAL_64): PDF_STREAM
			-- Create content stream for multiline text.
		require
			font_name_not_empty: not a_font_name.is_empty
			font_size_positive: a_font_size > 0.0
			line_spacing_positive: a_line_spacing > 0.0
			red_valid: a_red >= 0.0 and a_red <= 1.0
			green_valid: a_green >= 0.0 and a_green <= 1.0
			blue_valid: a_blue >= 0.0 and a_blue <= 1.0
		local
			content: STRING_8
			stream: PDF_STREAM
			escaped_text: STRING_8
			is_first_line: BOOLEAN
		do
				-- Clear buffer
			buffer.wipe_out

				-- Set fill color (rg operator for RGB)
			buffer.append (format_real (a_red))
			buffer.append (" ")
			buffer.append (format_real (a_green))
			buffer.append (" ")
			buffer.append (format_real (a_blue))
			buffer.append (" rg%N")

				-- Begin text object (BT operator)
			buffer.append ("BT%N")

				-- Set font and size (Tf operator)
			buffer.append ("/")
			buffer.append (a_font_name)
			buffer.append (" ")
			buffer.append (format_real (a_font_size))
			buffer.append (" Tf%N")

				-- Render each line, moving Y down by line spacing
			is_first_line := True
			across a_lines as cursor loop
				if is_first_line then
					buffer.append (format_real (a_x))
					buffer.append (" ")
					buffer.append (format_real (a_y))
					buffer.append (" Td%N")
					is_first_line := False
				else
					buffer.append ("0 ")
					buffer.append (format_real (-a_line_spacing))
					buffer.append (" Td%N")
				end

				escaped_text := escape_text (cursor)
				buffer.append ("(")
				buffer.append (escaped_text)
				buffer.append (") Tj%N")
			end

				-- End text object (ET operator)
			buffer.append ("ET%N")

				-- Create stream object
			create content.make_from_string (buffer)
			create stream.make (content)

			Result := stream
		ensure
			result_attached: Result /= Void
		end

feature {NONE} -- Formatting

	format_real (a_value: REAL_64): STRING_8
			-- Format real number for PDF output.
			-- Removes unnecessary trailing zeros and decimal point.
		local
			str: STRING_8
			i: INTEGER
		do
			str := a_value.out

				-- Remove trailing zeros after decimal point
			if str.has ('.') then
				from
					i := str.count
				until
					i <= 0 or else (str [i] /= '0' and str [i] /= '.')
				loop
					if str [i] = '.' then
						str.remove_tail (str.count - i + 1)
						i := 0
					elseif str [i] = '0' then
						str.remove_tail (1)
						i := i - 1
					end
				end
			end

			Result := str
		ensure
			result_attached: Result /= Void
		end

	escape_text (a_text: STRING_8): STRING_8
			-- Escape text for PDF literal string.
			-- Per ISO 32000-1:2008 §7.3.4.2, escape special characters.
		require
			text_valid: a_text /= Void
		local
			i: INTEGER
			c: CHARACTER
		do
			create Result.make (a_text.count * 2)

			from
				i := 1
			until
				i > a_text.count
			loop
				c := a_text [i]

				inspect c
				when '(' then
					Result.append ("\(")
				when ')' then
					Result.append ("\)")
				when '\' then
					Result.append ("\\")
				when '%N' then
					Result.append ("\n")
				when '%R' then
					Result.append ("\r")
				when '%T' then
					Result.append ("\t")
				else
						-- Check for non-printable characters
					if c.code < 32 or c.code > 126 then
							-- Use octal escape
						Result.append ("\")
						Result.append (octal_escape (c.code))
					else
						Result.append_character (c)
					end
				end

				i := i + 1
			end
		ensure
			result_attached: Result /= Void
		end

feature -- Resilient Watermarking

	create_scrambled_line_operators (a_text: STRING_8; a_font_name: STRING_8; a_font_size: REAL_64; a_x: REAL_64; a_y: REAL_64): STRING_8
			-- Generate scrambled character operators to render `a_text` at `a_x`, `a_y`.
		require
			text_valid: a_text /= Void and then not a_text.is_empty
			font_name_valid: a_font_name /= Void and then not a_font_name.is_empty
			font_size_positive: a_font_size > 0.0
		local
			char_positions: ARRAYED_LIST [REAL_64]
			shuffled_indices: ARRAYED_LIST [INTEGER]
			current_x: REAL_64
			dx: REAL_64
			i: INTEGER
			idx: INTEGER
			escaped: STRING_8
		do
			-- 1. Compute absolute positions for each character
			create char_positions.make (a_text.count)
			current_x := a_x
			from
				i := 1
			until
				i > a_text.count
			loop
				char_positions.extend (current_x)
				current_x := current_x + helvetica_char_width (a_text [i]) * a_font_size
				i := i + 1
			end

			-- 2. Shuffle indices
			shuffled_indices := shuffle_indices (a_text.count)

			-- 3. Build text operators
			create Result.make (256)
			Result.append ("BT%N")
			Result.append ("/")
			Result.append (a_font_name)
			Result.append (" ")
			Result.append (format_real (a_font_size))
			Result.append (" Tf%N")

			-- Set initial text position relative to line origin
			Result.append (format_real (a_x))
			Result.append (" ")
			Result.append (format_real (a_y))
			Result.append (" Td%N")

			-- current_x tracks the current text line matrix position relative to origin
			current_x := a_x

			from
				i := 1
			until
				i > shuffled_indices.count
			loop
				idx := shuffled_indices [i]
				dx := char_positions [idx] - current_x
				
				if dx /= 0.0 then
					Result.append (format_real (dx))
					Result.append (" 0 Td%N")
					current_x := char_positions [idx]
				end
				
				create escaped.make (1)
				escaped.append_character (a_text [idx])
				escaped := escape_text (escaped)
				
				Result.append ("(")
				Result.append (escaped)
				Result.append (") Tj%N")
				
				i := i + 1
			end

			Result.append ("ET%N")
		ensure
			result_attached: Result /= Void
		end

	shuffle_indices (n: INTEGER): ARRAYED_LIST [INTEGER]
			-- Generate a shuffled list of indices from 1 to n deterministically.
		local
			i, swap_idx, temp, seed: INTEGER
		do
			create Result.make (n)
			from
				i := 1
			until
				i > n
			loop
				Result.extend (i)
				i := i + 1
			end

			seed := n
			from
				i := n
			until
				i <= 1
			loop
				seed := (seed * 13 + 7) \\ 997
				swap_idx := (seed \\ i) + 1
				temp := Result [i]
				Result [i] := Result [swap_idx]
				Result [swap_idx] := temp
				i := i - 1
			end
		end

	helvetica_char_width (c: CHARACTER_8): REAL_64
			-- Width of character `c` in Helvetica (for font size 1.0).
		do
			inspect c
			when 'i', 'j', 'l' then
				Result := 0.222
			when ' ', '!', ',', '.', '/', ':', ';', '[', '\', ']', 'f', 't', 'I' then
				Result := 0.278
			when 'r', '(', ')', '-' then
				Result := 0.333
			when 'c', 'k', 's', 'v', 'x', 'y', 'z', 'J', '?' then
				Result := 0.500
			when 'a', 'b', 'd', 'e', 'g', 'h', 'n', 'o', 'p', 'q', 'u', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '$', 'L', '_', '^' then
				Result := 0.556
			when 'F', 'T', 'Z' then
				Result := 0.611
			when 'A', 'B', 'E', 'K', 'P', 'R', 'S', 'V', 'X', 'Y', '&' then
				Result := 0.667
			when 'C', 'D', 'H', 'N', 'U', 'w' then
				Result := 0.722
			when 'G', 'O', 'Q', '@' then
				Result := 0.778
			when 'M', 'm' then
				Result := 0.833
			when 'W' then
				Result := 0.944
			when '%%' then
				Result := 0.889
			else
				Result := 0.550 -- Default average
			end
		end


	octal_escape (a_code: INTEGER): STRING_8
			-- Convert character code to octal escape sequence.
			-- Format: ddd (three octal digits)
		require
			valid_code: a_code >= 0 and a_code <= 255
		local
			d1, d2, d3: INTEGER
		do
			d1 := a_code // 64
			d2 := (a_code \\ 64) // 8
			d3 := a_code \\ 8

			create Result.make (3)
			Result.append_character ((d1 + 48).to_character_8)
			Result.append_character ((d2 + 48).to_character_8)
			Result.append_character ((d3 + 48).to_character_8)
		ensure
			result_length: Result.count = 3
		end

invariant
	buffer_attached: buffer /= Void

end
