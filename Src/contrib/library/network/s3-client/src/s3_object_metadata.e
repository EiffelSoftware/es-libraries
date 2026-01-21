note
	description: "Represents metadata for an S3 object (file or folder)."

class
	S3_OBJECT_METADATA

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize empty metadata.
		do
			create metadata.make (10)
		ensure
			metadata_not_void: metadata /= Void
		end

feature -- Access

	metadata: HASH_TABLE [READABLE_STRING_8, READABLE_STRING_8]
			-- All metadata headers (header name -> value).

	content_type: detachable READABLE_STRING_8
			-- Content-Type of the object.
		do
			Result := metadata.item ("Content-Type")
		end

	content_length: detachable INTEGER_64
			-- Content-Length (size in bytes) of the object.
		local
			len_str: detachable READABLE_STRING_8
		do
			len_str := metadata.item ("Content-Length")
			if len_str /= Void then
				if len_str.is_integer_64 then
					Result := len_str.to_integer_64
				end
			end
		end

	last_modified: detachable READABLE_STRING_8
			-- Last-Modified timestamp of the object.
		do
			Result := metadata.item ("Last-Modified")
		end

	etag: detachable READABLE_STRING_8
			-- ETag (entity tag) of the object.
		do
			Result := metadata.item ("ETag")
		end

	storage_class: detachable READABLE_STRING_8
			-- Storage class (e.g., "STANDARD", "STANDARD_IA", "GLACIER").
		do
			Result := metadata.item ("x-amz-storage-class")
		end

	server_side_encryption: detachable READABLE_STRING_8
			-- Server-side encryption method (e.g., "AES256", "aws:kms").
		do
			Result := metadata.item ("x-amz-server-side-encryption")
		end

	custom_metadata: HASH_TABLE [READABLE_STRING_8, READABLE_STRING_8]
			-- Custom metadata (x-amz-meta-* headers).
		local
			key: READABLE_STRING_8
		do
			create Result.make (5)
			across
				metadata as entry
			loop
				key := @ entry.key
				if key.starts_with ("x-amz-meta-") then
					Result.force (entry, key.substring (12, key.count))
				end
			end
		ensure
			result_not_void: Result /= Void
		end

	exists: BOOLEAN
			-- Does the object exist? (True if metadata was successfully retrieved).
		do
			Result := not metadata.is_empty
		end

	is_folder: BOOLEAN
			-- Is this a folder/prefix? (Heuristic: True if Content-Length is 0 or missing).
			-- Note: S3 doesn't have real folders - they're just prefixes. This is a best-guess.
		do
			if attached content_length as len then
				Result := len = 0
			else
				-- No content-length might indicate a prefix/folder
				Result := etag = Void
			end
		end

feature -- Element change

	set_metadata (a_header_name: READABLE_STRING_8; a_value: READABLE_STRING_8)
			-- Set metadata header `a_header_name' to `a_value'.
		require
			header_name_not_empty: a_header_name /= Void and then not a_header_name.is_empty
			value_not_void: a_value /= Void
		do
			metadata.force (a_value, a_header_name)
		ensure
			metadata_set: metadata.has (a_header_name) and then attached metadata.item (a_header_name) as v and then v.same_string (a_value)
		end

invariant
	metadata_not_void: metadata /= Void

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
end

