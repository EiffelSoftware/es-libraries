note
	description: "Helper routines used by Markdown parsing and structure."

class
	MD_HELPER

feature -- Lines

	index_of_end_of_line (s: READABLE_STRING_8; i: INTEGER): INTEGER
			-- Index of last character of the line starting at `i` (excluding `%N`).
		require
			valid_start_index: i >= 1 and i <= s.count + 1
		local
			p: INTEGER
		do
			if i > s.count then
				Result := s.count
			else
				p := s.index_of ('%N', i)
				if p > 0 then
					Result := p - 1
				else
					Result := s.count
				end
			end
		ensure
			result_in_range: Result >= 0 and Result <= s.count
		end

	current_line (s: READABLE_STRING_8; i: INTEGER): READABLE_STRING_8
			-- Line substring from `i` to end of line (excluding `%N`).
		require
			valid_start_index: i >= 1 and i <= s.count + 1
		do
			if i > s.count then
				Result := ""
			else
				Result := s.substring (i, index_of_end_of_line (s, i))
			end
		end

feature -- Whitespace

	is_blank_string (s: READABLE_STRING_GENERAL): BOOLEAN
			-- Is `s` empty or made only of spaces/tabs/newlines?
		local
			i, n: INTEGER
			c: CHARACTER_32
		do
			from
				Result := True
				i := 1
				n := s.count
			until
				i > n or not Result
			loop
				c := s [i]
				inspect c
				when ' ', '%T', '%N', '%R' then
					-- Still blank.
				else
					Result := False
				end
				i := i + 1
			end
		end

	leading_blanks_count (s: READABLE_STRING_8): INTEGER
			-- Number of leading blanks (spaces or tabs) in `s`.
		local
			i, n: INTEGER
			c: CHARACTER
		do
			from
				i := 1
				n := s.count
			until
				i > n
			loop
				c := s [i]
				if c = ' ' or c = '%T' then
					Result := Result + 1
					i := i + 1
				else
					i := n + 1
				end
			end
		ensure
			non_negative: Result >= 0
		end

	trimmed (s: READABLE_STRING_8): READABLE_STRING_8
			-- `s` without leading blanks (spaces or tabs).
		do
			Result := right_trimmed (left_trimmed (s))
		end

	left_trimmed (s: READABLE_STRING_8): READABLE_STRING_8
			-- `s` without leading blanks (spaces or tabs).
		local
			i, n: INTEGER
		do
			from
				i := 1
				n := s.count
			until
				i > n or else (s [i] /= ' ' and s [i] /= '%T')
			loop
				i := i + 1
			end
			if i <= n then
				Result := s.substring (i, n)
			else
				Result := ""
			end
		end

	right_trimmed (s: READABLE_STRING_8): READABLE_STRING_8
			-- `s` without trailing blanks (spaces, tabs, or `%R`).
		local
			i: INTEGER
		do
			from
				i := s.count
			until
				i <= 0 or else (s [i] /= ' ' and s [i] /= '%T' and s [i] /= '%R')
			loop
				i := i - 1
			end
			if i > 0 then
				Result := s.substring (1, i)
			else
				Result := ""
			end
		end

feature -- Matching

	starts_with_at (s: READABLE_STRING_8; a_position: INTEGER; a_prefix: READABLE_STRING_8): BOOLEAN
			-- Does `s` contain `a_prefix` starting at `a_position`?
		require
			valid_position: a_position >= 1 and a_position <= s.count + 1
		local
			i, n: INTEGER
		do
			n := a_prefix.count
			if n = 0 then
				Result := True
			elseif a_position + n - 1 <= s.count then
				from
					Result := True
					i := 1
				until
					i > n or not Result
				loop
					Result := s [a_position + i - 1] = a_prefix [i]
					i := i + 1
				end
			end
		end

end

