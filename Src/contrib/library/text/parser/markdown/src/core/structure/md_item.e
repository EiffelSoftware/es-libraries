note
	description: "Base node for Markdown AST."

deferred class
	MD_ITEM

inherit
	MD_HELPER

feature -- Visitor

	process (a_visitor: MD_VISITOR)
			-- Process `Current` using `a_visitor`.
		require
			a_visitor_attached: a_visitor /= Void
		deferred
		end

end

