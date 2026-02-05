note
	description: "Tests for Markdown block-level: Tables, alignment, no header, empty cells (FEATURES.md Block-Level)."

class
	TEST_MD_TABLES

inherit
	TEST_MD_PARSER_BASE

feature -- Tests (Tables)

	test_table
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("| Header 1 | Header 2 |%N|----------|----------|%N| Cell 1   | Cell 2   |%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.same_string ("<table>%N<tr><th>Header 1</th><th>Header 2</th></tr>%N<tr><td>Cell 1</td><td>Cell 2</td></tr>%N</table>%N"))
		end

	test_table_with_inline
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("| *Bold* | `code` |%N|--------|--------|%N| Text   | More   |%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.same_string ("<table>%N<tr><th><em>Bold</em></th><th><code class=%"inline%">code</code></th></tr>%N<tr><td>Text</td><td>More</td></tr>%N</table>%N"))
		end

	test_table_column_alignment
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("| Left | Center | Right |%N|:-----|:-----:|-----:|%N| A    | B      | C     |%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.same_string ("<table>%N<tr><th style=%"text-align: left%">Left</th><th style=%"text-align: center%">Center</th><th style=%"text-align: right%">Right</th></tr>%N<tr><td style=%"text-align: left%">A</td><td style=%"text-align: center%">B</td><td style=%"text-align: right%">C</td></tr>%N</table>%N"))
		end

	test_table_without_header_row
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("|-----|-----|%N| one | two |%N| a   | b   |%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.same_string ("<table>%N<tr><td>one</td><td>two</td></tr>%N<tr><td>a</td><td>b</td></tr>%N</table>%N"))
		end

	test_table_empty_cells
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("| A | | C |%N|---|---|---|%N| 1 | 2 | 3 |%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.same_string ("<table>%N<tr><th>A</th><th></th><th>C</th></tr>%N<tr><td>1</td><td>2</td><td>3</td></tr>%N</table>%N"))
		end

end
