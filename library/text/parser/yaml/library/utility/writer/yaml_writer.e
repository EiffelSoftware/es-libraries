note
	description: "Writer for generating YAML output from YAML values."
	date: "$Date$"
	revision: "$Revision$"

class
	YAML_WRITER

inherit
	YAML_VISITOR

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize writer.
		do
			create output.make (500)
			indent_size := 2
			current_indent := 0
			use_flow_style := False
		ensure
			output_empty: output.is_empty
			default_indent: indent_size = 2
		end

feature -- Access

	output: STRING_32
			-- Generated YAML output.

	indent_size: INTEGER
			-- Number of spaces per indentation level.

feature -- Settings

	use_flow_style: BOOLEAN
			-- Should collections use flow style by default?

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

	set_use_flow_style (a_value: BOOLEAN)
			-- Set `use_flow_style` to `a_value`.
		do
			use_flow_style := a_value
		ensure
			flow_style_set: use_flow_style = a_value
		end

feature -- Operations

	reset
			-- Reset writer for new output.
		do
			output.wipe_out
			current_indent := 0
		ensure
			output_empty: output.is_empty
			indent_reset: current_indent = 0
		end

	write_value (a_value: YAML_VALUE)
			-- Write `a_value` to output.
		require
			value_attached: a_value /= Void
		do
			reset
			a_value.accept (Current)
		ensure
			output_not_empty: not output.is_empty
		end

	write_document (a_document: YAML_DOCUMENT)
			-- Write `a_document` to output.
		require
			document_attached: a_document /= Void
		do
			reset
			output.append ("---%N")
			if attached a_document.root as root then
				root.accept (Current)
			end
		ensure
			output_not_empty: not output.is_empty
		end

feature -- Visiting

	visit_document (a_doc: YAML_DOCUMENT)
			-- Visit mapping `a_mapping`.
		do
			write_document (a_doc)
		end

	visit_scalar (a_scalar: YAML_SCALAR)
			-- <Precursor>
		do
			write_scalar (a_scalar)
		end

	visit_sequence (a_sequence: YAML_SEQUENCE)
			-- <Precursor>
		do
			if a_sequence.is_flow_style or use_flow_style then
				write_flow_sequence (a_sequence)
			else
				write_block_sequence (a_sequence)
			end
		end

	visit_mapping (a_mapping: YAML_MAPPING)
			-- <Precursor>
		do
			if a_mapping.is_flow_style or use_flow_style then
				write_flow_mapping (a_mapping)
			else
				write_block_mapping (a_mapping)
			end
		end

feature {NONE} -- Implementation

	current_indent: INTEGER
			-- Current indentation level.

	write_scalar (a_scalar: YAML_SCALAR)
			-- Write scalar value.
		local
			needs_quoting: BOOLEAN
			value: STRING_32
		do
			value := a_scalar.value
			if attached a_scalar.anchor as anch then
				output.append ("&")
				output.append (anch)
				output.append (" ")
			end
			if attached a_scalar.tag as t then
				output.append (t)
				output.append (" ")
			end
			inspect a_scalar.style
			when {YAML_SCALAR}.Style_single_quoted then
				output.append_character ('%'')
				output.append (escape_single_quoted (value))
				output.append_character ('%'')
			when {YAML_SCALAR}.Style_double_quoted then
				output.append_character ('"')
				output.append (escape_double_quoted (value))
				output.append_character ('"')
			when {YAML_SCALAR}.Style_literal then
				output.append ("|%N")
				write_literal_content (value)
			when {YAML_SCALAR}.Style_folded then
				output.append (">%N")
				write_folded_content (value)
			else
				-- Plain style
				needs_quoting := needs_quoting_for_plain (value)
				if needs_quoting then
					output.append_character ('"')
					output.append (escape_double_quoted (value))
					output.append_character ('"')
				else
					output.append (value)
				end
			end
		end

	write_block_sequence (a_sequence: YAML_SEQUENCE)
			-- Write block-style sequence.
		local
			first_item: BOOLEAN
		do
			if a_sequence.is_empty then
				output.append ("[]%N")
			else
				first_item := True
				across a_sequence as ic loop
					if not first_item then
						write_indent
					end
					output.append ("- ")
					if ic.is_mapping or ic.is_sequence then
						if ic.is_mapping and then ic.as_mapping.is_flow_style then
							-- Flow-style mapping: write inline and add newline
							ic.accept (Current)
							output.append_character ('%N')
						elseif ic.is_sequence and then ic.as_sequence.is_flow_style then
							-- Flow-style sequence: write inline and add newline
							ic.accept (Current)
							output.append_character ('%N')
						else
							-- Block-style: newline before, indent, then content
							output.append_character ('%N')
							current_indent := current_indent + indent_size
							write_indent
							ic.accept (Current)
							current_indent := current_indent - indent_size
						end
					else
						ic.accept (Current)
						output.append_character ('%N')
					end
					first_item := False
				end
			end
		end

	write_flow_sequence (a_sequence: YAML_SEQUENCE)
			-- Write flow-style sequence [item1, item2, ...].
		local
			first_item: BOOLEAN
			saved_flow: BOOLEAN
		do
			saved_flow := use_flow_style
			use_flow_style := True
			output.append_character ('[')
			first_item := True
			across a_sequence as ic loop
				if not first_item then
					output.append (", ")
				end
				ic.accept (Current)
				first_item := False
			end
			output.append_character (']')
			use_flow_style := saved_flow
		end

	write_block_mapping (a_mapping: YAML_MAPPING)
			-- Write block-style mapping.
		local
			i: INTEGER
			first_item: BOOLEAN
			key: YAML_VALUE
			val: YAML_VALUE
		do
			if a_mapping.is_empty then
				output.append ("{}%N")
			else
				first_item := True
				from
					i := 1
				until
					i > a_mapping.count
				loop
					if not first_item then
						write_indent
					end
					key := a_mapping.key_at (i)
					val := a_mapping.value_at_index (i)
					key.accept (Current)
					output.append_character (':')
					if val.is_mapping or val.is_sequence then
						if val.is_mapping and then val.as_mapping.is_flow_style then
							-- Flow-style mapping: write inline and add newline
							output.append_character (' ')
							val.accept (Current)
							output.append_character ('%N')
						elseif val.is_sequence and then val.as_sequence.is_flow_style then
							-- Flow-style sequence: write inline and add newline
							output.append_character (' ')
							val.accept (Current)
							output.append_character ('%N')
						elseif val.is_mapping and then val.as_mapping.is_empty then
							-- Empty mapping: write {} and add newline
							output.append_character (' ')
							val.accept (Current)
							output.append_character ('%N')
						elseif val.is_sequence and then val.as_sequence.is_empty then
							-- Empty sequence: write [] and add newline
							output.append_character (' ')
							val.accept (Current)
							output.append_character ('%N')
						else
							-- Block-style: newline before, indent, then content
							output.append_character ('%N')
							current_indent := current_indent + indent_size
							write_indent
							val.accept (Current)
							current_indent := current_indent - indent_size
						end
					else
						output.append_character (' ')
						val.accept (Current)
						output.append_character ('%N')
					end
					first_item := False
					i := i + 1
				end
			end
		end

	write_flow_mapping (a_mapping: YAML_MAPPING)
			-- Write flow-style mapping {key1: value1, ...}.
		local
			i: INTEGER
			saved_flow: BOOLEAN
		do
			saved_flow := use_flow_style
			use_flow_style := True
			output.append_character ('{')
			from
				i := 1
			until
				i > a_mapping.count
			loop
				if i > 1 then
					output.append (", ")
				end
				a_mapping.key_at (i).accept (Current)
				output.append (": ")
				a_mapping.value_at_index (i).accept (Current)
				i := i + 1
			end
			output.append_character ('}')
			use_flow_style := saved_flow
		end

	write_indent
			-- Write current indentation.
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

	write_literal_content (a_content: STRING_32)
			-- Write content for literal scalar with proper indentation.
		local
			lines: LIST [STRING_32]
		do
			lines := a_content.split ('%N')
			across lines as line loop
				write_indent
				across 1 |..| indent_size as i loop
					output.append_character (' ')
				end
				output.append (line)
				output.append_character ('%N')
			end
		end

	write_folded_content (a_content: STRING_32)
			-- Write content for folded scalar with proper indentation.
		local
			lines: LIST [STRING_32]
		do
			lines := a_content.split ('%N')
			across lines as line loop
				write_indent
				across 1 |..| indent_size as i loop
					output.append_character (' ')
				end
				output.append (line)
				output.append_character ('%N')
			end
		end

	escape_single_quoted (a_value: STRING_32): STRING_32
			-- Escape single quotes by doubling them.
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
				if c = '%'' then
					Result.append ("''")
				else
					Result.append_character (c)
				end
				i := i + 1
			end
		end

	escape_double_quoted (a_value: STRING_32): STRING_32
			-- Escape special characters in double-quoted string.
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
					if c.code < 32 or c.code > 126 then
						-- Non-printable or non-ASCII: use unicode escape
						Result.append ("\u")
						Result.append (c.code.to_hex_string)
					else
						Result.append_character (c)
					end
				end
				i := i + 1
			end
		end

	needs_quoting_for_plain (a_value: STRING_32): BOOLEAN
			-- Does `a_value` need quoting when written as plain scalar?
		local
			lower: STRING_32
		do
			if a_value.is_empty then
				Result := True
			else
				lower := a_value.as_lower
				-- Check for reserved values
				if lower.same_string ("true") or lower.same_string ("false") or
				   lower.same_string ("yes") or lower.same_string ("no") or
				   lower.same_string ("on") or lower.same_string ("off") or
				   lower.same_string ("null") or lower.same_string ("~") then
					-- These might be ambiguous
					Result := False
				end
				-- Check for special characters
				if a_value.has (':') or a_value.has ('#') or a_value.has ('[') or
				   a_value.has (']') or a_value.has ('{') or a_value.has ('}') or
				   a_value.has (',') or a_value.has ('&') or a_value.has ('*') or
				   a_value.has ('!') or a_value.has ('|') or a_value.has ('>') or
				   a_value.has ('%'') or a_value.has ('"') or a_value.has ('%%') or
				   a_value.has ('@') or a_value.has ('`') then
					Result := True
				end
				-- Check for leading/trailing whitespace
				if a_value [1] = ' ' or a_value [1] = '%T' or
				   a_value [a_value.count] = ' ' or a_value [a_value.count] = '%T' then
					Result := True
				end
				-- Check for newlines
				if a_value.has ('%N') or a_value.has ('%R') then
					Result := True
				end
			end
		end

invariant
	output_attached: output /= Void
	valid_indent_size: indent_size > 0
	non_negative_indent: current_indent >= 0

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
