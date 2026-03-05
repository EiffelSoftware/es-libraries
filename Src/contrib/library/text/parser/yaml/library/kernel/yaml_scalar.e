note
	description: "YAML scalar value (string, number, boolean, null)."
	date: "$Date$"
	revision: "$Revision$"

deferred class
	YAML_SCALAR

inherit
	YAML_VALUE
		redefine
			is_scalar,
			is_null,
			is_boolean,
			is_integer,
			is_real,
			is_string,
			is_date
		end

feature -- Access

--	value: STRING_32
--			-- Raw string value.

	style: INTEGER
			-- Scalar style (plain, single-quoted, double-quoted, literal, folded).

feature -- Status report

	is_scalar: BOOLEAN = True
			-- <Precursor>

	is_null: BOOLEAN
			-- <Precursor>
		do
		end

	is_boolean: BOOLEAN
			-- <Precursor>
		do
		end

	is_integer: BOOLEAN
			-- <Precursor>
		do
		end

	is_real: BOOLEAN
			-- <Precursor>
		do
		end

	is_string: BOOLEAN
			-- <Precursor>
		do
		end

	is_date: BOOLEAN
			-- <Precursor>
		do
		end

feature -- Conversion

	to_string_value: STRING_32
		deferred
		end

	to_boolean: BOOLEAN
			-- Convert to boolean.
		require
			is_boolean: is_boolean
		do
		end

	to_integer_64: INTEGER_64
			-- Convert to integer.
		require
			is_integer: is_integer
		do
		end

	to_real_64: REAL_64
			-- Convert to real.
		require
			is_real_or_integer: is_real or is_integer
		do
		end

	to_string_32: STRING_32
			-- Get value as STRING_32.
		do
			Result := to_string_value
		ensure
			result_attached: Result /= Void
		end

feature -- Element change

--	set_value (a_value: STRING_32)
--			-- Set `value` to `a_value`.
--		require
--			value_attached: a_value /= Void
--		do
--			value := a_value
--		ensure
--			value_set: value.same_string (a_value)
--		end

	set_style (a_style: INTEGER)
			-- Set `style` to `a_style`.
		require
			valid_style: a_style >= Style_plain and a_style <= Style_folded
		do
			style := a_style
		ensure
			style_set: style = a_style
		end

feature -- Visitor

	accept (a_visitor: YAML_VISITOR)
			-- <Precursor>
		do
			a_visitor.visit_scalar (Current)
		end

feature -- Output

	representation: STRING_32
			-- <Precursor>
		local
			value: like to_string_value
		do
			value := to_string_value
			inspect style
			when Style_plain then
				Result := value.twin
			when Style_single_quoted then
				create Result.make (value.count + 2)
				Result.append_character ('%'')
				Result.append (escaped_single_quoted)
				Result.append_character ('%'')
			when Style_double_quoted then
				create Result.make (value.count + 2)
				Result.append_character ('"')
				Result.append (escaped_double_quoted)
				Result.append_character ('"')
			when Style_literal then
				Result := {STRING_32} "|%N" + value
			when Style_folded then
				Result := {STRING_32} ">%N" + value
			else
				Result := value.twin
			end
		end

feature -- Constants

	Style_plain: INTEGER = 0
			-- Plain style (no quotes).

	Style_single_quoted: INTEGER = 1
			-- Single-quoted style.

	Style_double_quoted: INTEGER = 2
			-- Double-quoted style.

	Style_literal: INTEGER = 3
			-- Literal block style (|).

	Style_folded: INTEGER = 4
			-- Folded block style (>).

feature {NONE} -- Implementation

	escaped_single_quoted: STRING_32
			-- Escape single quotes by doubling them.
		local
			i: INTEGER
			c: CHARACTER_32
			value: like to_string_value
		do
			value := to_string_value
			create Result.make (value.count)
			from
				i := 1
			until
				i > value.count
			loop
				c := value [i]
				if c = '%'' then
					Result.append ("''")
				else
					Result.append_character (c)
				end
				i := i + 1
			end
		end

	escaped_double_quoted: STRING_32
			-- Escape special characters in double-quoted string.
		local
			i: INTEGER
			c: CHARACTER_32
			value: like to_string_value
		do
			value := to_string_value
			create Result.make (value.count)
			from
				i := 1
			until
				i > value.count
			loop
				c := value [i]
				inspect c
				when '%N' then
					Result.append ("\n")
				when '%R' then
					Result.append ("\r")
				when '%T' then
					Result.append ("\t")
				when '\' then
					Result.append ("\\")
				when '"' then
					Result.append ("\%"")
				else
					Result.append_character (c)
				end
				i := i + 1
			end
		end

invariant
	valid_style: style >= Style_plain and style <= Style_folded

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
