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

	text: STRING_8
			-- Plain text of the heading (UTF-8), without its formatting.
		do
			create Result.make (20)
			append_inline_text (Current, Result)
		end

feature -- Visitor

	process (a_visitor: MD_VISITOR)
			-- Process `Current` using `a_visitor`.
		do
			a_visitor.visit_heading (Current)
		end

feature {NONE} -- Implementation

	append_inline_text (a_container: MD_COMPOSITE [MD_INLINE]; a_output: STRING_8)
			-- Append the plain text of the inline content of `a_container' to `a_output'.
		do
			across
				a_container as i
			loop
				if attached {MD_TEXT} i as l_text then
					a_output.append (l_text.text)
				elseif attached {MD_CODE_SPAN} i as l_code then
					a_output.append (l_code.code)
				elseif attached {MD_COMPOSITE [MD_INLINE]} i as l_composite then
					append_inline_text (l_composite, a_output)
				elseif attached {MD_SOFT_BREAK} i then
					a_output.append_character (' ')
				end
			end
		end

invariant
	valid_level: level >= 1 and level <= 6

end

