note
	description: "[
		Table of contents: a paragraph made only of `[TOC]' (any letter case) or `[[_TOC_]]'
		(extension, see {MD_PARSER}.using_table_of_contents_extension), replaced by the list of the
		headings of the document.
	]"

class
	MD_TABLE_OF_CONTENTS

inherit
	MD_BLOCK

create
	make

feature -- Initialization

	make
			-- Create a table of contents (without headings yet).
		do
			create headings.make (0)
		end

feature -- Access

	headings: ARRAYED_LIST [MD_HEADING]
			-- Headings of the document, in order (set by the parser once the document is parsed).

feature -- Element change

	set_headings (a_headings: like headings)
			-- Set `headings' to `a_headings'.
		do
			headings := a_headings
		ensure
			headings_set: headings = a_headings
		end

feature -- Visitor

	process (a_visitor: MD_VISITOR)
			-- Process `Current` using `a_visitor`.
		do
			a_visitor.visit_table_of_contents (Current)
		end

end
