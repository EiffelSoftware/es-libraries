note
	description: "YAML scalar value (string, number, boolean, null)."
	date: "$Date$"
	revision: "$Revision$"

class
	YAML_SCALAR

inherit
	YAML_VALUE
		redefine
			is_scalar,
			is_null,
			is_boolean,
			is_integer,
			is_real,
			is_string
		end

create
--	make,
--	make_string,
	make_null,
	make_boolean,
	make_integer,
	make_real

--convert
--	make ({READABLE_STRING_8, STRING_8, IMMUTABLE_STRING_8, READABLE_STRING_GENERAL, STRING_GENERAL, IMMUTABLE_STRING_GENERAL})

feature {NONE} -- Initialization

	make (a_value: READABLE_STRING_GENERAL)
			-- Initialize with string `a_value`.
		require
			value_attached: a_value /= Void
		do
			value := a_value.to_string_32
			style := Style_plain
		ensure
			value_set: value.same_string (a_value)
			style_plain: style = Style_plain
		end

	make_null
			-- Initialize as null value.
		do
			value := "null"
			is_null_value := True
			style := Style_plain
		ensure
			is_null: is_null
		end

	make_boolean (a_value: BOOLEAN)
			-- Initialize with boolean `a_value`.
		do
			if a_value then
				value := "true"
			else
				value := "false"
			end
			is_boolean_value := True
			style := Style_plain
		ensure
			is_boolean: is_boolean
			correct_value: (a_value and value.same_string ("true")) or (not a_value and value.same_string ("false"))
		end

	make_integer (a_value: INTEGER_64)
			-- Initialize with integer `a_value`.
		do
			value := a_value.out
			is_integer_value := True
			style := Style_plain
		ensure
			is_integer: is_integer
		end

	make_real (a_value: REAL_64)
			-- Initialize with real `a_value`.
		do
			value := a_value.out
			is_real_value := True
			style := Style_plain
		ensure
			is_real: is_real
		end

	make_string (a_value: READABLE_STRING_GENERAL)
			-- Initialize with string `a_value`, explicitly marked as string.
		require
			value_attached: a_value /= Void
		do
			value := a_value.to_string_32
			is_string_value := True
			style := Style_double_quoted
		ensure
			is_string: is_string
			value_set: value.same_string (a_value)
		end

feature -- Access

	value: STRING_32
			-- Raw string value.

	style: INTEGER
			-- Scalar style (plain, single-quoted, double-quoted, literal, folded).

feature -- Status report

	is_scalar: BOOLEAN = True
			-- <Precursor>

	is_null: BOOLEAN
			-- <Precursor>
		do
			Result := is_null_value
		end

	is_boolean: BOOLEAN
			-- <Precursor>
		do
			Result := is_boolean_value
		end

	is_integer: BOOLEAN
			-- <Precursor>
		do
			Result := is_integer_value
		end

	is_real: BOOLEAN
			-- <Precursor>
		do
			Result := is_real_value
		end

	is_string: BOOLEAN
			-- <Precursor>
		do
			Result := is_string_value
		end

feature -- Conversion

	to_boolean: BOOLEAN
			-- Convert to boolean.
		require
			is_boolean: is_boolean
		do
			Result := value.same_string ("true") or value.same_string ("True") or value.same_string ("TRUE")
		end

	to_integer_64: INTEGER_64
			-- Convert to integer.
		require
			is_integer: is_integer
		do
			Result := value.to_integer_64
		end

	to_real_64: REAL_64
			-- Convert to real.
		require
			is_real_or_integer: is_real or is_integer
		do
			Result := value.to_real_64
		end

	to_string_32: STRING_32
			-- Get value as STRING_32.
		do
			Result := value
		ensure
			result_attached: Result /= Void
		end

feature -- Element change

	set_value (a_value: STRING_32)
			-- Set `value` to `a_value`.
		require
			value_attached: a_value /= Void
		do
			value := a_value
		ensure
			value_set: value.same_string (a_value)
		end

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
		do
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

	is_null_value: BOOLEAN
			-- Is this explicitly a null value?

	is_boolean_value: BOOLEAN
			-- Is this explicitly a boolean value?

	is_integer_value: BOOLEAN
			-- Is this explicitly an integer value?

	is_real_value: BOOLEAN
			-- Is this explicitly a real value?

	is_string_value: BOOLEAN
			-- Is this explicitly a string value?

	escaped_single_quoted: STRING_32
			-- Escape single quotes by doubling them.
		local
			i: INTEGER
			c: CHARACTER_32
		do
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
		do
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
	value_attached: value /= Void
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
