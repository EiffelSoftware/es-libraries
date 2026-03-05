note
	description: "Visitor that produces a pretty-printed YAML string."
	date: "$Date$"
	revision: "$Revision$"

class
	YAML_PRETTY_STRING_VISITOR

inherit
	YAML_VISITOR

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize visitor.
		do
			create output.make (500)
			indent_size := 2
			current_indent := 0
		ensure
			output_empty: output.is_empty
		end

feature -- Access

	output: STRING_32
			-- Pretty-printed output.

	indent_size: INTEGER
			-- Spaces per indentation level.

feature -- Element change

	set_indent_size (a_size: INTEGER)
			-- Set `indent_size` to `a_size`.
		require
			positive: a_size > 0
		do
			indent_size := a_size
		ensure
			indent_set: indent_size = a_size
		end

	reset
			-- Reset for new output.
		do
			output.wipe_out
			current_indent := 0
		end

feature -- Visiting

	visit_document (a_doc: YAML_DOCUMENT)
			-- Visit mapping `a_mapping`.
		do
			if attached a_doc.root as v then
				v.accept (Current)
			end
		end

	visit_scalar (a_scalar: YAML_SCALAR)
			-- <Precursor>
		do
			if a_scalar.is_null then
				output.append ("null")
			elseif attached {YAML_BOOLEAN} a_scalar as y_bool then
				output.append_boolean (y_bool.value)
			elseif attached {YAML_INTEGER} a_scalar as y_int then
				output.append_integer_64 (y_int.value)
			elseif attached {YAML_REAL} a_scalar as y_real then
				output.append_double (y_real.value)
			else
				-- String scalar
				if needs_quoting (a_scalar.to_string_value) then
					output.append_character ('"')
					output.append (escaped_string (a_scalar.to_string_value))
					output.append_character ('"')
				else
					output.append (a_scalar.to_string_value)
				end
			end
		end

	visit_sequence (a_sequence: YAML_SEQUENCE)
			-- <Precursor>
		do
			if a_sequence.is_empty then
				output.append ("[]")
			elseif a_sequence.is_flow_style then
				output.append ("[")
				across a_sequence as ic loop
					if @ ic.target_index > 1 then
						output.append (", ")
					end
					ic.accept (Current)
				end
				output.append ("]")
			else
				across a_sequence as ic loop
					if @ ic.target_index > 1 then
						output.append_character ('%N')
						write_indent
					end
					output.append ("- ")
					current_indent := current_indent + indent_size
					ic.accept (Current)
					current_indent := current_indent - indent_size
				end
			end
		end

	visit_mapping (a_mapping: YAML_MAPPING)
			-- <Precursor>
		local
			i: INTEGER
		do
			if a_mapping.is_empty then
				output.append ("{}")
			elseif a_mapping.is_flow_style then
				output.append ("{")
				i := 1
				across
					a_mapping as val
				loop
					if i > 1 then
						output.append (", ")
					end
					(@val.key).accept (Current)
					output.append (": ")
					val.accept (Current)
					i := i + 1
				end
				output.append ("}")
			else
				i := 1
				across
					a_mapping as val
				loop
					if i > 1 then
						output.append_character ('%N')
						write_indent
					end
					(@val.key).accept (Current)
					output.append (":")
					if val.is_mapping or val.is_sequence then
						output.append_character ('%N')
						current_indent := current_indent + indent_size
						write_indent
						val.accept (Current)
						current_indent := current_indent - indent_size
					else
						output.append (" ")
						val.accept (Current)
					end
					i := i + 1
				end
			end
		end

feature {NONE} -- Implementation

	current_indent: INTEGER
			-- Current indentation level.

	write_indent
			-- Write indentation.
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > current_indent
			loop
				output.append_character (' ')
				i := i + 1
			end
		end

	needs_quoting (a_value: STRING_32): BOOLEAN
			-- Does `a_value` need quoting?
		do
			Result := a_value.is_empty or else
				a_value.has (':') or else a_value.has ('#') or else
				a_value.has ('%N') or else a_value.has ('%R') or else
				a_value [1] = ' ' or else a_value [a_value.count] = ' '
		end

	escaped_string (a_value: STRING_32): STRING_32
			-- Escape special characters.
		local
			i: INTEGER
			c: CHARACTER_32
		do
			create Result.make (a_value.count)
			from
				i := 1
			until
				i > a_value.count
			loop
				c := a_value [i]
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
	output_attached: output /= Void
	valid_indent: indent_size > 0

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
