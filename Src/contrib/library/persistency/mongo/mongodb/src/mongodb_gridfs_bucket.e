note
	description: "Object representing a GridFS bucket for storing and retrieving files"
	author: ""
	date: "$Date$"
	revision: "$Revision$"
	EIS: "name=mongoc_gridfs_bucket", "src=https://mongoc.org/libmongoc/current/mongoc_gridfs_bucket_t.html", "protocol=uri"

class
	MONGODB_GRIDFS_BUCKET

inherit
	MONGODB_WRAPPER_BASE

create
	make_by_pointer, make_from_database

feature {NONE} -- Initialization

	make_from_database (a_database: MONGODB_DATABASE; a_opts: detachable BSON; a_read_prefs: detachable MONGODB_READ_PREFERENCES)
			-- Create a new GridFS bucket instance using database `a_database` with optional settings `a_opts`
			-- and optional read preferences `a_read_prefs`.
			-- Note: If `a_read_prefs` is Void, inherits read preferences from database.
		local
			l_error: BSON_ERROR
			l_ptr: POINTER
			l_opts: POINTER
			l_read_prefs: POINTER
		do
			create l_error.make
			if attached a_opts as opts then
				l_opts := opts.item
			end
			if attached a_read_prefs as prefs then
				l_read_prefs := prefs.item
			end
				-- https://mongoc.org/libmongoc/current/mongoc_gridfs_bucket_new.html
			l_ptr := {MONGODB_EXTERNALS}.c_mongoc_gridfs_bucket_new (
										a_database.item, 	-- db
										l_opts, 			-- opts
										l_read_prefs, 		-- read_prefs
										l_error.item) 		-- error
			if l_ptr.is_default_pointer then
				set_last_error_with_bson (l_error)
			else
				make_by_pointer (l_ptr)
			end
		end

feature -- Access

	upload_from_stream (a_filename: STRING; a_source: MONGODB_STREAM; a_opts: detachable BSON): BSON_VALUE
			-- Upload contents from stream `a_source` to GridFS with filename `a_filename`.
			-- Returns the file ID of the created file on success.
		require
			is_useful: exists
			valid_filename: not a_filename.is_empty
			valid_source: a_source.exists
		local
			l_error: BSON_ERROR
			l_opts: POINTER
			c_filename: C_STRING
			l_file_id: BSON_VALUE
		do
			clean_up
			create l_error.make
			create c_filename.make (a_filename)
			if attached a_opts as opts then
				l_opts := opts.item
			end
			create l_file_id.make
			if {MONGODB_EXTERNALS}.c_mongoc_gridfs_bucket_upload_from_stream (
				item, c_filename.item, a_source.item, l_opts, l_file_id.item, l_error.item) then
				Result := l_file_id
			else
				set_last_error_with_bson (l_error)
				create Result.make -- Return empty value on error
			end
		end

	download_to_stream (a_file_id: BSON_VALUE; a_destination: MONGODB_STREAM): BOOLEAN
			-- Download the file with ID `a_file_id` to stream `a_destination`.
		require
			is_useful: exists
		local
			l_error: BSON_ERROR
		do
			clean_up
			create l_error.make
			Result := {MONGODB_EXTERNALS}.c_mongoc_gridfs_bucket_download_to_stream (
				item, a_file_id.item, a_destination.item, l_error.item)
			if not Result then
				set_last_error_with_bson (l_error)
			end
		end


feature -- Removal

	dispose
			-- <Precursor>
		do
			if not shared then
				if exists then
					c_mongoc_gridfs_bucket_destroy (item)
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
			"return sizeof(mongoc_gridfs_bucket_t *);"
		end

	c_mongoc_gridfs_bucket_destroy (a_bucket: POINTER)
		external
			"C inline use <mongoc/mongoc.h>"
		alias
			"mongoc_gridfs_bucket_destroy ((mongoc_gridfs_bucket_t *)$a_bucket);"
		end

end

