note
	description: "Markdown list block (ordered or unordered)."

class
	MD_LIST

inherit
	MD_BOX [MD_LIST_ITEM]
		redefine
			process
		end

	MD_BLOCK

create
	make_unordered,
	make_ordered

feature -- Initialization

	make_unordered (a_bullet: CHARACTER)
			-- Create an unordered list with bullet character `a_bullet` ('-', '*', or '+').
		require
			valid_bullet: a_bullet = '-' or a_bullet = '*' or a_bullet = '+'
		do
			initialize
			is_ordered := False
			start_number := 1
			list_marker := a_bullet
		ensure
			not_ordered: not is_ordered
			default_start: start_number = 1
			list_marker_set: list_marker = a_bullet
		end

	make_ordered (a_start_number: INTEGER; a_delimiter: CHARACTER)
			-- Create an ordered list starting at `a_start_number` with delimiter `a_delimiter` ('.' or ')').
		require
			valid_start_number: a_start_number >= 1
			valid_delimiter: a_delimiter = '.' or a_delimiter = ')'
		do
			initialize
			is_ordered := True
			start_number := a_start_number
			list_marker := a_delimiter
		ensure
			ordered: is_ordered
			start_number_set: start_number = a_start_number
			list_marker_set: list_marker = a_delimiter
		end

feature -- Access

	is_ordered: BOOLEAN
			-- Is this an ordered list?

	start_number: INTEGER
			-- Starting number for ordered lists (typically 1).

	list_marker: CHARACTER
			-- For unordered: bullet character ('-', '*', '+'). For ordered: delimiter ('.' or ')').

feature -- Visitor

	process (a_visitor: MD_VISITOR)
			-- Process `Current` using `a_visitor`.
		do
			a_visitor.visit_list (Current)
		end

invariant
	start_number_valid: start_number >= 1

end

