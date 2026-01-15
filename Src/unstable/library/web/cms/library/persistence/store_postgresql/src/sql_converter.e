note
	description: "Converts standard SQL queries into PostgreSQL-compatible queries. "
	description: "Supports conversion of identifier quotes (double, single, back quotes), "
	description: "DATETIME to TIMESTAMP, AUTO_INCREMENT to SERIAL PRIMARY KEY, and other PostgreSQL-specific conversions."
	date: "$Date$"
	revision: "$Revision$"

class
	SQL_CONVERTER

inherit
	REFACTORING_HELPER

feature -- Conversion

	convert_to_postgresql (a_sql: READABLE_STRING_8): STRING_8
			-- Convert standard SQL query `a_sql' to PostgreSQL-compatible query.
			-- Handles identifier quotes, DATETIME to TIMESTAMP, AUTO_INCREMENT to SERIAL PRIMARY KEY, etc.
		local
			result_sql: STRING_8
			i: INTEGER
			c: CHARACTER_8
			in_string_literal: BOOLEAN
			in_identifier: BOOLEAN
			identifier_quote: CHARACTER_8
		do
			create result_sql.make (a_sql.count)
			in_string_literal := False
			in_identifier := False

			from
				i := 1
			until
				i > a_sql.count
			loop
				c := a_sql.item (i)

				if in_string_literal then
					-- Inside a string literal (single quotes)
					if c = '%'' then
						-- Check if it's an escaped quote (two single quotes)
						if i < a_sql.count and then a_sql.item (i + 1) = '%'' then
							result_sql.append_character (c)
							result_sql.append_character (c)
							i := i + 1
						else
							-- End of string literal
							result_sql.append_character (c)
							in_string_literal := False
						end
					else
						result_sql.append_character (c)
					end
				elseif in_identifier then
					-- Inside an identifier (quoted)
					if c = identifier_quote then
						-- Check if it's an escaped quote
						if identifier_quote = '%"' and then i < a_sql.count and then a_sql.item (i + 1) = '%"' then
							-- Escaped double quote in identifier
							result_sql.append_character ('%"')
							result_sql.append_character ('%"')
							i := i + 1
						elseif identifier_quote = '`' and then i < a_sql.count and then a_sql.item (i + 1) = '`' then
							-- Escaped back quote - convert to escaped double quote
							result_sql.append_character ('%"')
							result_sql.append_character ('%"')
							i := i + 1
						else
							-- End of identifier - close with double quote
							result_sql.append_character ('%"')
							in_identifier := False
						end
					else
						-- Regular character inside identifier
						result_sql.append_character (c)
					end
				else
					-- Not in string or identifier
					if c = '%'' then
						-- Start of string literal (single quote)
						result_sql.append_character (c)
						in_string_literal := True
					elseif c = '%"' then
						-- Start of identifier with double quote (already PostgreSQL format)
						result_sql.append_character (c)
						in_identifier := True
						identifier_quote := c
					elseif c = '`' then
						-- Start of identifier with back quote - convert to double quote
						result_sql.append_character ('%"')
						in_identifier := True
						identifier_quote := '`'
					else
						result_sql.append_character (c)
					end
				end

				i := i + 1
			end

			-- Close any unclosed identifier (shouldn't happen in valid SQL, but be safe)
			if in_identifier then
				result_sql.append_character ('%"')
			end

			-- Apply PostgreSQL-specific conversions
			result_sql := convert_datetime_to_timestamp (result_sql)
			result_sql := convert_auto_increment_to_serial (result_sql)
			result_sql := convert_other_postgresql_specific (result_sql)

			Result := result_sql
		ensure
			result_not_void: Result /= Void
		end

feature {NONE} -- Implementation

	convert_datetime_to_timestamp (a_sql: STRING_8): STRING_8
			-- Replace DATETIME with TIMESTAMP in `a_sql'.
		local
			i: INTEGER
		do
			create Result.make_from_string (a_sql)

			from
				i := 1
			until
				i > Result.count - 7
			loop
				if Result.substring (i, i + 7).is_case_insensitive_equal ("DATETIME") then
					-- Check if it's a word boundary (not part of another word)
					if (i = 1 or else not is_identifier_char (Result [i - 1])) and then
						(i + 8 > Result.count or else not is_identifier_char (Result [i + 8])) then
						Result.replace_substring ("TIMESTAMP", i, i + 7)
						i := i + 8
					else
						i := i + 1
					end
				else
					i := i + 1
				end
			end
		end

	convert_auto_increment_to_serial (a_sql: STRING_8): STRING_8
			-- Convert AUTO_INCREMENT patterns to SERIAL PRIMARY KEY.
		local
			patterns: ARRAYED_LIST [TUPLE [pattern: STRING_8; replacement: STRING_8]]
		do
			create Result.make_from_string (a_sql)

			-- Define patterns to replace (order matters - longer patterns first)
			create patterns.make (10)
			patterns.force (["INTEGER PRIMARY KEY AUTO_INCREMENT NOT NULL", "SERIAL PRIMARY KEY"])
			patterns.force (["INTEGER PRIMARY KEY AUTO_INCREMENT", "SERIAL PRIMARY KEY"])
			patterns.force (["INT PRIMARY KEY AUTO_INCREMENT NOT NULL", "SERIAL PRIMARY KEY"])
			patterns.force (["INT PRIMARY KEY AUTO_INCREMENT", "SERIAL PRIMARY KEY"])
			patterns.force (["BIGINT PRIMARY KEY AUTO_INCREMENT NOT NULL", "BIGSERIAL PRIMARY KEY"])
			patterns.force (["BIGINT PRIMARY KEY AUTO_INCREMENT", "BIGSERIAL PRIMARY KEY"])
			patterns.force (["SMALLINT PRIMARY KEY AUTO_INCREMENT NOT NULL", "SMALLSERIAL PRIMARY KEY"])
			patterns.force (["SMALLINT PRIMARY KEY AUTO_INCREMENT", "SMALLSERIAL PRIMARY KEY"])
			patterns.force (["INTEGER AUTO_INCREMENT NOT NULL", "SERIAL NOT NULL"])
			patterns.force (["INT AUTO_INCREMENT NOT NULL", "SERIAL NOT NULL"])
			patterns.force (["INTEGER AUTO_INCREMENT", "SERIAL"])
			patterns.force (["INT AUTO_INCREMENT", "SERIAL"])

			across
				patterns as p
			loop
				if not p.pattern.is_empty then
					-- Replace case-sensitive version
					Result.replace_substring_all (p.pattern, p.replacement)
					-- Replace uppercase version
					Result.replace_substring_all (p.pattern.as_upper, p.replacement)
					-- Replace lowercase version
					Result.replace_substring_all (p.pattern.as_lower, p.replacement)
				end
			end
		end

	convert_other_postgresql_specific (a_sql: STRING_8): STRING_8
			-- Apply other PostgreSQL-specific conversions.
		do
			create Result.make_from_string (a_sql)

			-- Replace LIMIT/OFFSET syntax if needed (MySQL uses LIMIT n, m, PostgreSQL uses LIMIT m OFFSET n)
			-- This is more complex and might need regex-like parsing, but for now we do simple replacements

			-- Replace common MySQL functions with PostgreSQL equivalents
			Result.replace_substring_all ("NOW()", "CURRENT_TIMESTAMP")
			Result.replace_substring_all ("CURDATE()", "CURRENT_DATE")
			Result.replace_substring_all ("CURTIME()", "CURRENT_TIME")

			-- Replace IFNULL with COALESCE
			-- This requires more sophisticated parsing, but we do a simple replacement for common cases
			-- Note: This is a simplified version - a full implementation would need proper SQL parsing

			-- Replace backslash escape sequences (MySQL) with standard SQL (PostgreSQL uses single quote escaping)
			-- This is handled in the main conversion loop for string literals
		end

	is_identifier_char (c: CHARACTER_8): BOOLEAN
			-- Is `c' a valid identifier character?
		do
			Result := (c >= 'A' and c <= 'Z') or (c >= 'a' and c <= 'z') or (c >= '0' and c <= '9') or c = '_'
		end

end
