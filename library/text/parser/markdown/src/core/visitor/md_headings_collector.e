note
	description: "Collector of the headings and of the tables of contents of a document (in order)."

class
	MD_HEADINGS_COLLECTOR

inherit
	MD_ITERATOR
		redefine
			visit_heading,
			visit_table_of_contents
		end

create
	make

feature {NONE} -- Initialization

	make
			-- Create an empty collector.
		do
			create headings.make (10)
			create tables_of_contents.make (0)
		end

feature -- Access

	headings: ARRAYED_LIST [MD_HEADING]
			-- Headings visited, in order.

	tables_of_contents: ARRAYED_LIST [MD_TABLE_OF_CONTENTS]
			-- Tables of contents visited.

feature -- Visitor

	visit_heading (a_heading: MD_HEADING)
			-- <Precursor>
		do
			headings.extend (a_heading)
			Precursor (a_heading)
		end

	visit_table_of_contents (a_toc: MD_TABLE_OF_CONTENTS)
			-- <Precursor>
		do
			tables_of_contents.extend (a_toc)
		end

end
