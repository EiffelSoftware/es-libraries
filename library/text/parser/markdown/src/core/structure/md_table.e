note
	description: "Markdown table block."

class
	MD_TABLE

inherit
	MD_BOX [MD_TABLE_ROW]
		redefine
			process
		end

	MD_BLOCK

create
	make

feature -- Initialization

	make
			-- Create an empty table.
		do
			initialize
		ensure
			is_empty: count = 0
		end

feature -- Access

	alignments: detachable ARRAY [detachable READABLE_STRING_8]
			-- Column alignments from separator line: "left", "center", "right"; Void for default.
			-- Indexed by column (1-based).

feature -- Element change

	set_alignments (a_alignments: detachable ARRAY [detachable READABLE_STRING_8])
			-- Set `alignments` to `a_alignments`.
		do
			alignments := a_alignments
		ensure
			alignments_set: alignments = a_alignments
		end

feature -- Visitor

	process (a_visitor: MD_VISITOR)
			-- Process `Current` using `a_visitor`.
		do
			a_visitor.visit_table (Current)
		end

end
