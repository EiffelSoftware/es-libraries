note
	description: "S3 client for interacting with S3-compatible storage (AWS S3, MinIO, etc.)."
	description: "[
		Provides functionality to:
		- List objects in a bucket
		- Read objects from a bucket
		- Write objects to a bucket
		- Delete objects from a bucket
	]"

class
	S3_CLIENT

create
	make_with_endpoint,
	make

feature {NONE} -- Initialization

	make (a_bucket: READABLE_STRING_8; a_region: STRING_8; a_prefix: detachable READABLE_STRING_8; a_access_key: READABLE_STRING_32; a_secret_key: READABLE_STRING_32)
			-- Initialize S3 client with `a_endpoint`, `a_access_key`, `a_secret_key`, `a_bucket`, and `a_region`.
		require
			access_key_not_empty: a_access_key /= Void and then not a_access_key.is_empty
			secret_key_not_empty: a_secret_key /= Void and then not a_secret_key.is_empty
			bucket_not_empty: a_bucket /= Void and then not a_bucket.is_empty
		do
			access_key := a_access_key
			secret_key := a_secret_key
			bucket_name := a_bucket
			if a_prefix /= Void then
				prefix := a_prefix
			end
			region := a_region
			endpoint := "https://s3." + region + ".amazonaws.com"
			initialize
		ensure
			bucket_set: bucket_name.same_string (a_bucket)
			access_key_set: attached access_key as ak and then ak.same_string (a_access_key)
			secret_key_set: attached secret_key as sk and then sk.same_string (a_secret_key)
		end

	make_with_s3_url (a_s3_url: READABLE_STRING_8; a_region: STRING_8; a_access_key: READABLE_STRING_32; a_secret_key: READABLE_STRING_32)
		require
			a_s3_url.starts_with ("s3://")
		do
			access_key := a_access_key
			secret_key := a_secret_key
			region := a_region
			if attached parse_s3_url (a_s3_url) as d then
				bucket_name := d.bucket
				if attached d.key as k then
					prefix := k
				end
			else
				bucket_name := ""
			end
			endpoint := "https://s3." + a_region + ".amazonaws.com"
			initialize
		ensure
			access_key_set: attached access_key as ak and then ak.same_string (a_access_key)
			secret_key_set: attached secret_key as sk and then sk.same_string (a_secret_key)
			region_set: region.same_string (a_region)
		end

	make_with_endpoint (a_endpoint: READABLE_STRING_8; a_region: STRING_8; a_access_key: READABLE_STRING_32; a_secret_key: READABLE_STRING_32)
			-- Initialize S3 client with `a_endpoint`, `a_access_key`, `a_secret_key`, and `a_region`.
		require
			endpoint_not_empty: a_endpoint /= Void and then not a_endpoint.is_empty
			access_key_not_empty: a_access_key /= Void and then not a_access_key.is_empty
			secret_key_not_empty: a_secret_key /= Void and then not a_secret_key.is_empty
		local
			reg: READABLE_STRING_8
		do
			if a_endpoint.starts_with ("s3://") then
				if a_region /= Void then
					make_with_s3_url (a_endpoint, a_region, a_access_key, a_secret_key)
				else
					make_with_s3_url (a_endpoint, "us-east-1", a_access_key, a_secret_key)
				end
			elseif attached parse_url (a_endpoint) as d then
				access_key := a_access_key
				secret_key := a_secret_key
				bucket_name := d.bucket
				if attached d.key as k then
					prefix := k
				end
				endpoint := d.endpoint
				reg := d.region
				if reg = Void then
					reg := a_region
				end
				if reg = Void then
					reg := "us-east-1"
				end
				region := reg
				initialize
			else
				(create {EXCEPTIONS}).raise ("Invalid endpoint")
				check
					False
				then
				end
			end
		ensure
			endpoint_set: not a_endpoint.starts_with ("s3://") implies a_endpoint.starts_with (a_endpoint)
			access_key_set: attached access_key as ak and then ak.same_string (a_access_key)
			secret_key_set: attached secret_key as sk and then sk.same_string (a_secret_key)
		end

	initialize
		local
			sess: like http_session
		do
			sess := (create {DEFAULT_HTTP_CLIENT}).new_session (endpoint)
			debug ("s3")
				sess.set_is_debug (True)
			end
			http_session := sess
			create signature_generator.make (access_key, secret_key, region, "s3")
		end

feature -- Access

	endpoint: IMMUTABLE_STRING_8
			-- S3 endpoint URL.

	bucket_name: IMMUTABLE_STRING_8
			-- Name of the S3 bucket.

	prefix: detachable IMMUTABLE_STRING_8
			-- Optional prefix.

	access_key: IMMUTABLE_STRING_32
			-- Access key for authentication.

	secret_key: IMMUTABLE_STRING_32
			-- Secret key for authentication.

	region: IMMUTABLE_STRING_8
			-- AWS region (e.g., "us-east-1").

feature -- Status report

	last_operation_succeed: BOOLEAN

feature -- Conversion

	prefix_path (k: detachable READABLE_STRING_8): STRING_8
			-- Full path for key `k` including eventual prefix `prefix`.
		do
			if attached prefix as p and then not p.is_empty then
				create Result.make_from_string (p)
			end
			if k /= Void and then not k.is_empty then
				if Result /= Void then
					if not Result.ends_with ("/") and not k.starts_with ("/") then
						Result.append_character ('/')
					end;
					Result.append (k)
				else
					create Result.make_from_string (k)
				end
			end
			if Result = Void then
				create Result.make_empty
			end
		end

feature -- Element change

	set_prefix (p: detachable READABLE_STRING_8)
		do
			if p = Void then
				prefix := Void
			else
				prefix := create {attached IMMUTABLE_STRING_8}.make_from_string (p)
			end
		end

feature -- Operations

	list_bucket (a_prefix: detachable READABLE_STRING_8; is_recursive: BOOLEAN): detachable LIST [S3_OBJECT]
			-- List objects in bucket, optionally filtered by `a_prefix`.
			-- Returns list of S3 objects or Void if error occurred.
		require
			bucket_not_empty: not bucket_name.is_empty
		local
			path: STRING_8
			query_string: detachable STRING_8
			response: HTTP_CLIENT_RESPONSE
			parser: S3_LIST_RESPONSE_PARSER
			ctx: HTTP_CLIENT_REQUEST_CONTEXT
			l_prefix: STRING_8
		do
			last_operation_succeed := False
			create path.make_from_string ("/");
			path.append (bucket_name);
			path.append_character ('/')
			l_prefix := prefix_path (a_prefix)
			if l_prefix /= Void and then not l_prefix.is_empty then
				query_string := "prefix=" + l_prefix
			end
			if not is_recursive then
				if query_string /= Void and then not query_string.is_empty then
					query_string.append ("&delimiter=/")
				else
					query_string := "delimiter=/"
				end
			end
			if attached http_session as sess then
				ctx := build_request_context ("GET", path, query_string, Void, Void)
				if l_prefix /= Void then
					ctx.add_query_parameter ("prefix", l_prefix)
				end
				if not is_recursive then
					ctx.add_query_parameter ("delimiter", "/")
				end
				response := sess.get (path, ctx)
				if not response.error_occurred and then response.status = 200 then
					if attached response.body as body then
						create parser.make
						Result := parser.parse_list_response (body)
						last_operation_succeed := True
					end
				elseif attached response.body as b then
					Io.Error.put_string (b)
				end
			end
		end

	list_common_prefixes (a_prefix: detachable READABLE_STRING_8): detachable LIST [READABLE_STRING_32]
			-- List common prefix in bucket, optionally filtered by `a_prefix`.
			-- Returns list of common prefixes or Void if error occurred.
		require
			bucket_not_empty: not bucket_name.is_empty
		local
			path: STRING_8
			query_string: detachable STRING_8
			response: HTTP_CLIENT_RESPONSE
			parser: S3_LIST_RESPONSE_PARSER
			ctx: HTTP_CLIENT_REQUEST_CONTEXT
			l_prefix: STRING_8
		do
			last_operation_succeed := False
			create path.make_from_string ("/");
			path.append (bucket_name);
			path.append_character ('/')
			l_prefix := prefix_path (a_prefix)
			if l_prefix /= Void and then not l_prefix.is_empty then
				query_string := "prefix=" + l_prefix
			end
			if query_string /= Void and then not query_string.is_empty then
				query_string.append ("&delimiter=/")
			else
				query_string := "delimiter=/"
			end
			if attached http_session as sess then
				ctx := build_request_context ("GET", path, query_string, Void, Void)
				if l_prefix /= Void then
					ctx.add_query_parameter ("prefix", l_prefix)
				end
				ctx.add_query_parameter ("delimiter", "/")
				response := sess.get (path, ctx)
				if not response.error_occurred and then response.status = 200 then
					if attached response.body as body then
						create parser.make
						Result := parser.parse_list_common_prefixes_response (body)
						last_operation_succeed := True
					end
				elseif attached response.body as b then
					Io.Error.put_string (b)
				end
			end
		end

	read_file (a_key: READABLE_STRING_8): detachable READABLE_STRING_8
			-- Read file content for `a_key` from bucket.
			-- Returns file content or Void if error occurred.
		require
			key_not_empty: a_key /= Void and then not a_key.is_empty
		local
			path: STRING_8
			response: HTTP_CLIENT_RESPONSE
			ctx: HTTP_CLIENT_REQUEST_CONTEXT
		do
			last_operation_succeed := False
			path := s3_path (a_key)
			if attached http_session as sess then
				ctx := build_request_context ("GET", path, Void, Void, Void)
				response := sess.get (path, ctx)
				if not response.error_occurred and then response.status = 200 then
					if attached response.body as body then
						Result := body
						last_operation_succeed := True
					end
				end
			end
		ensure
			success_implies_result_attached: (Result /= Void) implies (attached http_session as sess and then sess.is_available)
		end

	write_file (a_key: READABLE_STRING_8; a_content: READABLE_STRING_8)
			-- Write `a_content` to file `a_key` in bucket.
			-- Returns True if successful, False otherwise.
		require
			key_not_empty: a_key /= Void and then not a_key.is_empty
			content_not_void: a_content /= Void
		local
			path: STRING_8
			response: HTTP_CLIENT_RESPONSE
			ctx: HTTP_CLIENT_REQUEST_CONTEXT
			payload_hash: STRING_8
		do
			last_operation_succeed := False
			path := s3_path (a_key)
			if attached http_session as sess then
				payload_hash := sha256_hash (a_content)
				ctx := build_request_context ("PUT", path, Void, a_content, payload_hash)
				response := sess.put (path, ctx, a_content)
				last_operation_succeed := not response.error_occurred and then response.status = 200
			end
		ensure
			success_implies_session_available: last_operation_succeed implies (attached http_session as sess and then sess.is_available)
		end

	delete_file (a_key: READABLE_STRING_8)
			-- Delete file `a_key` from bucket.
			-- Returns True if successful, False otherwise.
		require
			key_not_empty: a_key /= Void and then not a_key.is_empty
		local
			path: STRING_8
			response: HTTP_CLIENT_RESPONSE
			ctx: HTTP_CLIENT_REQUEST_CONTEXT
		do
			last_operation_succeed := False
			path := s3_path (a_key)
			if attached http_session as sess then
				ctx := build_request_context ("DELETE", path, Void, Void, Void)
				response := sess.delete (path, ctx)
				last_operation_succeed := not response.error_occurred and then (response.status = 204 or response.status = 200)
			end
		ensure
			success_implies_session_available: last_operation_succeed implies (attached http_session as sess and then sess.is_available)
		end

	metadata (a_key: READABLE_STRING_8): detachable S3_OBJECT_METADATA
			-- Get metadata for object `a_key` (file or folder).
			-- Returns metadata object or Void if object doesn't exist or error occurred.
			-- Use HEAD request to retrieve metadata without downloading the object.
		require
			key_not_empty: a_key /= Void and then not a_key.is_empty
		local
			path: STRING_8
			response: HTTP_CLIENT_RESPONSE
			ctx: HTTP_CLIENT_REQUEST_CONTEXT
			meta: S3_OBJECT_METADATA
			header_name: READABLE_STRING_8
			header_value: READABLE_STRING_8
		do
			path := s3_path (a_key)
			if attached http_session as sess then
				ctx := build_request_context ("HEAD", path, Void, Void, Void)
				response := sess.head (path, ctx)
				if not response.error_occurred and then (response.status = 200 or response.status = 404) then
					if response.status = 200 then
						create meta.make
						across
							response.headers as header_entry
						loop
							header_name := header_entry.name
							header_value := header_entry.value;
							meta.set_metadata (header_name, header_value)
						end
						Result := meta
					end
				end
			end
		ensure
			result_implies_exists: Result /= Void implies Result.exists
		end

feature {NONE} -- Implementation

	s3_path (k: READABLE_STRING_8): STRING_8
			-- Full s3 path for key `k` within bucket `bucket_name` and using eventual prefix `prefix`.
		do
			create Result.make_from_string ("/");
			Result.append (bucket_name);
			Result.append ("/")
			if attached prefix_path (k) as p then
				Result.append (p)
			end
		end

	http_session: detachable HTTP_CLIENT_SESSION
			-- HTTP session for making requests.

	signature_generator: S3_AWS_SIGNATURE_V4
			-- AWS Signature Version 4 generator.

	build_request_context (a_method: READABLE_STRING_8; a_path: STRING_8; a_query_string: detachable READABLE_STRING_8; a_content: detachable READABLE_STRING_8; a_payload_hash: detachable READABLE_STRING_8): HTTP_CLIENT_REQUEST_CONTEXT
			-- Build request context with AWS Signature Version 4 headers.
			-- Note: `a_path` may be modified to include query string.
		require
			method_not_empty: a_method /= Void and then not a_method.is_empty
			path_not_empty: a_path /= Void and then not a_path.is_empty
		local
			ctx: HTTP_CLIENT_REQUEST_CONTEXT
			now: DATE_TIME
			date_time_stamp: READABLE_STRING_8
			host_header: READABLE_STRING_8
			auth_header: READABLE_STRING_8
			payload: READABLE_STRING_8
			canonical_path: READABLE_STRING_8
		do
			create ctx.make;
			ctx.set_credentials_required (True)
			create now.make_now_utc
			date_time_stamp := format_date_time_stamp (now)
			host_header := extract_host_from_endpoint;
			ctx.headers.force (host_header, "Host")
			if a_payload_hash = Void then
				if a_content /= Void then
					payload := sha256_hash (a_content)
				else
					payload := "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
				end
			else
				payload := a_payload_hash
			end;
			ctx.headers.force (payload, "x-amz-content-sha256");
			ctx.headers.force (date_time_stamp, "x-amz-date")
			canonical_path := a_path
			auth_header := signature_generator.generate_authorization_header (a_method, canonical_path, a_query_string, ctx.headers, payload);
			ctx.headers.force (auth_header, "Authorization")
			Result := ctx
		ensure
			result_not_void: Result /= Void
		end

	extract_host_from_endpoint: STRING_8
			-- Extract host from endpoint URL.
		local
			url: STRING_8
			pos: INTEGER_32
		do
			create url.make_from_string (endpoint)
			pos := url.substring_index ("://", 1)
			if pos > 0 then
				url := url.substring (pos + 3, url.count)
			end
			pos := url.index_of ('/', 1)
			if pos > 0 then
				url := url.substring (1, pos - 1)
			end
			Result := url
		ensure
			result_not_empty: not Result.is_empty
		end

	format_date_time_stamp (a_date: DATE_TIME): STRING_8
			-- Format date-time as YYYYMMDDTHHMMSSZ.
		require
			date_not_void: a_date /= Void
		do
			create Result.make (16);
			Result.append_integer (a_date.year)
			if a_date.month < 10 then
				Result.append_character ('0')
			end;
			Result.append_integer (a_date.month)
			if a_date.day < 10 then
				Result.append_character ('0')
			end;
			Result.append_integer (a_date.day);
			Result.append_character ('T')
			if a_date.hour < 10 then
				Result.append_character ('0')
			end;
			Result.append_integer (a_date.hour)
			if a_date.minute < 10 then
				Result.append_character ('0')
			end;
			Result.append_integer (a_date.minute)
			if a_date.second < 10 then
				Result.append_character ('0')
			end;
			Result.append_integer (a_date.second);
			Result.append_character ('Z')
		ensure
			result_count: Result.count = 16
		end

	sha256_hash (a_string: READABLE_STRING_8): STRING_8
			-- Calculate SHA256 hash of `a_string` and return as hexadecimal string.
		require
			string_not_void: a_string /= Void
		local
			sha: SHA256
		do
			create sha.make;
			sha.update_from_string (a_string)
			Result := sha.digest_as_hexadecimal_string.as_lower
		ensure
			result_not_empty: not Result.is_empty
		end

feature {NONE} -- Implementation: S3 URL parsing

	parse_s3_http_url (a_url: READABLE_STRING_8): detachable TUPLE [endpoint: READABLE_STRING_8; bucket: READABLE_STRING_8; key: detachable READABLE_STRING_8; region: detachable READABLE_STRING_8]
			-- Parse `http(s)://` URL and extract bucket name and optional object key.
			-- Returns tuple with bucket name and optional key, or Void if URL is invalid.
			-- Example: "http://localhost:9800/my-bucket/path/to/file.txt" -> ["my-bucket", "path/to/file.txt", Void]
			-- Example: "https://s3.us-east-1.amazonaws.com/my-bucket/path/to/file.txt" -> ["my-bucket", "path/to/file.txt", "us-east-1"]
			-- Example: "https://s3.us-east-1.amazonaws.com/my-bucket/" -> ["my-bucket", "", "us-east-1"]
			-- Example: "https://s3.us-east-1.amazonaws.com/my-bucket" -> ["my-bucket", Void, "us-east-1"]
		require
			url_not_empty: a_url /= Void and then not a_url.is_empty
		local
			url: STRING_8
			pos: INTEGER_32
			region_end: INTEGER_32
			bucket_end: INTEGER_32
			key_start: INTEGER_32
			l_endpoint, reg, bucket: READABLE_STRING_8
			key: detachable READABLE_STRING_8
		do
			create url.make_from_string (a_url)
			url.to_lower
			l_endpoint := url
			if url.starts_with ("https://s3.") and url.has_substring (".amazonaws.com") then
				pos := 12
				region_end := url.index_of ('.', pos)
				if region_end = 0 then
					region_end := url.count + 1
					reg := "us-east-1"
				else
					reg := url.substring (pos, region_end - 1)
				end
				pos := url.index_of ('/', pos)
				if pos = 0 then
					create {IMMUTABLE_STRING_8} l_endpoint.make_from_string (a_url)
					bucket := Void
				else
					l_endpoint := url.substring (1, pos - 1)
					pos := pos + 1
					bucket_end := url.index_of ('/', pos)
					if bucket_end = 0 then
						bucket_end := url.count + 1
					end
					if bucket_end > pos then
						bucket := url.substring (pos, bucket_end - 1)
						if bucket_end <= url.count then
							key_start := bucket_end + 1
							if key_start <= url.count then
								key := url.substring (key_start, url.count)
							else
								key := ""
							end
						end
					end
				end
				if bucket /= Void then
					Result := [l_endpoint, bucket, key, reg]
				end
			end
		ensure
			result_implies_bucket_not_empty: Result /= Void implies not Result.bucket.is_empty
		end

	parse_s3_url (a_url: READABLE_STRING_8): detachable TUPLE [bucket: STRING_8; key: detachable STRING_8]
			-- Parse `s3://` URL and extract bucket name and optional object key.
			-- Returns tuple with bucket name and optional key, or Void if URL is invalid.
			-- Example: "s3://my-bucket/path/to/file.txt" -> ["my-bucket", "path/to/file.txt"]
			-- Example: "s3://my-bucket/" -> ["my-bucket", ""]
			-- Example: "s3://my-bucket" -> ["my-bucket", Void]
		require
			url_not_empty: a_url /= Void and then not a_url.is_empty
		local
			url: STRING_8
			pos: INTEGER_32
			bucket_end: INTEGER_32
			key_start: INTEGER_32
			bucket: STRING_8
			key: detachable STRING_8
		do
			url := a_url.to_string_8;
			url.to_lower
			if url.starts_with ("s3://") then
				pos := 6
				bucket_end := url.index_of ('/', pos)
				if bucket_end = 0 then
					bucket_end := url.count + 1
				end
				if bucket_end > pos then
					bucket := url.substring (pos, bucket_end - 1)
					if bucket_end <= url.count then
						key_start := bucket_end + 1
						if key_start <= url.count then
							key := url.substring (key_start, url.count)
						else
							key := ""
						end
					end
					Result := [bucket, key]
				end
			end
		ensure
			result_implies_bucket_not_empty: Result /= Void implies not Result.bucket.is_empty
		end

	parse_url (a_url: READABLE_STRING_8): detachable TUPLE [endpoint: READABLE_STRING_8; bucket: READABLE_STRING_8; key: detachable READABLE_STRING_8; region: detachable READABLE_STRING_8]
			-- Parse `https://host/my-bucket/path/to/node` URL and extract endpoint, bucket name and optional object key.
			-- Returns tuple with endpoint, bucket name and optional key, or Void if URL is invalid.
		require
			url_not_empty: a_url /= Void and then not a_url.is_empty
		local
			url: STRING_8
			pos: INTEGER_32
			bucket_start, bucket_end: INTEGER_32
			key_start: INTEGER_32
			l_endpoint, bucket: READABLE_STRING_8
			key: detachable READABLE_STRING_8
		do
			create url.make_from_string (a_url)
			url.to_lower
			if url.starts_with ("http://") or url.starts_with ("https://") then
				if attached parse_s3_http_url (a_url) as d then
					Result := [d.endpoint, d.bucket, d.key, d.region]
				else
					pos := url.substring_index ("://", 1)
					if pos > 0 then
						pos := pos + 3
						bucket_start := url.index_of ('/', pos + 1)
						if bucket_start = 0 then
							bucket_start := url.count + 1
						else
							bucket_start := bucket_start + 1
						end
						l_endpoint := url.head (bucket_start - 1)
						if l_endpoint.ends_with ("/") then
							l_endpoint := l_endpoint.head (l_endpoint.count - 1)
						end
						bucket_end := url.index_of ('/', bucket_start + 1)
						if bucket_end = 0 then
							bucket_end := url.count + 1
						end
						if bucket_end > bucket_start then
							bucket := url.substring (bucket_start, bucket_end - 1)
							if bucket_end <= url.count then
								key_start := bucket_end + 1
								if key_start <= url.count then
									key := url.substring (key_start, url.count)
								else
									key := ""
								end
							end
							Result := [l_endpoint, bucket, key, Void]
						end
					end
				end
			end
		ensure
			result_implies_bucket_not_empty: Result /= Void implies not Result.bucket.is_empty
		end

invariant
	endpoint_not_empty: not endpoint.is_empty
	bucket_name_not_empty: not bucket_name.is_empty
	access_key_attached: access_key /= Void
	secret_key_attached: secret_key /= Void
	region_not_empty: not region.is_empty

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
