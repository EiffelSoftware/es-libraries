note
	description: "Markdown ATX heading block."

class
	MD_HEADING

inherit
	MD_BOX [MD_INLINE]
		redefine
			process
		end

	MD_BLOCK

create
	make

feature -- Initialization

	make (a_level: INTEGER)
			-- Create heading of level `a_level`.
		require
			valid_level: a_level >= 1 and a_level <= 6
		do
			level := a_level
			initialize
		ensure
			level_set: level = a_level
			is_empty: count = 0
		end

feature -- Access

	level: INTEGER
			-- Heading level (1..6).

feature -- Visitor

	process (a_visitor: MD_VISITOR)
			-- Process `Current` using `a_visitor`.
		do
			a_visitor.visit_heading (Current)
		end

invariant
	valid_level: level >= 1 and level <= 6

end

