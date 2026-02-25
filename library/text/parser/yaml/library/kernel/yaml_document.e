note
	description: "YAML document containing a root value and optional directives."
	date: "$Date$"
	revision: "$Revision$"

class
	YAML_DOCUMENT

create
	make,
	make_empty

feature {NONE} -- Initialization

	make (a_root: YAML_VALUE)
			-- Initialize with `a_root` as root value.
		require
			root_attached: a_root /= Void
		do
			root := a_root
			yaml_version := "1.2"
			create tag_directives.make (5)
		ensure
			root_set: root = a_root
		end

	make_empty
			-- Initialize with no root value.
		do
			yaml_version := "1.2"
			create tag_directives.make (5)
		ensure
			no_root: root = Void
		end

feature -- Access

	root: detachable YAML_VALUE
			-- Root value of document.

	yaml_version: STRING
			-- YAML version (default "1.2").

	tag_directives: HASH_TABLE [STRING_32, STRING_32]
			-- Tag directives (handle -> prefix).

feature -- Status report

	has_root: BOOLEAN
			-- Does document have a root value?
		do
			Result := root /= Void
		end

feature -- Element change

	set_root (a_root: YAML_VALUE)
			-- Set `root` to `a_root`.
		require
			root_attached: a_root /= Void
		do
			root := a_root
		ensure
			root_set: root = a_root
		end

	set_yaml_version (a_version: STRING)
			-- Set `yaml_version` to `a_version`.
		require
			version_attached: a_version /= Void
		do
			yaml_version := a_version
		ensure
			version_set: yaml_version = a_version
		end

	add_tag_directive (a_handle: STRING_32; a_prefix: STRING_32)
			-- Add tag directive mapping `a_handle` to `a_prefix`.
		require
			handle_attached: a_handle /= Void
			prefix_attached: a_prefix /= Void
		do
			tag_directives.put (a_prefix, a_handle)
		ensure
			added: tag_directives.has (a_handle)
		end

feature -- Output

	representation: STRING_32
			-- String representation of this document.
		do
			create Result.make (500)
				-- Add directives if any
			if not tag_directives.is_empty then
				Result.append ("%%YAML ")
				Result.append_string_general (yaml_version)
				Result.append_character ('%N')
				across tag_directives as ic loop
					Result.append ("%%TAG ")
					Result.append (@ ic.key)
					Result.append_character (' ')
					Result.append (ic)
					Result.append_character ('%N')
				end
			end
				-- Add document start marker
			Result.append ("---%N")
			if attached root as r then
				Result.append (r.representation)
			end
		ensure
			result_attached: Result /= Void
		end

feature -- Visitor

	accept (a_visitor: YAML_VISITOR)
			-- <Precursor>
		do
			a_visitor.visit_document (Current)
		end

invariant
	yaml_version_attached: yaml_version /= Void
	tag_directives_attached: tag_directives /= Void

note
	copyright: "Copyright (c) 1984-2026, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"
end
