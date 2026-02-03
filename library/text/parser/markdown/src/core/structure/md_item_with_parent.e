note
	description: "AST item that may have a parent composite."

class
	MD_ITEM_WITH_PARENT [G -> MD_ITEM]

feature -- Access

	parent: detachable MD_COMPOSITE [MD_ITEM]
			-- Parent composite (if any).

feature -- Element change

	set_parent (p: like parent)
			-- Set `parent` to `p`.
		do
			parent := p
		ensure
			parent_set: parent = p
		end

end

