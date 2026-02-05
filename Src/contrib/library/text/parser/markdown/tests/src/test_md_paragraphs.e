note
	description: "Tests for Markdown block-level: Paragraphs (FEATURES.md Block-Level)."

class
	TEST_MD_PARAGRAPHS

inherit
	TEST_MD_PARSER_BASE

feature -- Tests (Paragraphs)

	test_paragraph_link_and_code
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("This is [Eiffel](https://eiffel.org) and `code`.%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.same_string ("<p>This is <a href=%"https://eiffel.org%">Eiffel</a> and <code class=%"inline%">code</code>.</p>%N"))
		end

	test_reference_style_link
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
				-- [text][label] with definition.
			create t.make_from_string ("This is [Eiffel][site].%N%N[site]: https://eiffel.org%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.same_string ("<p>This is <a href=%"https://eiffel.org%">Eiffel</a>.</p>%N"))
		end

	test_collapsed_reference_link
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
				-- [text][] uses text as label.
			create t.make_from_string ("Visit [Eiffel][].%N%N[Eiffel]: https://eiffel.org%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.same_string ("<p>Visit <a href=%"https://eiffel.org%">Eiffel</a>.</p>%N"))
		end

	test_shortcut_reference_link
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
				-- [text] shortcut uses text as label.
			create t.make_from_string ("Learn about [Eiffel].%N%N[eiffel]: https://eiffel.org%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.same_string ("<p>Learn about <a href=%"https://eiffel.org%">Eiffel</a>.</p>%N"))
		end

end
