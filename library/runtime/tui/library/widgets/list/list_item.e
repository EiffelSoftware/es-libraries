note
	description: "[
		An individual item within a TUI_LIST, consisting of multi-line styled text
		and item-specific baseline styling.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	LIST_ITEM

inherit
	ANY
		redefine
			copy,
			is_equal
		end

create
	make,
	make_raw,
	make_styled

feature {NONE} -- Initialization

	make (a_content: TEXT)
			-- Initialize item with `a_content`.
		require
			content_not_void: a_content /= Void
		do
			content := a_content
			create style.default_create
		ensure
			content_set: content = a_content
		end

	make_raw (a_text: READABLE_STRING_GENERAL)
			-- Initialize item from plain string `a_text`.
		require
			text_not_void: a_text /= Void
		local
			l_text: TEXT
		do
			create l_text.make_raw (a_text)
			make (l_text)
		end

	make_styled (a_text: READABLE_STRING_GENERAL; a_style: STYLE)
			-- Initialize item with `a_text` and baseline `a_style`.
		require
			text_not_void: a_text /= Void
			style_not_void: a_style /= Void
		local
			l_text: TEXT
		do
			create l_text.make_styled (a_text, a_style)
			make (l_text)
			style := a_style
		ensure
			style_set: style = a_style
		end

feature -- Access

	content: TEXT
			-- Text payload of this item

	style: STYLE
			-- Baseline style of this item

feature -- Element change

	set_style (a_style: STYLE)
			-- Set baseline style.
		require
			style_not_void: a_style /= Void
		do
			style := a_style
		ensure
			style_set: style = a_style
		end

feature -- Fluent Builders

	with_style (a_style: STYLE): like Current
			-- Item with updated baseline style.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_style (a_style)
		ensure
			result_is_copy: Result /= Current
			style_set: Result.style = a_style
		end

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
				Result := content.is_equal (a_other.content) and style.is_equal (a_other.style)
			end
		end

invariant
	content_not_void: content /= Void
	style_not_void: style /= Void

end
