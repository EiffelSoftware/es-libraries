note
	description: "Tests for GitHub Flavored Markdown extensions: strikethrough, underscore emphasis/strong, task lists (FEATURES.md Inline)."

class
	TEST_MD_GFM

inherit
	TEST_MD_PARSER_BASE

feature -- Tests (GFM extensions)

	test_strikethrough
		local
			p: MD_PARSER
			doc: MD_DOCUMENT
			o: STRING
		do
			create p.make
			p.set_using_github_extension (True)
			doc := p.parse ("~~strikethrough text~~%N")
			create o.make_empty
			doc.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.same_string ("<p><del>strikethrough text</del></p>%N"))
		end

	test_underscore_emphasis
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("_emphasized text_%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.same_string ("<p><em>emphasized text</em></p>%N"))
		end

	test_underscore_strong
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("__strong text__%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.same_string ("<p><strong>strong text</strong></p>%N"))
		end

	test_underscore_emphasis_and_strong
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("___emphasized and strong text___%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.same_string ("<p><strong><em>emphasized and strong text</em></strong></p>%N"))
		end

	test_task_list_unchecked
		local
			p: MD_PARSER
			doc: MD_DOCUMENT
			o: STRING
		do
			create p.make
			p.set_using_github_extension (True)
			doc := p.parse ("- [ ] Unchecked task%N")
			create o.make_empty
			doc.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.same_string ("<ul>%N<li><input type=%"checkbox%" disabled/>Unchecked task</li>%N</ul>%N"))
		end

	test_task_list_checked
		local
			p: MD_PARSER
			doc: MD_DOCUMENT
			o: STRING
		do
			create p.make
			p.set_using_github_extension (True)
			doc := p.parse ("- [x] Checked task%N")
			create o.make_empty
			doc.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.same_string ("<ul>%N<li><input type=%"checkbox%" disabled checked/>Checked task</li>%N</ul>%N"))
		end

	test_task_list
		local
			p: MD_PARSER
			doc: MD_DOCUMENT
			o: STRING
		do
			create p.make
			p.set_using_github_extension (True)
			doc := p.parse ("- [x] Checked task%N- [ ] Unchecked task%N- not a task%N")
			create o.make_empty
			doc.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.same_string ("<ul>%N<li><input type=%"checkbox%" disabled checked/>Checked task</li>%N<li><input type=%"checkbox%" disabled/>Unchecked task</li>%N<li><p>not a task</p>%N</li>%N</ul>%N"))
		end

	test_github_extensions_disabled
		local
			p: MD_PARSER
			doc: MD_DOCUMENT
			o: STRING
		do
			create p.make
			p.set_using_github_extension (False)
			doc := p.parse ("~~not strikethrough~~ - [ ] not task%N")
			create o.make_empty
			doc.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.same_string ("<p>~~not strikethrough~~ - [ ] not task</p>%N"))
		end

end
