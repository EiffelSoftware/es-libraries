note
	description: "Tests of the table of contents extension: [TOC] or [[_TOC_]] (see {MD_PARSER}.using_table_of_contents_extension)."

class
	TEST_MD_TABLE_OF_CONTENTS

inherit
	TEST_MD_PARSER_BASE

feature -- Tests

	test_table_of_contents
			-- `[TOC]' is replaced by the nested list of the headings, linked to their identifiers.
		local
			o: STRING
		do
			o := xhtml ("[TOC]%N%N# Intro%N%N## Getting *started*!%N%N## Usage%N%N# End%N")
			assert ("toc", o.starts_with ("<nav class=%"toc%"><ul><li><a href=%"#intro%">Intro</a><ul><li><a href=%"#getting-started%">Getting started!</a></li><li><a href=%"#usage%">Usage</a></li></ul></li><li><a href=%"#end%">End</a></li></ul></nav>%N"))
			assert ("heading ids", o.has_substring ("<h1 id=%"intro%">Intro</h1>") and o.has_substring ("<h2 id=%"getting-started%">Getting <em>started</em>!</h2>"))
		end

	test_table_of_contents_markers
			-- The markers: `[TOC]' (any letter case) and `[[_TOC_]]', alone in their paragraph.
		do
			assert ("lower case", xhtml ("[toc]%N%N# A%N").starts_with ("<nav class=%"toc%">"))
			assert ("gitlab", xhtml ("[[_TOC_]]%N%N# A%N").starts_with ("<nav class=%"toc%">"))
			assert ("spaces", xhtml ("  [TOC]  %N%N# A%N").starts_with ("<nav class=%"toc%">"))
			assert ("not alone", xhtml ("See [TOC] here.%N%N# A%N").starts_with ("<p>See [TOC] here.</p>"))
			assert ("reference defined", xhtml ("[TOC]%N%N[TOC]: https://example.com%N%N# A%N").starts_with ("<p><a href=%"https://example.com%">TOC</a></p>"))
			assert ("no heading", xhtml ("[TOC]%N%NText.%N").same_string ("<p>Text.</p>%N"))
		end

	test_table_of_contents_levels
			-- Repeated titles, skipped levels, chosen levels.
		local
			p: MD_PARSER
			g: MD_XHTML_GENERATOR
			o: STRING
		do
			o := xhtml ("[TOC]%N%N## A%N%N#### B%N%N## A%N")
			assert ("skipped level", o.starts_with ("<nav class=%"toc%"><ul><li><a href=%"#a%">A</a><ul><li><ul><li><a href=%"#b%">B</a></li></ul></li></ul></li><li><a href=%"#a-1%">A</a></li></ul></nav>"))
			create p.make
			p.set_using_table_of_contents_extension (True)
			create o.make_empty
			create g.make (o)
			g.set_table_of_contents_levels (2, 2)
			p.parse ("[TOC]%N%N# T%N%N## A%N%N### B%N").process (g)
			assert ("levels", o.starts_with ("<nav class=%"toc%"><ul><li><a href=%"#a%">A</a></li></ul></nav>"))
		end

	test_heading_identifiers
			-- Identifiers without table of contents: only when enabled.
		local
			p: MD_PARSER
			g: MD_XHTML_GENERATOR
			o: STRING
		do
			create p.make
			create o.make_empty
			p.parse ("# Title%N").process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("no id by default", o.same_string ("<h1>Title</h1>%N"))
			create o.make_empty
			create g.make (o)
			g.set_heading_identifier_enabled (True)
			p.parse ("# Caf%/0xC3/%/0xA9/ & co%N").process (g)
			assert ("id", o.same_string ("<h1 id=%"caf%/0xC3/%/0xA9/--co%">Caf%/0xC3/%/0xA9/ &amp; co</h1>%N"))
		end

	test_table_of_contents_disabled
			-- Without the extension, `[TOC]' is text.
		local
			p: MD_PARSER
			o: STRING
		do
			create p.make
			create o.make_empty
			p.parse ("[TOC]%N%N# A%N").process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("text", o.same_string ("<p>[TOC]</p>%N<h1>A</h1>%N"))
		end

feature {NONE} -- Implementation

	xhtml (a_text: STRING): STRING
			-- XHTML of `a_text', parsed with the table of contents extension.
		local
			p: MD_PARSER
		do
			create p.make
			p.set_using_table_of_contents_extension (True)
			create Result.make_empty
			p.parse (a_text).process (create {MD_XHTML_GENERATOR}.make (Result))
		end

end
