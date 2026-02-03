note
	description: "Plain text inline node."

class
	MD_TEXT

inherit
	MD_INLINE

create
	make

feature -- Initialization

	make (a_text: READABLE_STRING_8)
			-- Create text node with `a_text`.
		do
			create text.make_from_string (a_text)
		ensure
			text_set: text.same_string (a_text)
		end

feature -- Access

	text: STRING_8
			-- Text content (not escaped).

feature -- Visitor

	process (a_visitor: MD_VISITOR)
			-- Process `Current` using `a_visitor`.
		do
			a_visitor.visit_text (Current)
		end

invariant
	text_attached: text /= Void

end

