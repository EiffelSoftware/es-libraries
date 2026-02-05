note
	description: "Inline link."

class
	MD_LINK

inherit
	MD_BOX [MD_INLINE]
		redefine
			process
		end

	MD_INLINE

create
	make,
	make_with_title

feature -- Initialization

	make (a_url: READABLE_STRING_8)
			-- Create link to `a_url` (no title).
		require
			a_url_not_empty: not a_url.is_empty
		do
			create url.make_from_string (a_url)
			initialize
		ensure
			url_set: url.same_string (a_url)
			title_void: title = Void
		end

	make_with_title (a_url: READABLE_STRING_8; a_title: READABLE_STRING_8)
			-- Create link to `a_url` with optional `a_title`.
		require
			a_url_not_empty: not a_url.is_empty
			a_title_attached: a_title /= Void
		do
			create url.make_from_string (a_url)
			create title.make_from_string (a_title)
			initialize
		ensure
			url_set: url.same_string (a_url)
			title_attached: title /= Void
		end

feature -- Access

	url: STRING_8
			-- Link destination (not escaped).

	title: detachable STRING_8
			-- Optional link title (e.g. from `[text](url "title")`).

feature -- Visitor

	process (a_visitor: MD_VISITOR)
			-- Process `Current` using `a_visitor`.
		do
			a_visitor.visit_link (Current)
		end

invariant
	url_attached: url /= Void
	url_not_empty: not url.is_empty

end

