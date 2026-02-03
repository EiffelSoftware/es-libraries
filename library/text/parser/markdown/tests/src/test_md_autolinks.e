note
	description: "Tests for Markdown inline: Autolinks (URL, email) (FEATURES.md Inline)."

class
	TEST_MD_AUTOLINKS

inherit
	TEST_MD_PARSER_BASE

feature -- Tests (Autolinks)

	test_autolink_url
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("Visit <https://example.com> for more.%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.has_substring ("<a href=%"https://example.com%">https://example.com</a>"))

			create t.make_from_string ("<https://example.com>")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.has_substring ("<a href=%"https://example.com%">https://example.com</a>"))
		end

	test_autolink_email
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("Email <user@example.com> for info.%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.has_substring ("<a href=%"user@example.com%">user@example.com</a>"))
		end

feature -- Tests (Entity references)

	test_entity_amp_lt_gt
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("Use &amp; &lt; &gt; in HTML.%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.same_string ("<p>Use &amp; &lt; &gt; in HTML.</p>%N"))
		end

	test_entity_quot_apos
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("Quote: &quot;A&apos;B&quot;%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.same_string ("<p>Quote: %"A'B%"</p>%N"))
		end

	test_entity_numeric_decimal
		local
			t: MD_CONTENT_TEXT
			o: STRING
			cp: STRING_8
		do
			create t.make_from_string ("Copyright &#169;%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			create cp.make (1)
			cp.append_character ('%/169/')
			assert ("xhtml", o.has_substring (cp))
		end

	test_entity_numeric_hex
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("Ampersand: &#x26;%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.has_substring ("&"))
		end

end
