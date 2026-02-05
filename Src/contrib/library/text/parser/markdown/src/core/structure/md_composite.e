note
	description: "Composite AST node containing child items."

deferred class
	MD_COMPOSITE [G -> MD_ITEM]

inherit
	MD_ITEM

	ITERABLE [G]

feature {NONE} -- Initialization

	initialize
			-- Initialize internal storage.
		do
			create elements.make (5)
		ensure
			elements_attached: elements /= Void
		end

feature -- Access

	elements: ARRAYED_LIST [G]
			-- Child elements.

	count: INTEGER
			-- Number of child elements.
		do
			Result := elements.count
		ensure
			non_negative: Result >= 0
		end

	new_cursor: ITERATION_CURSOR [G]
			-- Fresh cursor associated with `Current`.
		do
			Result := elements.new_cursor
		end

feature -- Status report

	valid_element (e: G): BOOLEAN
			-- Is `e` a valid child element?
		do
			Result := True
		end

feature -- Element change

	add_element (e: G)
			-- Append `e` to `elements`.
		require
			valid_element: valid_element (e)
		do
			elements.extend (e)
			if attached {MD_ITEM_WITH_PARENT [G]} e as l_parentable then
				l_parentable.set_parent (Current)
			end
		ensure
			one_more: elements.count = old elements.count + 1
		end

feature -- Visitor

	process (a_visitor: MD_VISITOR)
			-- Process `Current` using `a_visitor`.
		do
			a_visitor.visit_composite (Current)
		end

invariant
	elements_attached: elements /= Void

end

