note
	description: "Inline image."

class
	MD_IMAGE

inherit
	MD_BOX [MD_INLINE]
		redefine
			process
		end

	MD_INLINE

create
	make

feature -- Initialization

	make (a_url: READABLE_STRING_8; a_title: detachable READABLE_STRING_8)
			-- Create image with `a_url` and optional `a_title`.
		require
			a_url_not_empty: not a_url.is_empty
		do
			create url.make_from_string (a_url)
			if a_title /= Void then
				create title.make_from_string (a_title)
			end
			initialize
		ensure
			url_set: url.same_string (a_url)
			title_set: (a_title = Void) = (title = Void)
			is_empty: count = 0
		end

feature -- Access

	url: STRING_8
			-- Image URL (not escaped).

	title: detachable STRING_8
			-- Optional image title.

feature -- Visitor

	process (a_visitor: MD_VISITOR)
			-- Process `Current` using `a_visitor`.
		do
			a_visitor.visit_image (Current)
		end

invariant
	url_attached: url /= Void
	url_not_empty: not url.is_empty

end
