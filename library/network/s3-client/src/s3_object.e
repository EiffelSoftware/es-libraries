note
	description: "Represents an S3 object (file) in a bucket."

class
	S3_OBJECT

create
	make

feature {NONE} -- Initialization

	make (a_key: READABLE_STRING_8; a_size: INTEGER_32; a_last_modified: detachable READABLE_STRING_8)
			-- Initialize S3 object with `a_key`, `a_size`, and `a_last_modified`.
		require
			key_not_empty: a_key /= Void and then not a_key.is_empty
			size_non_negative: a_size >= 0
		do
			create key.make_from_string (a_key)
			size := a_size
			if a_last_modified /= Void then
				create last_modified.make_from_string (a_last_modified)
			else
				create last_modified.make_empty
			end
		ensure
			key_set: key.same_string (a_key)
			size_set: size = a_size
			last_modified_set: a_last_modified /= Void implies last_modified.same_string (a_last_modified)
		end

feature -- Access

	key: STRING_8
			-- Object key (path/name).

	size: INTEGER_32
			-- Object size in bytes.

	last_modified: STRING_8
			-- Last modified timestamp.

invariant
	key_not_empty: not key.is_empty
	size_non_negative: size >= 0

note
	copyright: "2025-2026, Jocelyn Fiat, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"
end -- class S3_OBJECT


