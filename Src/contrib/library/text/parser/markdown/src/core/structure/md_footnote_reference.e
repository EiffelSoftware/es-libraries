note
	description: "Footnotes reference inline node (e.g., [^1])."

class
	MD_FOOTNOTE_REFERENCE

inherit
	MD_INLINE

create
	make

feature -- Initialization

	make (a_label: READABLE_STRING_8)
			-- Create a footnote reference with `a_label`.
		require
			a_label_attached: a_label /= Void
		do
			create label.make_from_string (a_label)
		ensure
			label_set: label.same_string (a_label)
		end

feature -- Access

	label: STRING_8
			-- Footnote label (e.g., "1").

feature -- Visitor

	process (a_visitor: MD_VISITOR)
			-- Process `Current` using `a_visitor`.
		do
			a_visitor.visit_footnote_reference (Current)
		end

invariant
	label_attached: label /= Void

end
