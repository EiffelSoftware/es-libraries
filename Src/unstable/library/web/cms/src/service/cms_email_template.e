note
	description: "Email template definition for CMS mail WebAPI."
	date: "$Date$"
	revision: "$Revision$"

class
	CMS_EMAIL_TEMPLATE

create
	make

feature -- Access

	id: detachable IMMUTABLE_STRING_8
			-- Template identifier.

	title: detachable IMMUTABLE_STRING_8
			-- Optional template title (UTF-8 encoded), used as default email subject.

	content: detachable IMMUTABLE_STRING_8
			-- Template main body (UTF-8 encoded).

	footer: detachable IMMUTABLE_STRING_8
			-- Optional template footer (UTF-8 encoded).

	engine: detachable IMMUTABLE_STRING_8
			-- Optional template engine name (smarty, expand, ...).

feature -- Status report

	has_id: BOOLEAN
		do
			Result := attached id as l_id and then not l_id.is_whitespace
		end

	has_title: BOOLEAN
		do
			Result := attached title as l_title and then not l_title.is_empty
		end

	has_content: BOOLEAN
		do
			Result := attached content as l_content and then not l_content.is_empty
		end

	has_footer: BOOLEAN
		do
			Result := attached footer as l_footer and then not l_footer.is_empty
		end

	has_engine: BOOLEAN
		do
			Result := attached engine as l_engine and then not l_engine.is_whitespace
		end

feature -- Initialization

	make (a_id: READABLE_STRING_8; a_content: READABLE_STRING_GENERAL)
			-- Create template with `a_id' and `a_content'.
		require
			valid_id: not a_id.is_whitespace
			valid_content: not a_content.is_empty
		do
			create id.make_from_string (a_id)
			set_content (a_content)
		ensure
			has_id: has_id
			has_content: has_content
		end

feature -- Element change

	set_id (a_id: READABLE_STRING_8)
		do
			if a_id = Void then
				id := Void
			else
				create id.make_from_string (a_id)
			end
		end

	set_title (a_title: detachable READABLE_STRING_GENERAL)
		do
			if a_title = Void or else a_title.is_empty then
				title := Void
			else
				create title.make_from_string ({UTF_CONVERTER}.utf_32_string_to_utf_8_string_8 (a_title))
			end
		end

	set_content (a_content: READABLE_STRING_GENERAL)
		do
			if a_content = Void then
				content := Void
			else
				create content.make_from_string ({UTF_CONVERTER}.utf_32_string_to_utf_8_string_8 (a_content))
			end
		end

	set_footer (a_footer: detachable READABLE_STRING_GENERAL)
		do
			if a_footer = Void or else a_footer.is_empty then
				footer := Void
			else
				create footer.make_from_string ({UTF_CONVERTER}.utf_32_string_to_utf_8_string_8 (a_footer))
			end
		end

	set_engine (a_engine: detachable READABLE_STRING_8)
		do
			if a_engine = Void then
				engine := Void
			else
				create engine.make_from_string (a_engine)
			end
		end

invariant
	has_id_when_created: id /= Void implies has_id

note
	copyright: "2011-2026, Jocelyn Fiat, Javier Velilla, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
end
