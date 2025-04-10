note
	description: "[
		Object representing a MongoDB Change Stream.
		mongoc_change_stream_t is a handle to a change stream. A collection change stream 
		can be obtained using mongoc_collection_watch().
	]"
	date: "$Date$"
	revision: "$Revision$"
	EIS: "name=Mongo Change Stream", "src=http://mongoc.org/libmongoc/current/mongoc_change_stream_t.html", "protocol=uri"

class
	MONGODB_CHANGE_STREAM

inherit
	MONGODB_WRAPPER_BASE

create
	make_by_pointer

feature -- Access

	next (a_bson: BSON): BOOLEAN
			-- Fetches the next document from the change stream.
			-- Parameters:
			--   a_bson: A location for the resulting document
			-- Returns: True if a document was fetched, False if there was an error or no documents remain
		note
			eis: "name=mongoc_change_stream_next", "src=http://mongoc.org/libmongoc/current/mongoc_change_stream_next.html", "protocol=uri"
		require
			is_usable: exists
		do
			clean_up
			Result := {MONGODB_EXTERNALS}.c_mongoc_change_stream_next (item, a_bson.item)
		end

	resume_token: BSON
			-- Get the cached resume token that can be used to resume the change stream.
			-- Note: The resume token is updated each time a document is retrieved via next().
		note
			eis: "name=mongoc_change_stream_get_resume_token", "src=http://mongoc.org/libmongoc/current/mongoc_change_stream_get_resume_token.html", "protocol=uri"
		require
			is_usable: exists
		local
			l_token: POINTER
		do
			clean_up
			l_token := {MONGODB_EXTERNALS}.c_mongoc_change_stream_get_resume_token (item)
			create Result.make_by_pointer (l_token)
		end

	error_document (a_reply: BSON): BOOLEAN
			-- Checks if an error has occurred when creating or iterating over a change stream.
			-- 	reply: A location for a bson_t
			-- Return true if there was an error
		note
			eis: "name=mongoc_change_stream_error_document", "src=http://mongoc.org/libmongoc/current/mongoc_change_stream_error_document.html", "protocol=uri"
		require
			is_usable: exists
		local
			l_error: BSON_ERROR
			l_error_doc: POINTER
			l_has_error: BOOLEAN
			l_reply: BSON
		do
			clean_up
			create l_error.make
			l_error_doc := a_reply.item
			l_has_error := {MONGODB_EXTERNALS}.c_mongoc_change_stream_error_document (item, l_error.item, $l_error_doc)
			if l_has_error then
				set_last_error_with_bson (l_error)
			end
				-- To be double checked.
			create l_reply.make_by_pointer (l_error_doc)
			l_reply.bson_copy_to (a_reply)
		end

feature -- Removal

	dispose
			-- Cleanup resources associated with change stream.
		do
			if not shared then
				if exists then
					c_mongoc_change_stream_destroy (item)
				else
					check exists: False end
				end
			end
		end

feature -- Measurement

	structure_size: INTEGER
			-- Size to allocate (in bytes)
		do
			Result := struct_size
		end

feature {NONE} -- Implementation

	struct_size: INTEGER
		external
			"C inline use <mongoc/mongoc.h>"
		alias
			"return sizeof(mongoc_change_stream_t *);"
		end

	c_mongoc_change_stream_destroy (a_stream: POINTER)
		external
			"C inline use <mongoc/mongoc.h>"
		alias
			"mongoc_change_stream_destroy ((mongoc_change_stream_t *)$a_stream);"
		end

end

