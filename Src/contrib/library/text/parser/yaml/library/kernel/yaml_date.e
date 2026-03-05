note
	description: "YAML timestamp scalar value (ISO 8601, canonical, spaced, date-only)."
	date: "$Date$"
	revision: "$Revision$"

class
	YAML_DATE

inherit
	YAML_SCALAR
		redefine
			is_date,
			same_string,
			same_caseless_string
		end

create
	make_from_string,
	make_from_date_time

convert
	make_from_date_time ({DATE_TIME})

feature {NONE} -- Initialization

	make_from_string (a_value: READABLE_STRING_GENERAL)
			-- Initialize with timestamp string `a_value`.
		require
			value_attached: a_value /= Void
			valid_format: is_timestamp_pattern (a_value)
		do
			text := a_value.to_string_8
			style := Style_plain
		ensure
			text_set: a_value.same_string (text)
			is_date: is_date
		end

	make_from_date_time (a_value: DATE_TIME)
			-- Initialize from `a_value`.
		require
			value_attached: a_value /= Void
		do
			text := a_value.formatted_out (default_format)
			style := Style_plain
		ensure
			is_date: is_date
		end

feature -- Access

	text: STRING_8
			-- Raw timestamp string value.

	value: detachable DATE_TIME
			-- Parsed date-time value.
		require
			can_parse: is_parseable
		local
			l_parsed: detachable DATE_TIME
		do
			l_parsed := parsed_value
			if l_parsed = Void then
				l_parsed := parse_timestamp (text)
				parsed_value := l_parsed
			end
			check l_parsed_attached: l_parsed /= Void end
			Result := l_parsed
		ensure
			result_attached: Result /= Void
		end

feature -- Conversion

	to_string_value: STRING_32
		do
			create Result.make_from_string_general (text)
		end

	to_date_time: detachable DATE_TIME
			-- Convert to DATE_TIME if parseable.
		do
			if is_parseable then
				Result := value
			end
		ensure
			parseable_implies_attached: is_parseable implies Result /= Void
		end

feature -- Status report

	is_date: BOOLEAN = True
			-- <Precursor>

	is_parseable: BOOLEAN
			-- Can `text` be parsed to DATE_TIME?
		do
			Result := parse_timestamp (text) /= Void
		end

	same_string (a_string: READABLE_STRING_GENERAL): BOOLEAN
			-- Current value is a string value, and same content as `a_string`?
		do
			Result := a_string.same_string (to_string_value)
		end

	same_caseless_string (a_string: READABLE_STRING_GENERAL): BOOLEAN
			-- Current value is a string value, and same caseless content as `a_string`?
		do
			Result := a_string.is_case_insensitive_equal (to_string_value)
		end

feature {NONE} -- Implementation

	parsed_value: detachable DATE_TIME
			-- Cached parsed value.

	default_format: STRING = "yyyy-[0]mm-[0]ddT[0]hh:[0]mi:[0]ss"
			-- Default ISO 8601 format for output.

	parse_timestamp (a_text: READABLE_STRING_GENERAL): detachable DATE_TIME
			-- Parse `a_text` to DATE_TIME if valid.
		local
			s: STRING_32
			y, mo, d, h, mi: INTEGER
			sec: DOUBLE
			i: INTEGER
			c: CHARACTER_32
			num: STRING_32
		do
			s := a_text.to_string_32
			s.left_adjust
			s.right_adjust
			if s.count >= 10 then
				-- Parse date part YYYY-MM-DD
				if s [1].is_digit and s [2].is_digit and s [3].is_digit and s [4].is_digit
					and s [5] = '-' and s [6].is_digit and s [7].is_digit
					and s [8] = '-' and s [9].is_digit and s [10].is_digit
				then
					y := substring_to_int (s, 1, 4)
					mo := substring_to_int (s, 6, 7)
					d := substring_to_int (s, 9, 10)
					if y >= 1 and y <= 9999 and mo >= 1 and mo <= 12 and d >= 1 and d <= 31 then
						h := 0
						mi := 0
						sec := 0.0
						if s.count > 10 then
							-- Parse time part: T or space
							i := 11
							if s [11] = 'T' or s [11] = 't' or s [11] = ' ' then
								i := 12
								if s.count >= 19 and s [12].is_digit and s [13].is_digit
									and s [14] = ':' and s [15].is_digit and s [16].is_digit
									and s [17] = ':' and s [18].is_digit and s [19].is_digit
								then
									h := substring_to_int (s, 12, 13)
									mi := substring_to_int (s, 15, 16)
									sec := substring_to_int (s, 18, 19).to_double
									i := 20
									-- Fractional seconds
									if i <= s.count and then s [i] = '.' then
										i := i + 1
										create num.make_empty
										from
										until
											i > s.count or not s [i].is_digit
										loop
											num.append_character (s [i])
											i := i + 1
										end
										if not num.is_empty then
											sec := sec + num.to_double / (10.0 ^ num.count)
										end
									end
									-- Skip timezone (Z, +HH:MM, -HH:MM, +HHMM, -HHMM, +H, -5)
									if i <= s.count then
										c := s [i]
										if c = 'Z' or c = 'z' then
											-- UTC, no adjustment
										elseif (c = '+' or c = '-') and i < s.count then
											-- Timezone offset: ignore for local time
											-- Full implementation would adjust h, mi
										end
									end
								end
							end
						end
						if (create {DATE_TIME}.make (1, 1, 1, 0, 0, 0)).is_correct_date_time (y, mo, d, h, mi, sec, False) then
							create Result.make_fine (y, mo, d, h, mi, sec)
						end
					end
				end
			end
		end

	substring_to_int (s: READABLE_STRING_32; start_index, end_index: INTEGER): INTEGER
			-- Parse integer from `s` [start_index..end_index].
		local
			i: INTEGER
		do
			from
				i := start_index
			until
				i > end_index or i > s.count
			loop
				if s [i].is_digit then
					Result := Result * 10 + (s [i].code - ('0').code)
				end
				i := i + 1
			end
		end

feature {NONE} -- Validation

	is_timestamp_pattern (s: READABLE_STRING_GENERAL): BOOLEAN
			-- Does `s` match YYYY-MM-DD or YYYY-MM-DD(T| )HH:MM:SS...?
		do
			if s.count >= 10 then
				Result := s [1].is_digit and s [2].is_digit and s [3].is_digit and s [4].is_digit
					and s [5] = '-' and s [6].is_digit and s [7].is_digit
					and s [8] = '-' and s [9].is_digit and s [10].is_digit
			end
		end

invariant
	text_attached: text /= Void

note
	copyright: "Copyright (c) 1984-2026, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"
end
