note
	description: "Footnotes definition block (e.g., [^1]: definition)."

class
	MD_FOOTNOTE_DEFINITION

inherit
	MD_BOX [MD_BLOCK]
		redefine
			process
		end

	MD_BLOCK

create
	make

feature -- Initialization

	make (a_label: READABLE_STRING_8)
			-- Create a footnote definition with `a_label`.
		require
			a_label_attached: a_label /= Void
		do
			create label.make_from_string (a_label)
			initialize
		ensure
			label_set: label.same_string (a_label)
			is_empty: count = 0
		end

feature -- Access

	label: STRING_8
			-- Footnote label (e.g., "1").

feature -- Visitor

	process (a_visitor: MD_VISITOR)
			-- Process `Current` using `a_visitor`.
		do
			a_visitor.visit_footnote_definition (Current)
		end

invariant
	label_attached: label /= Void

end
