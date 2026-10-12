note
	description: "[
		Title configuration for TUI_BLOCK supporting top/bottom positioning and alignment.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	BLOCK_TITLE

inherit
	ANY
		redefine
			copy,
			is_equal
		end

create
	make,
	make_raw

feature -- Constants

	position_top: NATURAL_8 = 1
			-- Render along the top border.

	position_bottom: NATURAL_8 = 2
			-- Render along the bottom border.

feature {NONE} -- Initialization

	make (a_content: TEXT_LINE; a_position, a_alignment: NATURAL_8)
			-- Initialize title with `a_content`, `a_position`, and `a_alignment`.
		require
			content_not_void: a_content /= Void
			valid_position: a_position = position_top or a_position = position_bottom
			valid_alignment: {TEXT_ALIGNMENT}.is_valid (a_alignment)
		do
			content := a_content
			position := a_position
			alignment := a_alignment
		ensure
			content_set: content = a_content
			position_set: position = a_position
			alignment_set: alignment = a_alignment
		end

	make_raw (a_text: READABLE_STRING_GENERAL; a_position, a_alignment: NATURAL_8)
			-- Initialize title with plain string `a_text`.
		require
			text_not_void: a_text /= Void
			valid_position: a_position = position_top or a_position = position_bottom
			valid_alignment: {TEXT_ALIGNMENT}.is_valid (a_alignment)
		local
			l_line: TEXT_LINE
		do
			create l_line.make_raw (a_text)
			make (l_line, a_position, a_alignment)
		end

feature -- Access

	content: TEXT_LINE
			-- Styled text content of title

	position: NATURAL_8
			-- Border position (`position_top` or `position_bottom`)

	alignment: NATURAL_8
			-- Text alignment along border ({TEXT_ALIGNMENT}.left, center, right)

feature -- Duplication

	copy (a_other: like Current)
			-- Re-create content on copy.
		do
			if a_other /= Current then
				standard_copy (a_other)
				content := a_other.content.twin
			end
		end

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Is `a_other` content-equal to `Current`?
		do
			if a_other = Current then
				Result := True
			elseif standard_is_equal (a_other) then
				Result := True
			else
				Result := position = a_other.position
					and alignment = a_other.alignment
					and content.is_equal (a_other.content)
			end
		end

invariant
	content_not_void: content /= Void
	valid_position: position = position_top or position = position_bottom
	valid_alignment: {TEXT_ALIGNMENT}.is_valid (alignment)

end
